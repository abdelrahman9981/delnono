import { strict as assert } from "node:assert";
import {
  adminDb,
  callFunction,
  clearEmulators,
  DEFAULT_POLICY_VERSION,
  seedChild,
  seedSettings,
  signInAsPhoneUser,
  type PhoneSession,
} from "../helpers/env";

const consent = { policyVersion: DEFAULT_POLICY_VERSION, scopes: ["privacy_policy", "terms", "child_data"] };
const valid = { fullName: "سارة محمود", relation: "mother", email: "sara@example.com", consent };

describe("completeRegistration", () => {
  let user: PhoneSession;

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    user = await signInAsPhoneUser("+201000000099");
  });

  async function audits() {
    const snap = await adminDb().collection("auditLog").where("actorUid", "==", user.uid).get();
    return snap.docs.map((d) => d.get("action")).sort();
  }

  it("writes guardian, one consent and two audit entries", async () => {
    const res = await callFunction<{ hasClinicChildren: boolean }>("completeRegistration", valid, user);
    assert.deepEqual(res, { result: { hasClinicChildren: false } });

    const g = (await adminDb().doc(`guardians/${user.uid}`).get()).data()!;
    assert.equal(g.phone, "+201000000099");
    assert.equal(g.fullName, "سارة محمود");
    assert.equal(g.relation, "mother");
    assert.equal(g.email, "sara@example.com");
    assert.equal(g.consentVersion, DEFAULT_POLICY_VERSION);
    assert.equal(g.clinicChildrenPending, false);
    assert.ok(g.lastActiveAt && g.createdAt);

    const consents = await adminDb().collection(`guardians/${user.uid}/consents`).get();
    assert.equal(consents.size, 1);
    assert.equal(consents.docs[0].get("policyVersion"), DEFAULT_POLICY_VERSION);
    assert.deepEqual(consents.docs[0].get("scopes"), ["privacy_policy", "terms", "child_data"]);
    assert.ok(consents.docs[0].get("acceptedAt"));

    assert.deepEqual(await audits(), ["account.created", "consent.accepted"]);
  });

  it("refuses a second registration", async () => {
    await callFunction("completeRegistration", valid, user);
    const res = await callFunction("completeRegistration", valid, user);
    assert.equal(res.error?.status, "ALREADY_EXISTS");
  });

  it("refuses an outdated policy version or a missing scope, storing nothing (FR-015)", async () => {
    await seedSettings({ policy: { currentVersion: 2 } });
    let res = await callFunction("completeRegistration", valid, user);
    assert.equal(res.error?.status, "FAILED_PRECONDITION");

    await seedSettings();
    res = await callFunction("completeRegistration", { ...valid, consent: { ...consent, scopes: ["privacy_policy", "terms"] } }, user);
    assert.equal(res.error?.status, "FAILED_PRECONDITION");

    assert.equal((await adminDb().doc(`guardians/${user.uid}`).get()).exists, false);
    assert.deepEqual(await audits(), []);
  });

  for (const [field, bad] of [
    ["fullName", { fullName: "س" }],
    ["relation", { relation: "aunt" }],
    ["email", { email: "nope" }],
  ] as const) {
    it(`invalid-argument for ${field}`, async () => {
      const res = await callFunction("completeRegistration", { ...valid, ...bad }, user);
      assert.equal(res.error?.status, "INVALID_ARGUMENT");
      assert.equal(res.error?.details?.field, field);
    });
  }

  it("requires a signed-in phone user", async () => {
    const res = await callFunction("completeRegistration", valid);
    assert.equal(res.error?.status, "UNAUTHENTICATED");
  });

  it("reports unlinked children on the number, from the clinic or a deleted account", async () => {
    await seedChild("clinic-1", { guardianPhone: user.phone, registeredBy: "clinic" });
    const res = await callFunction<{ hasClinicChildren: boolean }>("completeRegistration", valid, user);
    assert.equal(res.result?.hasClinicChildren, true);
    assert.equal((await adminDb().doc(`guardians/${user.uid}`).get()).get("clinicChildrenPending"), true);
  });

  it("counts a child left unlinked by a deleted account (registeredBy guardian)", async () => {
    await seedChild("old-1", { guardianPhone: user.phone, registeredBy: "guardian", guardianUid: null });
    const res = await callFunction<{ hasClinicChildren: boolean }>("completeRegistration", valid, user);
    assert.equal(res.result?.hasClinicChildren, true);
  });

  it("ignores linked children and other numbers", async () => {
    await seedChild("other", { guardianPhone: "+201000000077" });
    await seedChild("linked", { guardianPhone: user.phone, guardianUid: "someone" });
    const res = await callFunction<{ hasClinicChildren: boolean }>("completeRegistration", valid, user);
    assert.equal(res.result?.hasClinicChildren, false);
  });

  it("does not mark children pending while linking is locked", async () => {
    await seedChild("clinic-1", { guardianPhone: user.phone });
    await adminDb().doc(`linkAttempts/${user.phone}`).set({ failedCount: 3, lockedAt: new Date() });
    await callFunction("completeRegistration", valid, user);
    assert.equal((await adminDb().doc(`guardians/${user.uid}`).get()).get("clinicChildrenPending"), false);
  });
});
