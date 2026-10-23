import { strict as assert } from "node:assert";
import { Timestamp } from "firebase-admin/firestore";
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

const DAY = 24 * 60 * 60 * 1000;

describe("touchSession and reverifyGuardian (FR-010a, FR-010b)", () => {
  let user: PhoneSession;

  async function seed(daysAgo: number, withChild = true) {
    await clearEmulators();
    await seedSettings();
    user = await signInAsPhoneUser("+201000000099");
    await seedGuardian(user.uid, { phone: user.phone, lastActiveAt: new Date(Date.now() - daysAgo * DAY) });
    if (withChild) await seedChild("mine", { guardianUid: user.uid, guardianPhone: user.phone, birthDate: "2024-03-15" });
  }

  const lastActive = async () =>
    ((await adminDb().doc(`guardians/${user.uid}`).get()).get("lastActiveAt") as Timestamp).toMillis();
  const actions = async () => (await adminDb().collection("auditLog").get()).docs.map((d) => d.get("action")).sort();

  describe("touchSession", () => {
    it("active: no re-check, and lastActiveAt is refreshed when older than a day", async () => {
      await seed(10);
      const before = await lastActive();
      const res = await callFunction("touchSession", {}, user);
      assert.deepEqual(res, { result: { reverifyRequired: false } });
      assert.ok((await lastActive()) > before);
    });

    it("refreshes at most once a day", async () => {
      await seed(0.5);
      const before = await lastActive();
      await callFunction("touchSession", {}, user);
      assert.equal(await lastActive(), before);
    });

    it("inactive with linked children: re-check required and nothing changes", async () => {
      await seed(91);
      const before = await lastActive();
      const res = await callFunction("touchSession", {}, user);
      assert.deepEqual(res, { result: { reverifyRequired: true } });
      assert.equal(await lastActive(), before);
    });

    it("inactive without linked children: no re-check (nothing to protect)", async () => {
      await seed(200, false);
      const res = await callFunction("touchSession", {}, user);
      assert.deepEqual(res, { result: { reverifyRequired: false } });
    });

    it("no guardian doc yet: no re-check", async () => {
      await seed(10);
      const other = await signInAsPhoneUser("+201000000088");
      assert.deepEqual(await callFunction("touchSession", {}, other), { result: { reverifyRequired: false } });
    });
  });

  describe("reverifyGuardian", () => {
    it("the birth date of a linked child refreshes lastActiveAt and resets attempts", async () => {
      await seed(91);
      await adminDb().doc(`reverifyAttempts/${user.uid}`).set({ failedCount: 1, lockedAt: null });
      const res = await callFunction("reverifyGuardian", { birthDate: "2024-03-15" }, user);
      assert.deepEqual(res, { result: {} });
      assert.ok(Date.now() - (await lastActive()) < 60_000);
      assert.equal((await adminDb().doc(`reverifyAttempts/${user.uid}`).get()).exists, false);
      assert.deepEqual(await actions(), ["account.reverified"]);
      assert.deepEqual(await callFunction("touchSession", {}, user), { result: { reverifyRequired: false } });
    });

    it("wrong dates count down, then lock; even the right date is refused when locked", async () => {
      await seed(91);
      let res = await callFunction("reverifyGuardian", { birthDate: "2019-01-01" }, user);
      assert.equal(res.error?.status, "PERMISSION_DENIED");
      assert.equal(res.error?.details?.remaining, 2);
      res = await callFunction("reverifyGuardian", { birthDate: "2019-01-01" }, user);
      assert.equal(res.error?.details?.remaining, 1);
      res = await callFunction("reverifyGuardian", { birthDate: "2019-01-01" }, user);
      assert.equal(res.error?.status, "RESOURCE_EXHAUSTED");
      res = await callFunction("reverifyGuardian", { birthDate: "2024-03-15" }, user);
      assert.equal(res.error?.status, "RESOURCE_EXHAUSTED");
      assert.deepEqual(await actions(), [
        "account.reverify_failed",
        "account.reverify_failed",
        "account.reverify_failed",
        "account.reverify_locked",
      ]);
    });

    it("a clinic child on the same number that is not linked does not count", async () => {
      await seed(91, false);
      await seedChild("unlinked", { guardianUid: null, guardianPhone: user.phone, birthDate: "2024-03-15" });
      const res = await callFunction("reverifyGuardian", { birthDate: "2024-03-15" }, user);
      assert.equal(res.error?.status, "PERMISSION_DENIED");
    });
  });
});
