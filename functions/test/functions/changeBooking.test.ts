import { strict as assert } from "node:assert";
import { Timestamp } from "firebase-admin/firestore";
import { adminDb, callFunction, clearEmulators, seedSettings } from "../helpers/env";
import { CLINIC, CLINIC_2, guardianWithChildren, openNonVaccineDay, seedBookingSettings, seedClinic, vaccineDay, visit } from "../helpers/booking";

type Result = { bookingId: string; number: number; price: { total: number; visit: { amount: number } | null; vaccines: { vaccineId: string; amount: number }[] } };

const taken = async (date: string, hour: number) =>
  (await adminDb().doc(`slots/clinic-1_${date}_${String(hour).padStart(2, "0")}`).get()).get("taken") ?? 0;

const change = (bookingId: string, selection: ReturnType<typeof visit>) => {
  const { expectedTotal, ...rest } = selection;
  return { bookingId, selection: rest, expectedTotal };
};

describe("changeBooking (FR-022, FR-023)", () => {
  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedBookingSettings();
  });

  it("moves to another hour: old place freed, new taken, same number, event", async () => {
    const g = await guardianWithChildren("+201000000099");
    const day = openNonVaccineDay();
    const { result } = await callFunction<Result>("createBooking", visit(day, 18, g.childIds), g);
    const res = await callFunction<Result>("changeBooking", change(result!.bookingId, visit(day, 19, g.childIds)), g);
    assert.ok(res.result, JSON.stringify(res.error));
    assert.equal(res.result.number, result!.number);
    assert.equal(await taken(day, 18), 0);
    assert.equal(await taken(day, 19), 1);
    const b = (await adminDb().doc(`bookings/${result!.bookingId}`).get()).data()!;
    assert.equal(b.hour, 19);
    const events = (await adminDb().collection(`bookings/${result!.bookingId}/events`).get()).docs.map((d) => d.get("type"));
    assert.ok(events.includes("changed"));
  });

  it("same hour (e.g. adding a child): no change in places", async () => {
    const g = await guardianWithChildren("+201000000099", 2);
    const day = openNonVaccineDay();
    const { result } = await callFunction<Result>("createBooking", visit(day, 18, [g.childIds[0]]), g);
    const res = await callFunction<Result>("changeBooking", change(result!.bookingId, visit(day, 18, g.childIds)), g);
    assert.ok(res.result, JSON.stringify(res.error));
    assert.equal(await taken(day, 18), 1);
  });

  it("the new hour is full: the original booking is unchanged", async () => {
    const g = await guardianWithChildren("+201000000099");
    const day = openNonVaccineDay();
    const { result } = await callFunction<Result>("createBooking", visit(day, 18, g.childIds), g);
    await adminDb().doc(`slots/clinic-1_${day}_19`).set({ date: day, hour: 19, taken: 6 });
    const res = await callFunction("changeBooking", change(result!.bookingId, visit(day, 19, g.childIds)), g);
    assert.equal(res.error?.details?.reason, "full");
    assert.equal((await adminDb().doc(`bookings/${result!.bookingId}`).get()).get("hour"), 18);
    assert.equal(await taken(day, 18), 1);
  });

  it("inside the window: refused", async () => {
    const g = await guardianWithChildren("+201000000099");
    const day = openNonVaccineDay();
    const { result } = await callFunction<Result>("createBooking", visit(day, 18, g.childIds), g);
    await adminDb().doc(`bookings/${result!.bookingId}`).update({ startsAt: Timestamp.fromMillis(Date.now() + 3600_000) });
    const res = await callFunction("changeBooking", change(result!.bookingId, visit(day, 19, g.childIds)), g);
    assert.equal(res.error?.details?.reason, "inside_window");
  });

  it("keeps fixed amounts after a price rise; added vaccines use today's price (FR-023)", async () => {
    const g = await guardianWithChildren("+201000000099");
    const day = vaccineDay();
    const sel = { clinicId: CLINIC, visitType: "visit", date: day, hour: 18, children: [{ childId: g.childIds[0], vaccines: ["v1"] }], expectedTotal: 450 };
    const { result } = await callFunction<Result>("createBooking", sel, g);
    await seedBookingSettings({ visitPrice: 400 });
    await adminDb().doc("clinics/clinic-1").update({ "vaccinePrices.v1.price": 999 });
    const moved = { ...sel, hour: 19, children: [{ childId: g.childIds[0], vaccines: ["v1", "v2"] }], expectedTotal: 300 + 150 + 200 };
    const { expectedTotal, ...selection } = moved;
    const res = await callFunction<Result>("changeBooking", { bookingId: result!.bookingId, selection, expectedTotal }, g);
    assert.ok(res.result, JSON.stringify(res.error));
    assert.equal(res.result.price.visit?.amount, 300);
    assert.equal(res.result.price.vaccines.find((l) => l.vaccineId === "v1")!.amount, 150);
    assert.equal(res.result.price.vaccines.find((l) => l.vaccineId === "v2")!.amount, 200);
  });

  it("its own day does not count against one-per-day or the upcoming limit", async () => {
    const g = await guardianWithChildren("+201000000099");
    const d1 = openNonVaccineDay(1);
    let d2 = openNonVaccineDay(2);
    if (d2 === d1) d2 = openNonVaccineDay(3);
    const a = await callFunction<Result>("createBooking", visit(d1, 18, g.childIds), g);
    assert.ok((await callFunction<Result>("createBooking", visit(d2, 18, g.childIds), g)).result);
    // At the limit of 2: moving the first booking within its own day is still allowed.
    const res = await callFunction<Result>("changeBooking", change(a.result!.bookingId, visit(d1, 19, g.childIds)), g);
    assert.ok(res.result, JSON.stringify(res.error));
  });

  describe("004 two clinics", () => {
    it("a change stays at the booking's clinic, even if another clinic is sent (FR-010)", async () => {
      await seedClinic(CLINIC_2, { visitPrice: 350 });
      const g = await guardianWithChildren("+201000000099");
      const day = openNonVaccineDay();
      const { result } = await callFunction<Result>("createBooking", visit(day, 18, g.childIds), g);
      const res = await callFunction<Result>("changeBooking", change(result!.bookingId, visit(day, 19, g.childIds, 300, CLINIC_2)), g);
      assert.ok(res.result, JSON.stringify(res.error));
      assert.equal(res.result.price.total, 300, "clinic 1's price");
      const booking = await adminDb().doc(`bookings/${result!.bookingId}`).get();
      assert.equal(booking.get("clinicId"), CLINIC);
      assert.equal(await taken(day, 19), 1);
      assert.equal(await taken(day, 18), 0);
    });

    it("a booking stored without a clinic belongs to the main clinic (FR-018)", async () => {
      const g = await guardianWithChildren("+201000000099");
      const day = openNonVaccineDay();
      const { result } = await callFunction<Result>("createBooking", visit(day, 18, g.childIds), g);
      await adminDb().doc(`bookings/${result!.bookingId}`).update({ clinicId: null });
      const res = await callFunction<Result>("changeBooking", change(result!.bookingId, visit(day, 19, g.childIds)), g);
      assert.ok(res.result, JSON.stringify(res.error));
      assert.equal(await taken(day, 18), 0, "freed at the main clinic");
      assert.equal(await taken(day, 19), 1);
    });
  });
});
