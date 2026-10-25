import { strict as assert } from "node:assert";
import { Timestamp } from "firebase-admin/firestore";
import { adminDb, callFunction, clearEmulators, seedSettings } from "../../helpers/env";
import { CLINIC, CLINIC_2, guardianWithChildren, openNonVaccineDay, seedBookingSettings, seedClinic, slotPath, visit } from "../../helpers/booking";
import { cairoDate, startsAt } from "../../../src/lib/booking/time";
import { doctor, secretary1, secretary2 } from "../../helpers/staff";

/** Every hour open on every day, so "today" always has hours in the tests. */
const allDay = [{ from: 0, to: 24 }];
const always = { "1": allDay, "2": allDay, "3": allDay, "4": allDay, "5": allDay, "6": allDay, "7": allDay };

/** A booking for today at [hour] written directly (the app cannot book an hour that has started). */
async function todayBooking(guardianUid: string, childIds: string[], hour: number, extra: Record<string, unknown> = {}) {
  const date = cairoDate();
  const ref = adminDb().collection("bookings").doc();
  await ref.set({
    clinicId: CLINIC, guardianUid, guardianPhone: "+201000000099", date, hour, startsAt: Timestamp.fromDate(startsAt(date, hour)),
    status: "confirmed", visitType: "visit", number: 1,
    children: childIds.map((childId) => ({ childId, name: "طفل", vaccines: [] })),
    price: { visit: { amount: 300, covered: false }, vaccines: [], total: 300, hasHiddenPrices: false, packageId: null },
    ...extra,
  });
  return ref.id;
}

const currentHour = () => Number(new Intl.DateTimeFormat("en-GB", { timeZone: "Africa/Cairo", hour: "2-digit", hourCycle: "h23" }).format(new Date()));

/**
 * Tests here act on the current hour; one that starts in the hour's last seconds would see the hour
 * end mid-test (the server then refuses it). Near the turn of the hour, wait for the next one.
 * Cairo has whole-hour offsets, so the hour turns when UTC minutes and seconds are zero.
 */
async function awayFromHourEnd(marginMs = 45_000): Promise<void> {
  const left = 3_600_000 - (Date.now() % 3_600_000);
  if (left < marginMs) await new Promise((r) => setTimeout(r, left + 1_000));
}

