import { strict as assert } from "node:assert";
import { weekday } from "../../src/lib/booking/time";
import { adminDb, callFunction, clearEmulators, seedSettings } from "../helpers/env";
import {
  CLINIC,
  CLINIC_2,
  closedDay,
  guardianWithChildren,
  openNonVaccineDay,
  seedBookingSettings,
  seedClinic,
  slotPath,
  vaccineDay,
  visit,
} from "../helpers/booking";

type Result = { bookingId: string; number: number; price: { total: number; visit: { amount: number; covered: boolean } | null; vaccines: unknown[]; hasHiddenPrices: boolean } };

/** Three different open days, for limit tests. */
function threeOpenDays(): string[] {
  const days = new Set<string>();
  for (let from = 1; days.size < 3 && from <= 14; from++) days.add(openNonVaccineDay(from));
  return [...days].slice(0, 3);
}

const slot = async (date: string, hour: number) =>
  (await adminDb().doc(`slots/clinic-1_${date}_${String(hour).padStart(2, "0")}`).get()).get("taken");

describe("createBooking", () => {
  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedBookingSettings();
  });

  describe("US1 book a visit", () => {
    it("one child: booked, number assigned, one place taken, event written", async () => {
      const g = await guardianWithChildren("+201000000099");
      const day = openNonVaccineDay();
      const res = await callFunction<Result>("createBooking", visit(day, 18, g.childIds), g);
      assert.ok(res.result, JSON.stringify(res.error));
      assert.equal(res.result.number, 1);
      assert.equal(res.result.price.total, 300);
      const b = (await adminDb().doc(`bookings/${res.result.bookingId}`).get()).data()!;
      assert.equal(b.status, "confirmed");
      assert.equal(b.guardianUid, g.uid);
      assert.equal(b.children[0].name, "طفل 1");
      assert.equal(await slot(day, 18), 1);
      const events = await adminDb().collection(`bookings/${res.result.bookingId}/events`).get();
      assert.equal(events.docs[0].get("type"), "created");
    });

    it("two siblings take one place and pay one visit price (FR-013)", async () => {
      const g = await guardianWithChildren("+201000000099", 2);
      const day = openNonVaccineDay();
      const res = await callFunction<Result>("createBooking", visit(day, 18, g.childIds), g);
      assert.equal(res.result?.price.total, 300);
      assert.equal(await slot(day, 18), 1);
    });

    it("numbers increase", async () => {
      const a = await guardianWithChildren("+201000000099");
      const b = await guardianWithChildren("+201000000088");
      const day = openNonVaccineDay();
      const r1 = await callFunction<Result>("createBooking", visit(day, 18, a.childIds), a);
      const r2 = await callFunction<Result>("createBooking", visit(day, 18, b.childIds), b);
      assert.equal(r2.result!.number, r1.result!.number + 1);
    });

    it("refuses a child that is not linked to the caller", async () => {
      const a = await guardianWithChildren("+201000000099");
      const b = await guardianWithChildren("+201000000088");
      const res = await callFunction("createBooking", visit(openNonVaccineDay(), 18, b.childIds), a);
      assert.equal(res.error?.status, "INVALID_ARGUMENT");
      assert.equal(res.error?.details?.field, "children");
    });

    it("refuses a malformed selection", async () => {
      const g = await guardianWithChildren("+201000000099");
      for (const bad of [{ ...visit("15/11/2026", 18, g.childIds) }, { ...visit(openNonVaccineDay(), 25, g.childIds) }, { ...visit(openNonVaccineDay(), 18, []) }]) {
        const res = await callFunction("createBooking", bad, g);
        assert.equal(res.error?.status, "INVALID_ARGUMENT", JSON.stringify(bad));
      }
    });

    for (const [reason, sel] of [
      ["closed", () => ({ date: closedDay(), hour: 18 })],
      ["outside_hours", () => ({ date: openNonVaccineDay(), hour: 10 })],
      ["beyond_horizon", () => ({ date: "2099-01-01", hour: 18 })],
      ["started", () => ({ date: "2020-01-01", hour: 18 })],
    ] as const) {
      it(`failed-precondition ${reason}`, async () => {
        const g = await guardianWithChildren("+201000000099");
        const { date, hour } = sel();
        const res = await callFunction("createBooking", visit(date, hour, g.childIds), g);
        assert.equal(res.error?.status, "FAILED_PRECONDITION");
        assert.equal(res.error?.details?.reason, reason);
      });
    }

    it("one active booking per family per day (FR-011)", async () => {
      const g = await guardianWithChildren("+201000000099", 2);
      const day = openNonVaccineDay();
      const first = await callFunction<Result>("createBooking", visit(day, 18, [g.childIds[0]]), g);
      const second = await callFunction("createBooking", visit(day, 19, [g.childIds[1]]), g);
      assert.equal(second.error?.status, "ALREADY_EXISTS");
      assert.equal(second.error?.details?.bookingId, first.result!.bookingId);
    });

    it("at most maxUpcomingPerFamily upcoming bookings (FR-011a)", async () => {
      const g = await guardianWithChildren("+201000000099");
      const days = threeOpenDays();
      assert.equal(days.length, 3, "need three open days");
      assert.ok((await callFunction("createBooking", visit(days[0], 18, g.childIds), g)).result);
      assert.ok((await callFunction("createBooking", visit(days[1], 18, g.childIds), g)).result);
      const third = await callFunction("createBooking", visit(days[2], 18, g.childIds), g);
      assert.equal(third.error?.status, "OUT_OF_RANGE");
    });

    it("price_changed when the shown total is not today's price (FR-015); nothing is written", async () => {
      const g = await guardianWithChildren("+201000000099");
      const day = openNonVaccineDay();
      const res = await callFunction("createBooking", visit(day, 18, g.childIds, 250), g);
      assert.equal(res.error?.status, "FAILED_PRECONDITION");
      assert.equal(res.error?.details?.reason, "price_changed");
      assert.equal((res.error?.details?.price as { total: number }).total, 300);
      assert.equal(await slot(day, 18), undefined);
      assert.equal((await adminDb().collection("bookings").get()).size, 0);
    });

    it("requires current consent", async () => {
      const g = await guardianWithChildren("+201000000099");
      await seedSettings({ policy: { currentVersion: 2 } });
      const res = await callFunction("createBooking", visit(openNonVaccineDay(), 18, g.childIds), g);
      assert.equal(res.error?.status, "FAILED_PRECONDITION");
    });

    it("same-family race: different hours the same day, and more days than the limit", async () => {
      const g = await guardianWithChildren("+201000000099");
      const day = openNonVaccineDay();
      const sameDay = await Promise.all([17, 18, 19].map((h) => callFunction<Result>("createBooking", visit(day, h, g.childIds), g)));
      assert.equal(sameDay.filter((r) => r.result).length, 1, "one booking that day");

      await clearEmulators();
      await seedSettings();
      await seedBookingSettings();
      const g2 = await guardianWithChildren("+201000000088");
      const days = threeOpenDays();
      const many = await Promise.all(days.map((d) => callFunction<Result>("createBooking", visit(d, 18, g2.childIds), g2)));
      assert.equal(many.filter((r) => r.result).length, 2, "never more than maxUpcomingPerFamily");
    });
  });

  describe("US2 no double booking of the last place (FR-009, SC-002)", () => {
    it("five guardians race for the last place: exactly one wins, the rest see full", async () => {
      const day = openNonVaccineDay();
      await adminDb().doc(`slots/clinic-1_${day}_18`).set({ date: day, hour: 18, taken: 5 });
      const guardians = await Promise.all(
        [1, 2, 3, 4, 5].map((i) => guardianWithChildren(`+20100000007${i}`)),
      );
      const results = await Promise.all(guardians.map((g) => callFunction<Result>("createBooking", visit(day, 18, g.childIds), g)));
      assert.equal(results.filter((r) => r.result).length, 1);
      for (const r of results.filter((x) => x.error)) {
        assert.equal(r.error?.status, "RESOURCE_EXHAUSTED");
        assert.equal(r.error?.details?.reason, "full");
      }
      assert.equal(await slot(day, 18), 6, "never above capacity");
      assert.equal((await adminDb().collection("bookings").get()).size, 1);
    });

    it("a full hour refuses at once", async () => {
      const g = await guardianWithChildren("+201000000099");
      const day = openNonVaccineDay();
      await adminDb().doc(`slots/clinic-1_${day}_18`).set({ date: day, hour: 18, taken: 6 });
      const res = await callFunction("createBooking", visit(day, 18, g.childIds), g);
      assert.equal(res.error?.details?.reason, "full");
    });
  });

  describe("US6 covered by package (FR-016)", () => {
    const pkg = (guardianUid: string, startsOn: string, endsOn: string, active = true) =>
      adminDb().collection("packages").add({ guardianUid, startsOn, endsOn, active });

    it("an active package covering the date: visit covered, vaccines charged", async () => {
      const g = await guardianWithChildren("+201000000099");
      const day = vaccineDay();
      const ref = await pkg(g.uid, "2020-01-01", "2099-12-31");
      const sel = { clinicId: CLINIC, visitType: "visit", date: day, hour: 18, children: [{ childId: g.childIds[0], vaccines: ["v1"] }], expectedTotal: 150 };
      const res = await callFunction<Result & { price: { packageId: string } }>("createBooking", sel, g);
      assert.ok(res.result, JSON.stringify(res.error));
      assert.deepEqual(res.result.price.visit, { amount: 0, covered: true });
      assert.equal(res.result.price.total, 150);
      assert.equal(res.result.price.packageId, ref.id);
    });

    it("an expired, inactive or other family's package is not used", async () => {
      const g = await guardianWithChildren("+201000000099");
      const other = await guardianWithChildren("+201000000088");
      await pkg(g.uid, "2020-01-01", "2020-12-31");
      await pkg(g.uid, "2020-01-01", "2099-12-31", false);
      await pkg(other.uid, "2020-01-01", "2099-12-31");
      const res = await callFunction<Result>("createBooking", visit(openNonVaccineDay(), 18, g.childIds), g);
      assert.equal(res.result?.price.total, 300);
    });
  });

  describe("US3 vaccines (FR-008, FR-014, D-31)", () => {
    const withVaccines = (date: string, children: { childId: string; vaccines: string[] }[], visitType: string, expectedTotal: number) =>
      ({ clinicId: CLINIC, visitType, date, hour: 18, children, expectedTotal });

    it("vaccine only on a vaccine day: no visit price, vaccine price only, one place", async () => {
      const g = await guardianWithChildren("+201000000099");
      const day = vaccineDay();
      const res = await callFunction<Result>("createBooking", withVaccines(day, [{ childId: g.childIds[0], vaccines: ["v2"] }], "vaccine_only", 200), g);
      assert.ok(res.result, JSON.stringify(res.error));
      assert.equal(res.result.price.visit, null);
      assert.equal(res.result.price.total, 200);
      assert.equal(await slot(day, 18), 1);
    });

    it("a visit with vaccines per child adds each vaccine once per child", async () => {
      const g = await guardianWithChildren("+201000000099", 2);
      const sel = [{ childId: g.childIds[0], vaccines: ["v1", "v2"] }, { childId: g.childIds[1], vaccines: ["v1"] }];
      const res = await callFunction<Result>("createBooking", withVaccines(vaccineDay(), sel, "visit", 300 + 150 + 200 + 150), g);
      assert.equal(res.result?.price.total, 800);
      assert.equal(res.result?.price.vaccines.length, 3);
    });

    it("vaccines on a non-vaccine day are refused (not_vaccine_day)", async () => {
      const g = await guardianWithChildren("+201000000099");
      const res = await callFunction("createBooking", withVaccines(openNonVaccineDay(), [{ childId: g.childIds[0], vaccines: ["v1"] }], "visit", 450), g);
      assert.equal(res.error?.details?.reason, "not_vaccine_day");
    });

    it("vaccine only without a vaccine, or with an inactive vaccine, is invalid", async () => {
      const g = await guardianWithChildren("+201000000099");
      const none = await callFunction("createBooking", withVaccines(vaccineDay(), [{ childId: g.childIds[0], vaccines: [] }], "vaccine_only", 0), g);
      assert.equal(none.error?.status, "INVALID_ARGUMENT");
      const inactive = await callFunction("createBooking", withVaccines(vaccineDay(), [{ childId: g.childIds[0], vaccines: ["v4"] }], "vaccine_only", 300), g);
      assert.equal(inactive.error?.status, "INVALID_ARGUMENT");
      assert.equal(inactive.error?.details?.field, "vaccines");
    });

    it("a hidden-price vaccine is stored for the clinic but left out of the shown total", async () => {
      const g = await guardianWithChildren("+201000000099");
      const res = await callFunction<Result>("createBooking", withVaccines(vaccineDay(), [{ childId: g.childIds[0], vaccines: ["v3"] }], "visit", 300), g);
      assert.equal(res.result?.price.total, 300);
      assert.equal(res.result?.price.hasHiddenPrices, true);
      assert.deepEqual(res.result?.price.vaccines[0], { childId: g.childIds[0], vaccineId: "v3", name: "[تطعيم ٣]", amount: 450, shown: false });
    });
  });

  describe("004 two clinics", () => {
    /** Clinic 2: mornings Sun–Thu, 5 places, visit 350, v1 at 170, v2 not offered, 6-hour window. */
    const morning = [{ from: 10, to: 14 }];
    async function seedSecondClinic(fields: Record<string, unknown> = {}) {
      await seedClinic(CLINIC_2, {
        order: 1,
        capacityPerHour: 5,
        workingHours: { "1": morning, "2": morning, "3": morning, "4": morning, "5": [], "6": [], "7": morning },
        vaccineWeekdays: [1, 3],
        visitPrice: 350,
        cancelWindowHours: 6,
        vaccinePrices: { v1: { offered: true, price: 170, shown: true }, v2: { offered: false, price: 0, shown: true } },
        ...fields,
      });
    }
    /** An open day of clinic 2: clinic 1's open days except Saturday (weekday 6). */
    const clinic2Day = (from = 1): string => {
      const d = openNonVaccineDay(from);
      return weekday(d) === 6 ? clinic2Day(from + 1) : d;
    };
    const mondayOrWednesday = () => vaccineDay();

    it("uses the chosen clinic's hours, capacity and prices; booking and slot carry the clinic (FR-007 to FR-009)", async () => {
      await seedSecondClinic();
      const g = await guardianWithChildren("+201000000099");
      const day = mondayOrWednesday();
      const evening = await callFunction("createBooking", visit(day, 18, g.childIds, 350, CLINIC_2), g);
      assert.equal(evening.error?.details?.reason, "outside_hours", "18:00 is clinic 1's hours, not clinic 2's");
      const res = await callFunction<Result>("createBooking", visit(day, 11, g.childIds, 350, CLINIC_2), g);
      assert.ok(res.result, JSON.stringify(res.error));
      assert.equal(res.result.price.total, 350);
      const booking = await adminDb().doc(`bookings/${res.result.bookingId}`).get();
      assert.equal(booking.get("clinicId"), CLINIC_2);
      assert.equal((await adminDb().doc(slotPath(day, 11, CLINIC_2)).get()).get("taken"), 1);
      assert.equal((await adminDb().doc(slotPath(day, 11, CLINIC_2)).get()).get("clinicId"), CLINIC_2);
    });

    it("a full hour at one clinic does not affect the other (FR-008)", async () => {
      await seedSecondClinic({ workingHours: { "1": [{ from: 17, to: 21 }], "2": [{ from: 17, to: 21 }], "3": [{ from: 17, to: 21 }], "4": [{ from: 17, to: 21 }], "6": [{ from: 17, to: 21 }], "7": [{ from: 17, to: 21 }] } });
      const g = await guardianWithChildren("+201000000099");
      const day = openNonVaccineDay();
      await adminDb().doc(slotPath(day, 18)).set({ clinicId: CLINIC, date: day, hour: 18, taken: 6 });
      const full = await callFunction("createBooking", visit(day, 18, g.childIds), g);
      assert.equal(full.error?.details?.reason, "full");
      const other = await callFunction<Result>("createBooking", visit(day, 18, g.childIds, 350, CLINIC_2), g);
      assert.ok(other.result, JSON.stringify(other.error));
    });

    it("vaccine prices are the clinic's; a vaccine not offered there is refused (FR-002)", async () => {
      await seedSecondClinic();
      const g = await guardianWithChildren("+201000000099");
      const day = mondayOrWednesday();
      const sel = (vaccines: string[], expectedTotal: number) => ({
        clinicId: CLINIC_2, visitType: "vaccine_only", date: day, hour: 11, children: [{ childId: g.childIds[0], vaccines }], expectedTotal,
      });
      const notOffered = await callFunction("createBooking", sel(["v2"], 200), g);
      assert.equal(notOffered.error?.details?.field, "vaccines");
      const ok = await callFunction<Result>("createBooking", sel(["v1"], 170), g);
      assert.ok(ok.result, JSON.stringify(ok.error));
      assert.equal(ok.result.price.total, 170);
    });

    it("an inactive or unknown clinic is refused; the clinic id is required", async () => {
      await seedSecondClinic({ active: false });
      const g = await guardianWithChildren("+201000000099");
      const day = mondayOrWednesday();
      const inactive = await callFunction("createBooking", visit(day, 11, g.childIds, 350, CLINIC_2), g);
      assert.equal(inactive.error?.details?.reason, "clinic_inactive");
      const unknown = await callFunction("createBooking", visit(day, 11, g.childIds, 350, "nope"), g);
      assert.equal(unknown.error?.details?.reason, "clinic_inactive");
      const { clinicId: _, ...missing } = visit(day, 18, g.childIds);
      const noClinic = await callFunction("createBooking", missing, g);
      assert.equal(noClinic.error?.details?.field, "clinicId");
    });

    it("one booking per day across clinics (D-49)", async () => {
      await seedSecondClinic();
      const g = await guardianWithChildren("+201000000099");
      const day = mondayOrWednesday();
      assert.ok((await callFunction("createBooking", visit(day, 18, g.childIds), g)).result);
      const same = await callFunction("createBooking", visit(day, 11, g.childIds, 350, CLINIC_2), g);
      assert.equal(same.error?.status, "ALREADY_EXISTS");
    });

    it("the upcoming maximum counts both clinics (D-49)", async () => {
      await seedSecondClinic();
      const g = await guardianWithChildren("+201000000099");
      // Days both clinics are open: clinic 2 is closed on Saturdays (weekday 6).
      const days: string[] = [];
      for (let from = 1; days.length < 3; from++) {
        const d = openNonVaccineDay(from);
        if (weekday(d) !== 6 && !days.includes(d)) days.push(d);
      }
      const [d1, d2, d3] = days;
      assert.ok((await callFunction("createBooking", visit(d1, 18, g.childIds), g)).result);
      assert.ok((await callFunction("createBooking", visit(d2, 11, g.childIds, 350, CLINIC_2), g)).result);
      const third = await callFunction("createBooking", visit(d3, 11, g.childIds, 350, CLINIC_2), g);
      assert.equal(third.error?.status, "OUT_OF_RANGE");
    });

    it("the last place at a clinic goes to exactly one of two simultaneous families", async () => {
      await seedSecondClinic();
      const a = await guardianWithChildren("+201000000099");
      const b = await guardianWithChildren("+201000000088");
      const day = clinic2Day();
      await adminDb().doc(slotPath(day, 11, CLINIC_2)).set({ clinicId: CLINIC_2, date: day, hour: 11, taken: 4 });
      const results = await Promise.all([a, b].map((g) => callFunction("createBooking", visit(day, 11, g.childIds, 350, CLINIC_2), g)));
      assert.equal(results.filter((r) => r.result).length, 1);
      assert.equal((await adminDb().doc(slotPath(day, 11, CLINIC_2)).get()).get("taken"), 5);
    });

    it("a package sold at clinic 1 covers a visit at clinic 2; vaccines at clinic 2's price (D-46)", async () => {
      await seedSecondClinic();
      const g = await guardianWithChildren("+201000000099");
      await adminDb().collection("packages").add({ guardianUid: g.uid, startsOn: "2020-01-01", endsOn: "2099-12-31", active: true, soldAtClinicId: CLINIC });
      const day = mondayOrWednesday();
      const sel = { clinicId: CLINIC_2, visitType: "visit", date: day, hour: 11, children: [{ childId: g.childIds[0], vaccines: ["v1"] }], expectedTotal: 170 };
      const res = await callFunction<Result>("createBooking", sel, g);
      assert.ok(res.result, JSON.stringify(res.error));
      assert.deepEqual(res.result.price.visit, { amount: 0, covered: true });
      assert.equal(res.result.price.total, 170);
      assert.equal((await adminDb().doc(`bookings/${res.result.bookingId}`).get()).get("clinicId"), CLINIC_2);
    });
  });
});
