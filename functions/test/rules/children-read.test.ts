import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { collection, deleteDoc, doc, getDoc, getDocs, query, setDoc, where } from "firebase/firestore";
import { clearEmulators, rulesEnv, seedChild, seedGuardian, seedSettings } from "../helpers/env";

// contracts/firestore-access.md: children/{id} read, list, create and delete.

describe("rules: children (read, create, delete)", () => {
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
    await seedChild("mine", { guardianUid: "u1", guardianPhone: "+201000000099" });
    await seedChild("theirs", { guardianUid: "u2", guardianPhone: "+201000000088" });
    await seedChild("clinic-unlinked", { guardianUid: null, guardianPhone: "+201000000099" });
  });

  const as = (uid: string) => env.authenticatedContext(uid).firestore();

  it("a guardian reads their linked child", async () => {
    await assertSucceeds(getDoc(doc(as("u1"), "children/mine")));
  });

  it("a guardian lists their linked children with the guardianUid filter", async () => {
    const snap = await assertSucceeds(getDocs(query(collection(as("u1"), "children"), where("guardianUid", "==", "u1"))));
    if (snap.size !== 1) throw new Error(`expected 1 child, got ${snap.size}`);
  });

  it("listing without the filter is denied", async () => {
    await assertFails(getDocs(collection(as("u1"), "children")));
  });

  it("another guardian's child is denied", async () => {
    await assertFails(getDoc(doc(as("u1"), "children/theirs")));
  });

  it("an unlinked clinic child on the same phone is denied until linked", async () => {
    await assertFails(getDoc(doc(as("u1"), "children/clinic-unlinked")));
  });

  it("a guardian whose consent is outdated is denied (FR-017)", async () => {
    await seedSettings({ policy: { currentVersion: 2 } });
    await assertFails(getDoc(doc(as("u1"), "children/mine")));
  });

  it("a signed-in user with no guardian doc is denied", async () => {
    await assertFails(getDoc(doc(as("u9"), "children/mine")));
  });

  it("anonymous is denied", async () => {
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), "children/mine")));
  });

  it("creating or deleting a child from the app is denied", async () => {
    await assertFails(setDoc(doc(as("u1"), "children/new"), { name: "يوسف", guardianUid: "u1" }));
    await assertFails(deleteDoc(doc(as("u1"), "children/mine")));
  });
});
