import { strict as assert } from "node:assert";
import { addDays, cairoDate, slotId, startsAt, weekday } from "../../src/lib/booking/time";

describe("booking time (Cairo)", () => {
  it("winter hour start: 18:00 Cairo is 16:00 UTC", () => {
    assert.equal(startsAt("2026-11-15", 18).toISOString(), "2026-11-15T16:00:00.000Z");
  });

  it("summer-time hour start: 18:00 Cairo is 15:00 UTC", () => {
    assert.equal(startsAt("2026-07-15", 18).toISOString(), "2026-07-15T15:00:00.000Z");
  });

  it("Cairo date of an instant crosses midnight before UTC does", () => {
    assert.equal(cairoDate(new Date("2026-11-15T22:30:00Z")), "2026-11-16");
  });

  it("ISO weekdays", () => {
    assert.equal(weekday("2026-11-16"), 1); // Monday
    assert.equal(weekday("2026-11-15"), 7); // Sunday
    assert.equal(weekday("2026-11-13"), 5); // Friday
  });

  it("adds days across months and slot ids are padded", () => {
    assert.equal(addDays("2026-11-28", 5), "2026-12-03");
    assert.equal(slotId("clinic-1", "2026-11-15", 9), "clinic-1_2026-11-15_09");
  });
});