describe("today: queue, walk-ins, payments, packages (005 US2, US3)", () => {
  beforeEach(async () => {
    await awayFromHourEnd();
    await clearEmulators();
    await seedSettings();
    await seedBookingSettings({ workingHours: always });
  });

  it("arrive → done records a visit per child at the clinic; no-show only after the hour (FR-006, FR-010)", async () => {
    const s = await secretary1();
    const g = await guardianWithChildren("+201000000099", 2);
    const now = await todayBooking(g.uid, g.childIds, currentHour());
    assert.equal((await callFunction("queueAction", { action: "noShow", bookingId: now }, s)).error?.details?.reason, "hour_not_over");
    assert.ok((await callFunction("queueAction", { action: "arrive", bookingId: now }, s)).result);
    assert.ok((await adminDb().doc(`bookings/${now}`).get()).get("arrivedAt"));
    assert.ok((await callFunction("queueAction", { action: "done", bookingId: now }, s)).result);
    for (const c of g.childIds) {
      const v = await adminDb().doc(`children/${c}/visits/${now}`).get();
      assert.equal(v.get("clinicId"), CLINIC);
      assert.equal(v.get("bookingId"), now);
    }
    assert.equal((await callFunction("queueAction", { action: "arrive", bookingId: now }, s)).error?.details?.reason, "wrong_status");
  });

  it("no-show after the hour; only the doctor undoes, the same day", async () => {
    const s = await secretary1();
    const d = await doctor();
    const g = await guardianWithChildren("+201000000099");
    const hour = currentHour();
    if (hour === 0) return; // no earlier hour today
    const id = await todayBooking(g.uid, g.childIds, hour - 1);
    assert.ok((await callFunction("queueAction", { action: "noShow", bookingId: id }, s)).result);
    assert.equal((await callFunction("queueAction", { action: "undo", bookingId: id }, s)).error?.status, "PERMISSION_DENIED");
    assert.ok((await callFunction("queueAction", { action: "undo", bookingId: id }, d)).result);
    assert.equal((await adminDb().doc(`bookings/${id}`).get()).get("status"), "confirmed");
    assert.equal((await adminDb().collection("auditLog").where("action", "==", "status.undone").get()).size, 1);
  });

  it("a secretary cannot act on the other clinic's booking (D-47)", async () => {
    const s2 = await secretary2();
    const g = await guardianWithChildren("+201000000099");
    const id = await todayBooking(g.uid, g.childIds, currentHour());
    assert.equal((await callFunction("queueAction", { action: "arrive", bookingId: id }, s2)).error?.status, "PERMISSION_DENIED");
  });

  it("walk-ins take places in the hour; full and stopped are refused (FR-007, FR-008)", async () => {
    await seedClinic(CLINIC, { order: 0, workingHours: always, capacityPerHour: 2 });
    const s = await secretary1();
    const hour = currentHour();
    const walkIn = (name: string) => callFunction<{ walkInId: string }>("addWalkIn", {
      clinicId: CLINIC, hour, familyName: name, phone: "01000000055", children: [{ name: "سما" }], visitType: "visit",
    }, s);
    assert.ok((await walkIn("أ")).result);
    assert.ok((await walkIn("ب")).result);
    assert.equal((await walkIn("ج")).error?.details?.reason, "full");
    assert.equal((await adminDb().doc(slotPath(cairoDate(), hour)).get()).get("taken"), 2);
    await callFunction("setWalkInsStopped", { clinicId: CLINIC, stopped: true }, s);
    await seedClinic(CLINIC, { order: 0, workingHours: always, capacityPerHour: 9 });
    assert.equal((await walkIn("د")).error?.details?.reason, "walk_ins_stopped");
  });

  it("a walk-in is done like a booking; visits only for registered children", async () => {
    const s = await secretary1();
    const g = await guardianWithChildren("+201000000099");
    const res = await callFunction<{ walkInId: string }>("addWalkIn", {
      clinicId: CLINIC, hour: currentHour(), familyName: "عائلة", phone: "01000000099",
      children: [{ childId: g.childIds[0], name: "طفل" }, { name: "ضيف" }], visitType: "visit",
    }, s);
    assert.ok(res.result, JSON.stringify(res.error));
    assert.ok((await callFunction("queueAction", { action: "done", walkInId: res.result.walkInId }, s)).result);
    const v = await adminDb().doc(`children/${g.childIds[0]}/visits/${res.result.walkInId}`).get();
    assert.equal(v.get("type"), "walkIn");
  });

  it("payment on a done visit; covered needs an active package (FR-011)", async () => {
    const s = await secretary1();
    const g = await guardianWithChildren("+201000000099");
    const id = await todayBooking(g.uid, g.childIds, currentHour(), { status: "done" });
    assert.equal((await callFunction("recordPayment", { bookingId: id, cash: 0, covered: true }, s)).error?.details?.reason, "no_package");
    assert.ok((await callFunction("recordPayment", { bookingId: id, cash: 300, covered: false }, s)).result);
    assert.equal((await adminDb().doc(`bookings/${id}`).get()).get("payment.cash"), 300);
  });

  it("sell a package at the clinic's price, valid from today; a second is refused (FR-012, D-46)", async () => {
    await seedClinic(CLINIC_2, { packagePrice: 1700, packageMonths: 12 });
    const s2 = await secretary2();
    const g = await guardianWithChildren("+201000000099");
    const res = await callFunction<{ packageId: string; price: number; endsOn: string }>("sellPackage", { clinicId: CLINIC_2, guardianUid: g.uid }, s2);
    assert.ok(res.result, JSON.stringify(res.error));
    assert.equal(res.result.price, 1700);
    const pkg = await adminDb().doc(`packages/${res.result.packageId}`).get();
    assert.equal(pkg.get("soldAtClinicId"), CLINIC_2);
    assert.equal(pkg.get("startsOn"), cairoDate());
    assert.equal((await callFunction("sellPackage", { clinicId: CLINIC_2, guardianUid: g.uid }, s2)).error?.details?.reason, "has_package");
    // The package covers a visit recorded at clinic 1 too.
    const s1 = await secretary1();
    const id = await todayBooking(g.uid, g.childIds, currentHour(), { status: "done" });
    assert.ok((await callFunction("recordPayment", { bookingId: id, cash: 0, covered: true }, s1)).result);
  });

  it("staff cancel inside the window and move a booking for the family (FR-009)", async () => {
    const s = await secretary1();
    const g = await guardianWithChildren("+201000000099");
    const day = openNonVaccineDay();
    const { result } = await callFunction<{ bookingId: string }>("createBooking", visit(day, 18, g.childIds), g);
    await adminDb().doc(`bookings/${result!.bookingId}`).update({ startsAt: Timestamp.fromMillis(Date.now() + 3600_000) });
    const moved = await callFunction("staffBookingAction", {
      action: "change", bookingId: result!.bookingId,
      selection: { visitType: "visit", date: day, hour: 19, children: [{ childId: g.childIds[0], vaccines: [] }] },
    }, s);
    assert.ok(moved.result, JSON.stringify(moved.error));
    assert.equal((await adminDb().doc(slotPath(day, 19)).get()).get("taken"), 1);
    assert.ok((await callFunction("staffBookingAction", { action: "cancel", bookingId: result!.bookingId }, s)).result);
    assert.equal((await adminDb().doc(`bookings/${result!.bookingId}`).get()).get("cancelledBy"), "sec1");
    assert.equal((await adminDb().doc(slotPath(day, 19)).get()).get("taken"), 0);
  });
});
