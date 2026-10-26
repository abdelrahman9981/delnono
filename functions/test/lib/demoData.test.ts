import { strict as assert } from "node:assert";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { BANDS, DANGER_SIGNS, DANGER_SIGNS_SOURCES, FAMILIES, HOLIDAYS, SCHEDULE, TIPS, VACCINES, medianAt } from "../../scripts/demo_data";

/** Every researched medical text the seed writes. */
const texts = [
  ...VACCINES.flatMap((v) => [v.name, v.note ?? ""]),
  ...SCHEDULE.map((e) => e.ageLabel),
  ...BANDS.flatMap((b) => [b.title, ...b.items, ...b.dangerSigns]),
  ...DANGER_SIGNS,
  ...TIPS.flatMap((t) => [t.title, t.body]),
];

describe("demo data safety (docs/launch-checklist.md)", () => {
  it("every medical item has a source URL", () => {
    for (const item of [...VACCINES, ...SCHEDULE, ...BANDS, ...TIPS]) {
      assert.match(item.sourceUrl, /^https:\/\//, JSON.stringify(item).slice(0, 80));
    }
    assert.ok(DANGER_SIGNS_SOURCES.length > 0 && DANGER_SIGNS_SOURCES.every((u) => u.startsWith("https://")));
  });

  it("the seed writes every medical item as proposed (never approved)", () => {
    const seed = readFileSync(join(__dirname, "../../scripts/seed.ts"), "utf8");
    for (const where of ["vaccines/${id}", "vaccineSchedule/${id}", "settings/followUp", "followUp/b${fromMonths}", "settings/vaccines"]) {
      const at = seed.indexOf(where);
      assert.ok(at > 0, where);
      assert.match(seed.slice(at, at + 600), /reviewStatus: PROPOSED/, where);
    }
    assert.match(seed.slice(seed.indexOf("TIPS.forEach")), /reviewStatus: PROPOSED/);
    assert.doesNotMatch(seed, /reviewStatus: "approved"/);
  });

  it("no medicine names with doses, no diagnoses, no normal/abnormal judgments", () => {
    const doses = /\d+\s*(mg|ml|مجم|ملجم|مللي|ملي|سم مكعب)\b/i;
    const medicines = /(باراسيتامول|بنادول|سيتال|ايبوبروفين|إيبوبروفين|بروفين|أموكسيسيلين|اموكسيسيلين|مضاد حيوي|paracetamol|ibuprofen|acetaminophen)/i;
    // Whole words: «الرضاعة الطبيعية» (breastfeeding) is not a judgment, «طبيعي» (normal) is.
    const judgments = /(^|[\s،.])(طبيعي|طبيعية|غير طبيعي|مطمئن|مقلق|سليم)([\s،.]|$)|على الطريق الصحيح|\b(normal|abnormal|on track)\b/i;
    const diagnoses = /(تشخيص|عنده التهاب|مصاب ب)/;
    for (const t of texts) {
      assert.doesNotMatch(t, doses, t);
      assert.doesNotMatch(t, medicines, t);
      assert.doesNotMatch(t, judgments, t);
      assert.doesNotMatch(t, diagnoses, t);
    }
  });

  it("demo families are fictional test numbers that leave the seeded and test numbers alone", () => {
    const reserved = new Set(["+201000000001", "+201000000003", "+201000000099"]);
    const phones = FAMILIES.map((f) => f.phone);
    assert.equal(new Set(phones).size, phones.length);
    for (const p of phones) {
      assert.match(p, /^\+2010000002\d\d$/);
      assert.ok(!reserved.has(p));
    }
    assert.ok(FAMILIES.length >= 10);
    assert.ok(FAMILIES.some((f) => f.children.length > 1), "siblings");
  });

  it("holidays are Nov 2026 – Dec 2027 dates; medians grow with age", () => {
    for (const d of HOLIDAYS) assert.ok(d >= "2026-11-01" && d <= "2027-12-31", d);
    for (const sex of ["male", "female"] as const) {
      assert.ok(medianAt(sex, 6).weightKg > medianAt(sex, 2).weightKg);
      assert.ok(Math.abs(medianAt(sex, 12).lengthCm - (sex === "male" ? 75.7 : 74.0)) < 0.01);
    }
  });
});
