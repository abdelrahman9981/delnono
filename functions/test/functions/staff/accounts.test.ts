import { strict as assert } from "node:assert";
import { getApps } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { adminDb, callFunction, clearEmulators, seedGuardian, seedSettings, signInAsPhoneUser } from "../../helpers/env";
import { seedBookingSettings } from "../../helpers/booking";
import { doctor, secretary1, signInAsStaff } from "../../helpers/staff";

describe("staff accounts (005 US1)", () => {
  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedBookingSettings();
  });

  it("the doctor creates a secretary with claims and a temporary password to change (FR-001)", async () => {
    const d = await doctor();
    const res = await callFunction<{ uid: string }>("manageStaff", {
      action: "create", name: "[منى]", email: "Mona@Demo.delnono", role: "secretary", clinicId: "clinic-1", tempPassword: "Temp-1234",
    }, d);
    assert.ok(res.result, JSON.stringify(res.error));
    const user = await getAuth(getApps().find((a) => a.name === "test")!).getUser(res.result.uid);
    assert.deepEqual(user.customClaims, { role: "secretary", clinicId: "clinic-1" });
    assert.equal(user.email, "mona@demo.delnono");
    const staff = await adminDb().doc(`staff/${res.result.uid}`).get();
    assert.equal(staff.get("mustChangePassword"), true);
    const audit = await adminDb().collection("auditLog").where("action", "==", "staff.created").get();
    assert.equal(audit.size, 1);
  });

  it("only the doctor manages staff (D-12)", async () => {
    const s = await secretary1();
    const res = await callFunction("manageStaff", { action: "create", name: "x", email: "x@y.z", role: "secretary", clinicId: "clinic-1", tempPassword: "Temp-1234" }, s);
    assert.equal(res.error?.status, "PERMISSION_DENIED");
  });

  it("a guardian and a disabled staff member are refused", async () => {
    const g = await signInAsPhoneUser("+201000000099");
    await seedGuardian(g.uid);
    assert.equal((await callFunction("manageStaff", { action: "create" }, g)).error?.status, "PERMISSION_DENIED");
    const off = await signInAsStaff("off", "doctor", null, false);
    assert.equal((await callFunction("manageStaff", { action: "create" }, off)).error?.status, "PERMISSION_DENIED");
  });

  it("a secretary needs an existing clinic", async () => {
    const d = await doctor();
    const res = await callFunction("manageStaff", { action: "create", name: "x", email: "a@b.cd", role: "secretary", clinicId: "nope", tempPassword: "Temp-1234" }, d);
    assert.equal(res.error?.details?.field, "clinicId");
  });

  it("disabling takes access away at once (FR-004)", async () => {
    const d = await doctor();
    const s = await secretary1();
    assert.ok((await callFunction("manageStaff", { action: "disable", uid: "sec1" }, d)).result);
    assert.equal((await adminDb().doc("staff/sec1").get()).get("active"), false);
    const after = await callFunction("searchChildren", { query: "يوسف" }, s);
    assert.equal(after.error?.status, "PERMISSION_DENIED");
  });

  it("the last active doctor cannot be disabled or demoted", async () => {
    const d = await doctor();
    assert.equal((await callFunction("manageStaff", { action: "disable", uid: "doc" }, d)).error?.details?.reason, "last_doctor");
    assert.equal(
      (await callFunction("manageStaff", { action: "update", uid: "doc", name: "x", role: "secretary", clinicId: "clinic-1" }, d)).error?.details?.reason,
      "last_doctor",
    );
  });

  it("staffPasswordChanged clears the flag", async () => {
    const s = await secretary1();
    await adminDb().doc("staff/sec1").update({ mustChangePassword: true });
    assert.ok((await callFunction("staffPasswordChanged", {}, s)).result);
    assert.equal((await adminDb().doc("staff/sec1").get()).get("mustChangePassword"), false);
  });
});
