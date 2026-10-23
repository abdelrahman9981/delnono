import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { deleteDoc, doc, getDoc, getDocs, collection, serverTimestamp, setDoc, updateDoc } from "firebase/firestore";
import { clearEmulators, rulesEnv, seedGuardian, seedSettings } from "../helpers/env";

// contracts/firestore-access.md: guardians/{uid} and guardians/{uid}/consents/{id}.

describe("rules: guardians", () => {
  let env: RulesTestEnvironment;

  before(async () => {
    env = await rulesEnv();
  });
  after(async () => env.cleanup());

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedGuardian("u1", { phone: "+201000000099", email: "a@b.co" });
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "guardians/u1/consents/c1"), { policyVersion: 1 });
    });
  });

  const as = (uid: string) => env.authenticatedContext(uid, { phone_number: "+201000000099" }).firestore();
  const anon = () => env.unauthenticatedContext().firestore();
  const edit = (data: object) => updateDoc(doc(as("u1"), "guardians/u1"), { ...data, updatedAt: serverTimestamp() });

  describe("read", () => {
    it("the owner can read their guardian doc", async () => {
      await assertSucceeds(getDoc(doc(as("u1"), "guardians/u1")));
    });

    it("another signed-in user and anonymous cannot", async () => {
      await assertFails(getDoc(doc(as("u2"), "guardians/u1")));
      await assertFails(getDoc(doc(anon(), "guardians/u1")));
    });

    it("listing guardians is denied", async () => {
      await assertFails(getDocs(collection(as("u1"), "guardians")));
    });
  });

  describe("create and delete (functions only)", () => {
    it("the owner cannot create or delete their doc", async () => {
      await assertFails(setDoc(doc(as("u3"), "guardians/u3"), { fullName: "سارة", relation: "mother" }));
      await assertFails(deleteDoc(doc(as("u1"), "guardians/u1")));
    });
  });

  describe("update", () => {
    it("the owner can change name, relation and email", async () => {
      await assertSucceeds(edit({ fullName: "سارة أحمد", relation: "other", email: "s@x.eg" }));
    });

    it("email can be removed", async () => {
      await assertSucceeds(edit({ email: null }));
    });

    for (const field of ["phone", "consentVersion", "clinicChildrenPending", "lastActiveAt"]) {
      it(`changing ${field} is denied`, async () => {
        const value = field === "phone" ? "+201111111111" : field === "consentVersion" ? 99 : field === "lastActiveAt" ? new Date() : true;
        await assertFails(edit({ [field]: value }));
      });
    }

    it("invalid values are denied", async () => {
      await assertFails(edit({ fullName: "س" }));
      await assertFails(edit({ fullName: "س".repeat(81) }));
      await assertFails(edit({ relation: "aunt" }));
      await assertFails(edit({ email: "not-an-email" }));
    });

    it("updatedAt must be the server time", async () => {
      await assertFails(updateDoc(doc(as("u1"), "guardians/u1"), { fullName: "سارة", updatedAt: new Date(2020, 1, 1) }));
    });

    it("another user cannot edit", async () => {
      await assertFails(updateDoc(doc(as("u2"), "guardians/u1"), { fullName: "سارة", updatedAt: serverTimestamp() }));
    });
  });

  describe("consents", () => {
    it("the owner can read their consents", async () => {
      await assertSucceeds(getDoc(doc(as("u1"), "guardians/u1/consents/c1")));
      await assertSucceeds(getDocs(collection(as("u1"), "guardians/u1/consents")));
    });

    it("another user cannot read them", async () => {
      await assertFails(getDoc(doc(as("u2"), "guardians/u1/consents/c1")));
    });

    it("nobody can write consents from the app", async () => {
      await assertFails(setDoc(doc(as("u1"), "guardians/u1/consents/c2"), { policyVersion: 1 }));
      await assertFails(updateDoc(doc(as("u1"), "guardians/u1/consents/c1"), { policyVersion: 2 }));
      await assertFails(deleteDoc(doc(as("u1"), "guardians/u1/consents/c1")));
    });
  });
});
