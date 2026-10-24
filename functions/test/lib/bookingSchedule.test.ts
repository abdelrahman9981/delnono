import { strict as assert } from "node:assert";
import { hoursOf, insideCancelWindow, isOpenDay, isVaccineDay, slotProblem } from "../../src/lib/booking/schedule";
import { BOOKING_DEFAULTS, bookingSettingsFrom } from "../../src/lib/booking/settings";
import { startsAt } from "../../src/lib/booking/time";

// Shared cases with test/features/booking/schedule_test.dart (the app mirrors these rules).
const s = BOOKING_DEFAULTS;
const now = new Date("2026-11-15T10:00:00Z"); // Sunday 15 Nov 2026, 12:00 Cairo

describe("booking schedule", () => {
  it("open days follow working hours and holidays", () => {
    assert.equal(isOpenDay(s, "2026-11-15"), true); // Sunday
    assert.equal(isOpenDay(s, "2026-11-13"), false); // Friday
    assert.equal(isOpenDay({ ...s, holidays: ["2026-11-16"] }, "2026-11-16"), false);
  });

  it("vaccine days are open days on vaccine weekdays", () => {
    assert.equal(isVaccineDay(s, "2026-11-16"), true); // Monday
    assert.equal(isVaccineDay(s, "2026-11-15"), false);
  });

  it("hours of a day come from its ranges", () => {
    assert.deepEqual(hoursOf(s, "2026-11-15"), [17, 18, 19, 20]);
    assert.deepEqual(hoursOf(s, "2026-11-13"), []);
  });

  it("slot problems in order", () => {
    assert.equal(slotProblem(s, "2026-11-15", 18, now, false), null);
    assert.equal(slotProblem(s, "2026-11-14", 18, now, false), "started");
    assert.equal(slotProblem(s, "2026-11-30", 18, now, false), "beyond_horizon");
    assert.equal(slotProblem(s, "2026-11-29", 18, now, false), null); // exactly 14 days ahead
    assert.equal(slotProblem(s, "2026-11-20", 18, now, false), "closed"); // Friday
    assert.equal(slotProblem(s, "2026-11-15", 12, now, false), "outside_hours");
    assert.equal(slotProblem(s, "2026-11-15", 18, new Date("2026-11-15T16:00:00Z"), false), "started");
    assert.equal(slotProblem(s, "2026-11-15", 18, now, true), "not_vaccine_day");
    assert.equal(slotProblem(s, "2026-11-16", 18, now, true), null);
  });

  it("cancel window uses cancelWindowHours", () => {
    const start = startsAt("2026-11-15", 18); // 16:00 UTC
    assert.equal(insideCancelWindow(s, start, new Date("2026-11-15T12:59:00Z")), false);
    assert.equal(insideCancelWindow(s, start, new Date("2026-11-15T13:00:00Z")), true);
    assert.equal(insideCancelWindow({ ...s, cancelWindowHours: 1 }, start, new Date("2026-11-15T13:00:00Z")), false);
  });

  it("settings fall back to defaults field by field", () => {
    const r = bookingSettingsFrom({ capacityPerHour: 4, holidays: ["2026-12-25"] }, undefined);
    assert.equal(r.capacityPerHour, 4);
    assert.deepEqual(r.holidays, ["2026-12-25"]);
    assert.equal(r.visitPrice, 300);
  });

  it("clinic values come from the clinic, family limits from settings/booking (004, D-49)", () => {
    const r = bookingSettingsFrom(
      { visitPrice: 350, cancelWindowHours: 6, maxUpcomingPerFamily: 9, vaccinePrices: { v1: { offered: true, price: 170, shown: true } } },
      { maxUpcomingPerFamily: 3, bookingHorizonDays: 7, visitPrice: 1 },
    );
    assert.equal(r.visitPrice, 350);
    assert.equal(r.cancelWindowHours, 6);
    assert.equal(r.maxUpcomingPerFamily, 3, "the family maximum is not a clinic setting");
    assert.equal(r.bookingHorizonDays, 7);
    assert.deepEqual(r.vaccinePrices.v1, { offered: true, price: 170, shown: true });
  });
});
