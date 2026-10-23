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

const valid = { name: "يوسف", birthDate: "2024-03-15", sex: "male" };

describe("createChild", () => {
  let user: PhoneSession;

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    user = await signInAsPhoneUser("+201000000099");
    await seedGuardian(user.uid, { phone: user.phone });
  });

  it("creates a guardian-registered child linked to the caller", async () => {
    const res = await callFunction<{ childId: string }>(
      "createChild",
      { ...valid, birthWeightKg: 3.1, allergies: "بنسلين" },
      user,
    );
    const id = res.result!.childId;
    const c = (await adminDb().doc(`children/${id}`).get()).data()!;
    assert.equal(c.name, "يوسف");
    assert.equal(c.nameKey, "يوسف");
    assert.equal(c.birthDate, "2024-03-15");
    assert.equal(c.sex, "male");
    assert.equal(c.birthWeightKg, 3.1);
    assert.equal(c.allergies, "بنسلين");
    assert.equal(c.guardianUid, user.uid);
    assert.equal(c.guardianPhone, user.phone);
    assert.equal(c.registeredBy, "guardian");
  });

  it("refuses a duplicate already in the account (existingLinked true)", async () => {
    await callFunction("createChild", valid, user);
    const res = await callFunction("createChild", { ...valid, name: " يُوسُف " }, user);
    assert.equal(res.error?.status, "ALREADY_EXISTS");
    assert.equal(res.error?.details?.existingLinked, true);
    assert.equal((await adminDb().collection("children").get()).size, 1);
  });

  it("refuses a duplicate of an unlinked clinic child (existingLinked false)", async () => {
    await seedChild("clinic-1", { name: "مريم", nameKey: "مريم", birthDate: "2022-07-02", guardianPhone: user.phone });
    const res = await callFunction("createChild", { name: "مريم", birthDate: "2022-07-02", sex: "female" }, user);
    assert.equal(res.error?.status, "ALREADY_EXISTS");
    assert.equal(res.error?.details?.existingLinked, false);
  });

  it("allows the same name with another birth date, and the same child on another number", async () => {
    await seedChild("other-number", { name: "يوسف", nameKey: "يوسف", birthDate: "2024-03-15", guardianPhone: "+201000000077" });
    assert.ok((await callFunction("createChild", valid, user)).result);
    assert.ok((await callFunction("createChild", { ...valid, birthDate: "2023-01-01" }, user)).result);
  });

  for (const [field, bad] of [
    ["name", { name: "ي" }],
    ["birthDate", { birthDate: "2999-01-01" }],
    ["sex", { sex: "x" }],
    ["birthWeightKg", { birthWeightKg: 9 }],
    ["allergies", { allergies: "ا".repeat(501) }],
  ] as const) {
    it(`invalid-argument for ${field}`, async () => {
      const res = await callFunction("createChild", { ...valid, ...bad }, user);
      assert.equal(res.error?.status, "INVALID_ARGUMENT");
      assert.equal(res.error?.details?.field, field);
    });
  }

  it("requires current consent", async () => {
    await seedSettings({ policy: { currentVersion: 2 } });
    const res = await callFunction("createChild", valid, user);
    assert.equal(res.error?.status, "FAILED_PRECONDITION");
  });

  it("requires a registered guardian", async () => {
    const other = await signInAsPhoneUser("+201000000088");
    const res = await callFunction("createChild", valid, other);
    assert.equal(res.error?.status, "FAILED_PRECONDITION");
  });
});
