import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { collection, doc, getDoc, getDocs, serverTimestamp, setDoc, updateDoc } from "firebase/firestore";
import { clearEmulators, rulesEnv, seedChild, seedGuardian, seedSettings } from "../helpers/env";

// contracts/firestore-access.md: children/{id} update and children/{id}/history/{h}.

describe("rules: children (update, history)", () => {
  let env: RulesTestEnvironment;

  before(async () => {
    env = await rulesEnv();
  });
  after(async () => env.cleanup());

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedGuardian("u1", { phone: "+201000000099" });
    await seedGuardian("u2", { phone: "+201000000088" });
    await seedChild("mine", { guardianUid: "u1", guardianPhone: "+201000000099", allergies: "بنسلين" });
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "children/mine/history/h1"), { changedBy: "u1" });
    });
  });

  const as = (uid: string) => env.authenticatedContext(uid).firestore();
  const edit = (uid: string, data: object) =>
    updateDoc(doc(as(uid), "children/mine"), { ...data, updatedBy: uid, updatedAt: serverTimestamp() });

  it("the linked guardian can edit name and allergies", async () => {
    await assertSucceeds(edit("u1", { name: "يوسف أحمد" }));
    await assertSucceeds(edit("u1", { allergies: "لا يوجد" }));
    await assertSucceeds(edit("u1", { allergies: null }));
  });

  for (const [field, value] of [
    ["birthDate", "2020-01-01"],
    ["sex", "female"],
    ["guardianUid", "u2"],
    ["guardianPhone", "+201000000088"],
    ["birthWeightKg", 4],
    ["nameKey", "x"],
  ] as const) {
    it(`changing ${field} is denied (FR-024)`, async () => {
      await assertFails(edit("u1", { [field]: value }));
    });
  }

  it("invalid values are denied", async () => {
    await assertFails(edit("u1", { name: "ي" }));
    await assertFails(edit("u1", { name: "ي".repeat(61) }));
    await assertFails(edit("u1", { allergies: "ا".repeat(501) }));
  });

  it("updatedBy must be the caller and updatedAt the server time", async () => {
    await assertFails(updateDoc(doc(as("u1"), "children/mine"), { name: "يوسف", updatedBy: "u2", updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(doc(as("u1"), "children/mine"), { name: "يوسف", updatedBy: "u1", updatedAt: new Date(2020, 0, 1) }));
    await assertFails(updateDoc(doc(as("u1"), "children/mine"), { name: "يوسف" }));
  });

  it("another guardian cannot edit", async () => {
    await assertFails(edit("u2", { name: "يوسف" }));
  });

  it("a guardian with outdated consent cannot edit", async () => {
    await seedSettings({ policy: { currentVersion: 2 } });
    await assertFails(edit("u1", { name: "يوسف" }));
  });

  it("history is readable by the linked guardian only", async () => {
    await assertSucceeds(getDoc(doc(as("u1"), "children/mine/history/h1")));
    await assertSucceeds(getDocs(collection(as("u1"), "children/mine/history")));
    await assertFails(getDoc(doc(as("u2"), "children/mine/history/h1")));
  });

  it("history is never writable from the app", async () => {
    await assertFails(setDoc(doc(as("u1"), "children/mine/history/h2"), { changedBy: "u1" }));
    await assertFails(updateDoc(doc(as("u1"), "children/mine/history/h1"), { changedBy: "u2" }));
  });
});
