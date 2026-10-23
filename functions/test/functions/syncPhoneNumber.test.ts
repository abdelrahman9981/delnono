import { strict as assert } from "node:assert";
import { getAuth } from "firebase-admin/auth";
import { getApps } from "firebase-admin/app";
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

const OLD = "+201000000099";
const NEW = "+201111111111";

describe("syncPhoneNumber", () => {
  let user: PhoneSession;

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    user = await signInAsPhoneUser(OLD);
    await seedGuardian(user.uid, { phone: OLD });
    await seedChild("mine", { guardianUid: user.uid, guardianPhone: OLD });
    await seedChild("other", { guardianUid: "someone", guardianPhone: "+201000000077" });
  });

  const changeAuthNumber = () =>
    getAuth(getApps().find((a) => a.name === "test")).updateUser(user.uid, { phoneNumber: NEW });

  it("copies the new number to the guardian and linked children (FR-025, FR-026)", async () => {
    await changeAuthNumber();
    const res = await callFunction<{ phone: string }>("syncPhoneNumber", {}, user);
    assert.equal(res.result?.phone, NEW);
    assert.equal((await adminDb().doc(`guardians/${user.uid}`).get()).get("phone"), NEW);
    assert.equal((await adminDb().doc("children/mine").get()).get("guardianPhone"), NEW);
    assert.equal((await adminDb().doc("children/mine").get()).get("guardianUid"), user.uid);
    assert.equal((await adminDb().doc("children/other").get()).get("guardianPhone"), "+201000000077");

    const audit = await adminDb().collection("auditLog").where("action", "==", "phone.changed").get();
    assert.equal(audit.size, 1);
    assert.deepEqual(audit.docs[0].get("details"), { from: OLD, to: NEW });
  });

  it("marks clinic children on the new number as pending", async () => {
    await seedChild("clinic", { guardianPhone: NEW, guardianUid: null });
    await changeAuthNumber();
    await callFunction("syncPhoneNumber", {}, user);
    assert.equal((await adminDb().doc(`guardians/${user.uid}`).get()).get("clinicChildrenPending"), true);
  });

  it("does nothing when the number has not changed", async () => {
    await callFunction("syncPhoneNumber", {}, user);
    const audit = await adminDb().collection("auditLog").get();
    assert.equal(audit.size, 0);
  });

  it("requires a registered guardian", async () => {
    const other = await signInAsPhoneUser("+201000000088");
    const res = await callFunction("syncPhoneNumber", {}, other);
    assert.equal(res.error?.status, "NOT_FOUND");
  });

  it("requires sign-in", async () => {
    const res = await callFunction("syncPhoneNumber", {});
    assert.equal(res.error?.status, "UNAUTHENTICATED");
  });
});
