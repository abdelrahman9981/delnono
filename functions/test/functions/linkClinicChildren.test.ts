import { strict as assert } from "node:assert";
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

describe("linkClinicChildren", () => {
  let user: PhoneSession;

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    user = await signInAsPhoneUser("+201000000001");
    await seedGuardian(user.uid, { phone: user.phone, clinicChildrenPending: true });
    await seedChild("youssef", { name: "يوسف", birthDate: "2024-03-15", guardianPhone: user.phone });
    await seedChild("mariam", { name: "مريم", birthDate: "2022-07-02", guardianPhone: user.phone });
    await seedChild("left-by-deleted", {
      name: "سلمى",
      birthDate: "2020-01-01",
      guardianPhone: user.phone,
      registeredBy: "guardian",
    });
    await seedChild("other-number", { name: "علي", birthDate: "2024-03-15", guardianPhone: "+201000000077" });
  });

  const guardian = async () => (await adminDb().doc(`guardians/${user.uid}`).get()).data()!;
  const actions = async () =>
    (await adminDb().collection("auditLog").get()).docs.map((d) => d.get("action") as string).sort();
  const link = (birthDate: string) => callFunction<{ linked: { childId: string; name: string }[] }>(
    "linkClinicChildren",
    { birthDate },
    user,
  );

  it("the birth date of any one child links every unlinked child on the number", async () => {
    await adminDb().doc(`linkAttempts/${user.phone}`).set({ failedCount: 1, lockedAt: null });
    const res = await link("2022-07-02");
    const names = res.result!.linked.map((c) => c.name).sort();
    assert.deepEqual(names, ["سلمى", "مريم", "يوسف"]);

    for (const id of ["youssef", "mariam", "left-by-deleted"]) {
      assert.equal((await adminDb().doc(`children/${id}`).get()).get("guardianUid"), user.uid, id);
    }
    assert.equal((await adminDb().doc("children/other-number").get()).get("guardianUid"), null);
    assert.equal((await guardian()).clinicChildrenPending, false);
    assert.equal((await adminDb().doc(`linkAttempts/${user.phone}`).get()).exists, false);
    assert.deepEqual(await actions(), ["children.linked"]);
  });

  it("a wrong date counts down, then locks at maxLinkAttempts (FR-021a)", async () => {
    let res = await link("2019-05-05");
    assert.equal(res.error?.status, "PERMISSION_DENIED");
    assert.equal(res.error?.details?.remaining, 2);

    res = await link("2019-05-05");
    assert.equal(res.error?.details?.remaining, 1);
    assert.equal((await guardian()).clinicChildrenPending, true);

    res = await link("2019-05-05");
    assert.equal(res.error?.status, "RESOURCE_EXHAUSTED");
    assert.equal((await guardian()).clinicChildrenPending, false);
    assert.ok((await adminDb().doc(`linkAttempts/${user.phone}`).get()).get("lockedAt"));
    assert.deepEqual(await actions(), [
      "children.link_failed",
      "children.link_failed",
      "children.link_failed",
      "children.link_locked",
    ]);

    // Locked: even the right date is refused, and nothing is linked.
    res = await link("2024-03-15");
    assert.equal(res.error?.status, "RESOURCE_EXHAUSTED");
    assert.equal((await adminDb().doc("children/youssef").get()).get("guardianUid"), null);
  });

  it("uses maxLinkAttempts from settings", async () => {
    await seedSettings({ auth: { maxLinkAttempts: 1 } });
    const res = await link("2019-05-05");
    assert.equal(res.error?.status, "RESOURCE_EXHAUSTED");
  });

  it("not-found when nothing is left to link, and clears the pending flag", async () => {
    await clearEmulators();
    await seedSettings();
    user = await signInAsPhoneUser("+201000000001");
    await seedGuardian(user.uid, { phone: user.phone, clinicChildrenPending: true });
    const res = await link("2024-03-15");
    assert.equal(res.error?.status, "NOT_FOUND");
    assert.equal((await guardian()).clinicChildrenPending, false);
  });

  it("requires current consent", async () => {
    await seedSettings({ policy: { currentVersion: 2 } });
    const res = await link("2024-03-15");
    assert.equal(res.error?.status, "FAILED_PRECONDITION");
  });

  it("rejects a malformed date without counting an attempt", async () => {
    const res = await link("15/03/2024");
    assert.equal(res.error?.status, "INVALID_ARGUMENT");
    assert.equal((await adminDb().doc(`linkAttempts/${user.phone}`).get()).exists, false);
  });
});
