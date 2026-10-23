import { strict as assert } from "node:assert";
import { adminDb, callFunction, clearEmulators, seedGuardian, seedSettings, signInAsPhoneUser, type PhoneSession } from "../helpers/env";

const scopes = ["privacy_policy", "terms", "child_data"];

describe("acceptPolicy", () => {
  let user: PhoneSession;

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings({ policy: { currentVersion: 2 } });
    user = await signInAsPhoneUser("+201000000099");
  });

  it("records a new consent and updates consentVersion (FR-017)", async () => {
    await seedGuardian(user.uid, { phone: user.phone, consentVersion: 1 });
    const res = await callFunction("acceptPolicy", { policyVersion: 2, scopes }, user);
    assert.deepEqual(res, { result: {} });

    assert.equal((await adminDb().doc(`guardians/${user.uid}`).get()).get("consentVersion"), 2);
    const consents = await adminDb().collection(`guardians/${user.uid}/consents`).get();
    assert.equal(consents.size, 1);
    assert.equal(consents.docs[0].get("policyVersion"), 2);
    const audit = await adminDb().collection("auditLog").where("action", "==", "consent.accepted").get();
    assert.equal(audit.size, 1);
  });

  it("refuses a version that is not current", async () => {
    await seedGuardian(user.uid, { phone: user.phone, consentVersion: 1 });
    const res = await callFunction("acceptPolicy", { policyVersion: 1, scopes }, user);
    assert.equal(res.error?.status, "FAILED_PRECONDITION");
  });

  it("refuses when the guardian is not registered", async () => {
    const res = await callFunction("acceptPolicy", { policyVersion: 2, scopes }, user);
    assert.equal(res.error?.status, "NOT_FOUND");
  });
});
