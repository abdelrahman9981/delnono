import { strict as assert } from "node:assert";
import { adminDb, callFunction, clearEmulators, seedSettings } from "../helpers/env";
import {
  closedDay,
  guardianWithChildren,
  openNonVaccineDay,
  seedBookingSettings,
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
  (await adminDb().doc(`slots/${date}_${String(hour).padStart(2, "0")}`).get()).get("taken");

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

  // Keeps the vaccine-day helper referenced until the US3 cases are added here.
  it("a vaccine day exists within the horizon", () => {
    assert.ok(vaccineDay());
  });
});
