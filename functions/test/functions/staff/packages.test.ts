import { strict as assert } from "node:assert";
import { adminDb, callFunction, clearEmulators, seedSettings } from "../../helpers/env";
import { CLINIC, CLINIC_2, guardianWithChildren, openNonVaccineDay, seedBookingSettings, seedClinic, visit } from "../../helpers/booking";
import { cairoDate } from "../../../src/lib/booking/time";
import { secretary1, secretary2 } from "../../helpers/staff";

/** `YYYY-MM-DD` plus [n] days. */
function plusDays(date: string, n: number): string {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

type Sold = { packageId: string; startsOn: string; endsOn: string; price: number };

describe("package renewal (008 US3, D-14, D-46)", () => {
  const today = () => cairoDate();

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedBookingSettings();
    await seedClinic(CLINIC_2, { packagePrice: 1700, packageMonths: 12 });
  });

  async function familyWithPackageEndingIn(days: number) {
    const g = await guardianWithChildren("+201000000099");
    await adminDb().doc("packages/current").set({
      guardianUid: g.uid, soldAtClinicId: CLINIC, price: 1500, startsOn: plusDays(today(), days - 365), endsOn: plusDays(today(), days),
      active: true, soldBy: "sec1", soldOn: plusDays(today(), days - 365),
    });
    return g;
  }

  it("within the last 14 days: starts the day after the end, at the selling clinic's price and months, audited", async () => {
    const g = await familyWithPackageEndingIn(10);
    const res = await callFunction<Sold>("sellPackage", { clinicId: CLINIC_2, guardianUid: g.uid, renew: true }, await secretary2());
    assert.ok(res.result, JSON.stringify(res.error));
    assert.equal(res.result.startsOn, plusDays(today(), 11));
    assert.equal(res.result.price, 1700);
    const pkg = await adminDb().doc(`packages/${res.result.packageId}`).get();
    assert.equal(pkg.get("renews"), "current");
    assert.equal(pkg.get("soldAtClinicId"), CLINIC_2, "revenue to the selling clinic (D-46)");
    assert.equal(pkg.get("endsOn") > pkg.get("startsOn"), true);
    const audit = await adminDb().collection("auditLog").where("action", "==", "package.sold").get();
    assert.equal(audit.docs[0].get("details.renew"), true);
  });

  it("exactly 14 days left is allowed; 15 is too early", async () => {
    const g = await familyWithPackageEndingIn(15);
    const early = await callFunction("sellPackage", { clinicId: CLINIC, guardianUid: g.uid, renew: true }, await secretary1());
    assert.equal(early.error?.details?.reason, "too_early");
    await adminDb().doc("packages/current").update({ endsOn: plusDays(today(), 14) });
    assert.ok((await callFunction("sellPackage", { clinicId: CLINIC, guardianUid: g.uid, renew: true }, await secretary1())).result);
  });

  it("a second renewal, or a plain sale while one is active, is refused; no package means nothing to renew", async () => {
    const g = await familyWithPackageEndingIn(5);
    const s = await secretary1();
    assert.ok((await callFunction("sellPackage", { clinicId: CLINIC, guardianUid: g.uid, renew: true }, s)).result);
    assert.equal((await callFunction("sellPackage", { clinicId: CLINIC, guardianUid: g.uid, renew: true }, s)).error?.details?.reason, "has_package");
    assert.equal((await callFunction("sellPackage", { clinicId: CLINIC, guardianUid: g.uid }, s)).error?.details?.reason, "has_package");
    const none = await guardianWithChildren("+201000000088");
    assert.equal((await callFunction("sellPackage", { clinicId: CLINIC, guardianUid: none.uid, renew: true }, s)).error?.details?.reason, "no_package");
  });

  it("a booking after the current end is covered by the renewal (coverage by date)", async () => {
    const g = await familyWithPackageEndingIn(1);
    assert.ok((await callFunction("sellPackage", { clinicId: CLINIC, guardianUid: g.uid, renew: true }, await secretary1())).result);
    const day = openNonVaccineDay(3);
    const res = await callFunction<{ bookingId: string }>("createBooking", visit(day, 18, g.childIds, 0), g);
    assert.ok(res.result, JSON.stringify(res.error));
    const b = await adminDb().doc(`bookings/${res.result.bookingId}`).get();
    assert.equal(b.get("price").visit.covered, true);
    assert.ok(b.get("price").packageId, "the renewal covers it");
  });
});
