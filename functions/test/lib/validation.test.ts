import { strict as assert } from "node:assert";
import { HttpsError } from "firebase-functions/https";
import { cairoToday, validateBirthDate, validateChild, validateGuardian } from "../../src/lib/validation";

function failsOn(field: string, fn: () => unknown) {
  assert.throws(fn, (e: unknown) => e instanceof HttpsError && e.code === "invalid-argument" && (e.details as { field?: string } | undefined)?.field === field);
}

describe("validation (data-model.md constraints)", () => {
  // 2026-10-22 23:30 in Cairo is 20:30 UTC (UTC+3 in summer time).
  const now = new Date("2026-10-22T20:30:00Z");

  describe("guardian", () => {
    it("accepts valid input and trims", () => {
      assert.deepEqual(validateGuardian({ fullName: "  سارة محمود ", relation: "mother" }), {
        fullName: "سارة محمود",
        relation: "mother",
      });
      assert.equal(validateGuardian({ fullName: "سارة", relation: "other", email: "a@b.co" }).email, "a@b.co");
    });

    it("fullName: required, 2–80 chars", () => {
      failsOn("fullName", () => validateGuardian({ relation: "mother" }));
      failsOn("fullName", () => validateGuardian({ fullName: "س", relation: "mother" }));
      failsOn("fullName", () => validateGuardian({ fullName: "س".repeat(81), relation: "mother" }));
    });

    it("relation: mother | father | other", () => {
      failsOn("relation", () => validateGuardian({ fullName: "سارة", relation: "aunt" }));
    });

    it("email: optional, valid if present", () => {
      assert.equal(validateGuardian({ fullName: "سارة", relation: "mother", email: "" }).email, undefined);
      failsOn("email", () => validateGuardian({ fullName: "سارة", relation: "mother", email: "not-an-email" }));
    });
  });

  describe("birthDate: required, not in future, within 18 years", () => {
    it("uses the Cairo date", () => {
      assert.equal(cairoToday(now), "2026-10-22");
    });

    it("accepts today and exactly 18 years ago", () => {
      assert.equal(validateBirthDate("2026-10-22", now), "2026-10-22");
      assert.equal(validateBirthDate("2008-10-22", now), "2008-10-22");
    });

    it("rejects tomorrow, more than 18 years, bad formats and impossible dates", () => {
      for (const bad of ["2026-10-23", "2008-10-21", "2024-3-15", "15/03/2024", "2024-02-30", "", undefined]) {
        failsOn("birthDate", () => validateBirthDate(bad, now));
      }
    });
  });

  describe("child", () => {
    const valid = { name: "يوسف", birthDate: "2024-03-15", sex: "male" };

    it("accepts required fields only", () => {
      assert.deepEqual(validateChild(valid, now), valid);
    });

    it("accepts a child over 4 years (FR-020)", () => {
      assert.equal(validateChild({ ...valid, birthDate: "2019-01-01" }, now).birthDate, "2019-01-01");
    });

    it("name: required, 2–60 chars", () => {
      failsOn("name", () => validateChild({ ...valid, name: "ي" }, now));
      failsOn("name", () => validateChild({ ...valid, name: "ي".repeat(61) }, now));
    });

    it("sex: male | female", () => {
      failsOn("sex", () => validateChild({ ...valid, sex: "x" }, now));
    });

    it("birthWeightKg: 0.3–7.0", () => {
      assert.equal(validateChild({ ...valid, birthWeightKg: 3.2 }, now).birthWeightKg, 3.2);
      failsOn("birthWeightKg", () => validateChild({ ...valid, birthWeightKg: 0.2 }, now));
      failsOn("birthWeightKg", () => validateChild({ ...valid, birthWeightKg: 7.1 }, now));
      failsOn("birthWeightKg", () => validateChild({ ...valid, birthWeightKg: "3" }, now));
    });

    it("allergies: ≤ 500 chars", () => {
      assert.equal(validateChild({ ...valid, allergies: "بنسلين" }, now).allergies, "بنسلين");
      failsOn("allergies", () => validateChild({ ...valid, allergies: "ا".repeat(501) }, now));
    });
  });
});
