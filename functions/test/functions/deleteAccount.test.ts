import { strict as assert } from "node:assert";
import { getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import {
  adminDb,
  callFunction,
  clearEmulators,
  seedChild,
  seedGuardian,
  seedSettings,
  signInAsPhoneUser,
  type PhoneSession,
} from "../helpers/env";

const auth = () => getAuth(getApps().find((a) => a.name === "test"));

async function authUserExists(uid: string) {
  try {
    await auth().getUser(uid);
    return true;
  } catch {
    return false;
  }
}

describe("deleteAccount", () => {
  let user: PhoneSession;

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    user = await signInAsPhoneUser("+201000000099");
    await seedGuardian(user.uid, { phone: user.phone });
    await adminDb().doc(`guardians/${user.uid}/consents/c1`).set({ policyVersion: 1, scopes: ["privacy_policy"] });
    await seedChild("mine", { guardianUid: user.uid, guardianPhone: user.phone });
    await seedChild("other", { guardianUid: "someone", guardianPhone: "+201000000077" });
  });

  it("removes the account and keeps the clinic's records (FR-027 to FR-030)", async () => {
    const res = await callFunction("deleteAccount", { confirm: true }, user);
    assert.deepEqual(res, { result: {} });

    assert.equal((await adminDb().doc(`guardians/${user.uid}`).get()).exists, false);
    assert.equal((await adminDb().collection(`guardians/${user.uid}/consents`).get()).size, 0);
    const archived = await adminDb().collection(`deletedGuardians/${user.uid}/consents`).get();
    assert.equal(archived.size, 1);
    assert.equal(archived.docs[0].get("policyVersion"), 1);

    const child = (await adminDb().doc("children/mine").get()).data()!;
    assert.equal(child.guardianUid, null);
    assert.equal(child.guardianPhone, user.phone);
    assert.equal((await adminDb().doc("children/other").get()).get("guardianUid"), "someone");

    const audit = await adminDb().collection("auditLog").where("action", "==", "account.deleted").get();
    assert.equal(audit.size, 1);
    assert.deepEqual(audit.docs[0].get("childIds"), ["mine"]);

    assert.equal(await authUserExists(user.uid), false);
  });

  it("a retry after the Firestore step finishes removing the Auth user, auditing once", async () => {
    await callFunction("deleteAccount", { confirm: true }, user);
    // Simulate a failure after the Firestore commit: the Auth user is still there.
    await auth().createUser({ uid: user.uid, phoneNumber: user.phone });
    user = await signInAsPhoneUser(user.phone, user.uid);

    const res = await callFunction("deleteAccount", { confirm: true }, user);
    assert.deepEqual(res, { result: {} });
    assert.equal(await authUserExists(user.uid), false);
    const audit = await adminDb().collection("auditLog").where("action", "==", "account.deleted").get();
    assert.equal(audit.size, 1);
  });

  it("requires an explicit confirm", async () => {
    const res = await callFunction("deleteAccount", {}, user);
    assert.equal(res.error?.status, "INVALID_ARGUMENT");
    assert.equal((await adminDb().doc(`guardians/${user.uid}`).get()).exists, true);
  });

  it("requires sign-in", async () => {
    const res = await callFunction("deleteAccount", { confirm: true });
    assert.equal(res.error?.status, "UNAUTHENTICATED");
  });
});
