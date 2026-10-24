import { strict as assert } from "node:assert";
import { priceSelection, type Vaccine } from "../../src/lib/booking/pricing";

// Shared cases with test/features/booking/price_preview_test.dart.
const vaccines = new Map<string, Vaccine>([
  ["v1", { id: "v1", name: "أ", price: 150, showPrice: true, active: true }],
  ["v2", { id: "v2", name: "ب", price: 200, showPrice: true, active: true }],
  ["v3", { id: "v3", name: "ج", price: 450, showPrice: false, active: true }],
]);
const base = { visitPrice: 300, vaccines, packageId: null };

describe("booking pricing", () => {
  it("one visit price for siblings (FR-013)", () => {
    const p = priceSelection({ ...base, visitType: "visit", children: [{ childId: "a", vaccines: [] }, { childId: "b", vaccines: [] }] });
    assert.deepEqual(p.visit, { amount: 300, covered: false });
    assert.equal(p.total, 300);
  });

  it("vaccines per child are added (FR-014)", () => {
    const p = priceSelection({ ...base, visitType: "visit", children: [{ childId: "a", vaccines: ["v1"] }, { childId: "b", vaccines: ["v1", "v2"] }] });
    assert.equal(p.vaccines.length, 3);
    assert.equal(p.total, 300 + 150 + 150 + 200);
  });

  it("vaccine only has no visit price (D-31)", () => {
    const p = priceSelection({ ...base, visitType: "vaccine_only", children: [{ childId: "a", vaccines: ["v2"] }] });
    assert.equal(p.visit, null);
    assert.equal(p.total, 200);
  });

  it("hidden prices are kept for the clinic but left out of the shown total", () => {
    const p = priceSelection({ ...base, visitType: "visit", children: [{ childId: "a", vaccines: ["v3"] }] });
    assert.deepEqual(p.vaccines[0], { childId: "a", vaccineId: "v3", name: "ج", amount: 450, shown: false });
    assert.equal(p.total, 300);
    assert.equal(p.hasHiddenPrices, true);
  });

  it("a package covers the visit, not vaccines (FR-016)", () => {
    const p = priceSelection({ ...base, packageId: "pk", visitType: "visit", children: [{ childId: "a", vaccines: ["v1"] }] });
    assert.deepEqual(p.visit, { amount: 0, covered: true });
    assert.equal(p.total, 150);
    assert.equal(p.packageId, "pk");
  });

  it("a change keeps fixed amounts and prices only new lines at today's prices (FR-023)", () => {
    const before = priceSelection({ ...base, visitType: "visit", children: [{ childId: "a", vaccines: ["v1"] }] });
    const raised = new Map(vaccines);
    raised.set("v1", { ...vaccines.get("v1")!, price: 999 });
    const after = priceSelection({
      visitPrice: 400,
      vaccines: raised,
      packageId: null,
      previous: before,
      visitType: "visit",
      children: [{ childId: "a", vaccines: ["v1", "v2"] }],
    });
    assert.deepEqual(after.visit, { amount: 300, covered: false }, "visit keeps its fixed price");
    assert.equal(after.vaccines.find((l) => l.vaccineId === "v1")!.amount, 150, "kept vaccine keeps its price");
    assert.equal(after.vaccines.find((l) => l.vaccineId === "v2")!.amount, 200, "added vaccine at today's price");
  });

  it("a visit added by a change (from vaccine only) uses today's price", () => {
    const before = priceSelection({ ...base, visitType: "vaccine_only", children: [{ childId: "a", vaccines: ["v1"] }] });
    const after = priceSelection({ ...base, visitPrice: 350, previous: before, visitType: "visit", children: [{ childId: "a", vaccines: ["v1"] }] });
    assert.deepEqual(after.visit, { amount: 350, covered: false });
  });
});
