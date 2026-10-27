import { strict as assert } from "node:assert";
import { hoursOf, slotProblem } from "../../src/lib/booking/schedule";
import { BOOKING_DEFAULTS, type BookingSettings } from "../../src/lib/booking/settings";

// The seeded clinics' hours (scripts/seed.ts), checked for every weekday on the server, as the app
// does in test/features/booking/seeded_hours_test.dart.
const c1Hours = [{ from: 13, to: 15 }, { from: 18, to: 22 }];
const c2Long = [{ from: 11, to: 14 }, { from: 17, to: 20 }];
const c2Evening = [{ from: 17, to: 21 }];
const moqattam: BookingSettings = {
  ...BOOKING_DEFAULTS,
  workingHours: { "1": c1Hours, "2": c1Hours, "3": c1Hours, "4": c1Hours, "5": [], "6": c1Hours, "7": c1Hours },
  holidays: ["2027-01-07"],
};
const nasrCity: BookingSettings = {
  ...BOOKING_DEFAULTS,
  capacityPerHour: 5,
  workingHours: { "1": c2Evening, "2": c2Long, "3": c2Long, "4": c2Evening, "5": [], "6": [], "7": c2Long },
};

describe("seeded clinic hours, every weekday", () => {
  const both = [13, 14, 18, 19, 20, 21];
  const long = [11, 12, 13, 17, 18, 19];
  const evening = [17, 18, 19, 20];
  const week: [string, string, number[], number[]][] = [
    ["2026-11-07", "Saturday", both, []],
    ["2026-11-08", "Sunday", both, long],
    ["2026-11-09", "Monday", both, evening],
    ["2026-11-10", "Tuesday", both, long],
    ["2026-11-11", "Wednesday", both, long],
    ["2026-11-12", "Thursday", both, evening],
    ["2026-11-13", "Friday", [], []],
  ];
  for (const [date, day, m, n] of week) {
    it(`${day} ${date}: only the working ranges`, () => {
      assert.deepEqual(hoursOf(moqattam, date), m, "Moqattam");
      assert.deepEqual(hoursOf(nasrCity, date), n, "Nasr City");
    });
  }

  it("a holiday is closed; an hour outside the ranges is refused", () => {
    assert.deepEqual(hoursOf(moqattam, "2027-01-07"), []);
    const before = new Date("2026-11-09T06:00:00Z");
    assert.equal(slotProblem(moqattam, "2026-11-10", 16, before, false), "outside_hours");
    assert.equal(slotProblem(moqattam, "2026-11-13", 18, before, false), "closed");
    assert.equal(slotProblem(moqattam, "2026-11-10", 18, before, false), null);
  });
});
