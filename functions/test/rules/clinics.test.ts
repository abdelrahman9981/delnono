import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { collection, deleteDoc, doc, getDoc, getDocs, setDoc } from "firebase/firestore";
import { adminDb, clearEmulators, rulesEnv, seedGuardian, seedSettings } from "../helpers/env";

// contracts/firestore-access.md (004): clinics are public to read and never written from the app.

describe("rules: clinics (004)", () => {
  let env: RulesTestEnvironment;

  before(async () => {
    env = await rulesEnv();
  });
  after(async () => env.cleanup());

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedGuardian("u1");
    await adminDb().doc("clinics/clinic-1").set({ name: "[عيادة]", active: true, order: 0, visitPrice: 300 });
  });

  it("anyone reads and lists clinics (Home is public)", async () => {
    const anon = env.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(anon, "clinics/clinic-1")));
    await assertSucceeds(getDocs(collection(anon, "clinics")));
  });

  it("nobody writes clinics from the app", async () => {
    const db = env.authenticatedContext("u1").firestore();
    await assertFails(setDoc(doc(db, "clinics/clinic-1"), { visitPrice: 1 }));
    await assertFails(setDoc(doc(db, "clinics/new"), { name: "x" }));
    await assertFails(deleteDoc(doc(db, "clinics/clinic-1")));
  });
});
