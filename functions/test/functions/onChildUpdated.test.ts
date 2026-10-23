import { strict as assert } from "node:assert";
import { adminDb, clearEmulators, seedChild, seedSettings } from "../helpers/env";

/** The trigger runs asynchronously in the Functions emulator; wait for its writes. */
async function waitFor<T>(read: () => Promise<T>, done: (v: T) => boolean, ms = 10000): Promise<T> {
  const end = Date.now() + ms;
  let v = await read();
  while (!done(v) && Date.now() < end) {
    await new Promise((r) => setTimeout(r, 250));
    v = await read();
  }
  return v;
}

const history = () => adminDb().collection("children/c1/history").get();
const audits = () => adminDb().collection("auditLog").where("action", "==", "child.allergies_changed").get();
const settleMs = () => new Promise((r) => setTimeout(r, 2500));

describe("onChildUpdated", () => {
  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedChild("c1", { name: "يوسف", nameKey: "يوسف", allergies: "بنسلين", guardianUid: "u1", guardianPhone: "+201000000099" });
  });

  it("an allergies change writes history and an audit entry (FR-023, FR-023a)", async () => {
    await adminDb().doc("children/c1").update({ allergies: "لا يوجد", updatedBy: "u1", updatedAt: new Date() });
    const h = await waitFor(history, (s) => s.size >= 1);
    assert.equal(h.size, 1);
    const entry = h.docs[0].data();
    assert.deepEqual(entry.changedFields, { allergies: { from: "بنسلين", to: "لا يوجد" } });
    assert.equal(entry.changedBy, "u1");
    assert.ok(entry.changedAt);

    const a = await waitFor(audits, (s) => s.size >= 1);
    assert.equal(a.size, 1);
    assert.deepEqual(a.docs[0].get("childIds"), ["c1"]);
  });

  it("a name change writes history, no audit, and refreshes nameKey", async () => {
    await adminDb().doc("children/c1").update({ name: "يُوسُف أحمد", updatedBy: "u1", updatedAt: new Date() });
    const h = await waitFor(history, (s) => s.size >= 1);
    assert.deepEqual(h.docs[0].get("changedFields"), { name: { from: "يوسف", to: "يُوسُف أحمد" } });
    const key = await waitFor(
      async () => (await adminDb().doc("children/c1").get()).get("nameKey"),
      (k) => k === "يوسف احمد",
    );
    assert.equal(key, "يوسف احمد");
    await settleMs();
    assert.equal((await audits()).size, 0);
    assert.equal((await history()).size, 1, "refreshing nameKey is not a new history entry");
  });

  it("bookkeeping-only updates write nothing", async () => {
    await adminDb().doc("children/c1").update({ updatedAt: new Date(), updatedBy: "u1", guardianUid: "u2" });
    await settleMs();
    assert.equal((await history()).size, 0);
    assert.equal((await audits()).size, 0);
  });
});
