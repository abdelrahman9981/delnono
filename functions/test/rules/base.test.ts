import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, collection, getDocs, deleteDoc } from "firebase/firestore";
import { clearEmulators, rulesEnv, seedSettings } from "../helpers/env";

// Rows of contracts/firestore-access.md covered here: settings, server-only collections, default deny.

describe("rules: base", () => {
  let env: RulesTestEnvironment;

  before(async () => {
    env = await rulesEnv();
  });

  after(async () => {
    await env.cleanup();
  });

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
  });

  const anon = () => env.unauthenticatedContext().firestore();
  const user = () => env.authenticatedContext("u1", { phone_number: "+201000000099" }).firestore();

  describe("settings/{doc}", () => {
    for (const id of ["auth", "policy", "clinic"]) {
      it(`anyone can read settings/${id}`, async () => {
        await assertSucceeds(getDoc(doc(anon(), `settings/${id}`)));
        await assertSucceeds(getDoc(doc(user(), `settings/${id}`)));
      });
    }

    it("nobody can write settings", async () => {
      await assertFails(setDoc(doc(anon(), "settings/auth"), { maxCodeAttempts: 99 }));
      await assertFails(setDoc(doc(user(), "settings/auth"), { maxCodeAttempts: 99 }));
      await assertFails(setDoc(doc(user(), "settings/policy"), { currentVersion: 0 }));
      await assertFails(deleteDoc(doc(user(), "settings/clinic")));
    });
  });

  describe("server-only collections", () => {
    const paths = [
      "clinicGuardians/+201000000099",
      "linkAttempts/+201000000099",
      "reverifyAttempts/u1",
      "smsCounters/+201000000099_20261022",
      "auditLog/a1",
      "deletedGuardians/u1",
      "deletedGuardians/u1/consents/c1",
    ];

    for (const path of paths) {
      it(`${path} is denied to every client`, async () => {
        for (const db of [anon(), user()]) {
          await assertFails(getDoc(doc(db, path)));
          await assertFails(setDoc(doc(db, path), { x: 1 }));
          await assertFails(deleteDoc(doc(db, path)));
        }
      });
    }

    it("listing the audit log is denied", async () => {
      await assertFails(getDocs(collection(user(), "auditLog")));
    });
  });

  describe("default deny", () => {
    it("unlisted collections are denied", async () => {
      await assertFails(getDoc(doc(user(), "anything/x")));
      await assertFails(setDoc(doc(user(), "anything/x"), { x: 1 }));
      await assertFails(getDoc(doc(anon(), "anything/x")));
    });
  });
});
