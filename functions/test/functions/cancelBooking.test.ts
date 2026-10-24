import { strict as assert } from "node:assert";
import { Timestamp } from "firebase-admin/firestore";
import { adminDb, callFunction, clearEmulators, seedSettings } from "../helpers/env";
import { guardianWithChildren, openNonVaccineDay, seedBookingSettings, visit } from "../helpers/booking";

type Created = { bookingId: string };

describe("cancelBooking (FR-020, FR-021)", () => {
  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedBookingSettings();
  });

  const slot = async (date: string) => (await adminDb().doc(`slots/${date}_18`).get()).get("taken");

  it("before the window: cancelled, place freed at once, event written", async () => {
    const g = await guardianWithChildren("+201000000099");
    const day = openNonVaccineDay();
    const { result } = await callFunction<Created>("createBooking", visit(day, 18, g.childIds), g);
    assert.equal(await slot(day), 1);
    const res = await callFunction("cancelBooking", { bookingId: result!.bookingId }, g);
    assert.deepEqual(res, { result: {} });
    const b = (await adminDb().doc(`bookings/${result!.bookingId}`).get()).data()!;
    assert.equal(b.status, "cancelled");
    assert.equal(b.cancelledBy, g.uid);
    assert.equal(await slot(day), 0);
    const events = (await adminDb().collection(`bookings/${result!.bookingId}/events`).get()).docs.map((d) => d.get("type"));
    assert.ok(events.includes("cancelled"));
    // The family can book that day again.
    assert.ok((await callFunction("createBooking", visit(day, 19, g.childIds), g)).result);
  });

  it("inside the window: refused (inside_window)", async () => {
    const g = await guardianWithChildren("+201000000099");
    const { result } = await callFunction<Created>("createBooking", visit(openNonVaccineDay(), 18, g.childIds), g);
    await adminDb().doc(`bookings/${result!.bookingId}`).update({ startsAt: Timestamp.fromMillis(Date.now() + 2 * 3600_000) });
    const res = await callFunction("cancelBooking", { bookingId: result!.bookingId }, g);
    assert.equal(res.error?.details?.reason, "inside_window");
  });

  it("uses cancelWindowHours from settings", async () => {
    await seedBookingSettings({ cancelWindowHours: 1 });
    const g = await guardianWithChildren("+201000000099");
    const { result } = await callFunction<Created>("createBooking", visit(openNonVaccineDay(), 18, g.childIds), g);
    await adminDb().doc(`bookings/${result!.bookingId}`).update({ startsAt: Timestamp.fromMillis(Date.now() + 2 * 3600_000) });
    assert.ok((await callFunction("cancelBooking", { bookingId: result!.bookingId }, g)).result);
  });

  it("a booking that is not confirmed cannot be cancelled", async () => {
    const g = await guardianWithChildren("+201000000099");
    const { result } = await callFunction<Created>("createBooking", visit(openNonVaccineDay(), 18, g.childIds), g);
    await adminDb().doc(`bookings/${result!.bookingId}`).update({ status: "arrived" });
    const res = await callFunction("cancelBooking", { bookingId: result!.bookingId }, g);
    assert.equal(res.error?.details?.reason, "not_confirmed");
  });

  it("another guardian gets not-found", async () => {
    const a = await guardianWithChildren("+201000000099");
    const b = await guardianWithChildren("+201000000088");
    const { result } = await callFunction<Created>("createBooking", visit(openNonVaccineDay(), 18, a.childIds), a);
    const res = await callFunction("cancelBooking", { bookingId: result!.bookingId }, b);
    assert.equal(res.error?.status, "NOT_FOUND");
  });
});
