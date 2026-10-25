import { strict as assert } from "node:assert";
import { adminDb, callFunction, clearEmulators, seedChild, seedGuardian, seedSettings, signInAsPhoneUser } from "../../helpers/env";
import { seedBookingSettings } from "../../helpers/booking";
import { doctor, secretary1 } from "../../helpers/staff";

const PHONE = "+201000000077";
type Registered = { childIds: string[] };
type Dup = { index: number; childId: string; name: string };

const family = (children: Record<string, unknown>[], extra: Record<string, unknown> = {}) => ({
  clinicId: "clinic-1", phone: "01000000077", fullName: "[أم يوسف]", relation: "mother", children, ...extra,
});
const youssef = { name: "يوسف أحمد", birthDate: "2024-03-15", sex: "male" };
const mariam = { name: "مريم", birthDate: "2022-07-02", sex: "female", birthWeightKg: 3.1, allergies: "[بنسلين]" };

describe("desk registration (009 US1, US2; FR-64, FR-65)", () => {
  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedBookingSettings();
  });

  it("registers the guardian for staff and the children unlinked on the number, audited", async () => {
    const s = await secretary1();
    const res = await callFunction<Registered>("registerFamily", family([youssef, mariam]), s);
    assert.ok(res.result, JSON.stringify(res.error));
    assert.equal(res.result.childIds.length, 2);
    for (const id of res.result.childIds) {
      const c = await adminDb().doc(`children/${id}`).get();
      assert.equal(c.get("guardianPhone"), PHONE);
      assert.equal(c.get("guardianUid"), null);
      assert.equal(c.get("registeredBy"), "staff");
      assert.equal(c.get("registeredAt"), "clinic-1");
      assert.equal(c.get("registeredByUid"), "sec1");
      assert.ok(c.get("nameKey"));
    }
    const m = (await adminDb().collection("children").where("name", "==", "مريم").get()).docs[0];
    assert.equal(m.get("birthWeightKg"), 3.1);
    assert.equal(m.get("allergies"), "[بنسلين]");
    const g = await adminDb().doc(`clinicGuardians/${PHONE}`).get();
    assert.equal(g.get("fullName"), "[أم يوسف]");
    assert.equal(g.get("relation"), "mother");
    const audit = await adminDb().collection("auditLog").where("action", "==", "family.registered").get();
    assert.equal(audit.size, 1);
    assert.deepEqual([...audit.docs[0].get("childIds")].sort(), [...res.result.childIds].sort());
    assert.equal(audit.docs[0].get("subjectPhone"), PHONE);
  });

  it("the guardian then links them in the app with one birth date (001 FR-021)", async () => {
    const s = await secretary1();
    assert.ok((await callFunction<Registered>("registerFamily", family([youssef, mariam]), s)).result);
    const user = await signInAsPhoneUser(PHONE);
    await seedGuardian(user.uid, { phone: PHONE, clinicChildrenPending: true });
    const link = await callFunction<{ linked: { name: string }[] }>("linkClinicChildren", { birthDate: "2022-07-02" }, user);
    assert.deepEqual(link.result?.linked.map((c) => c.name).sort(), ["مريم", "يوسف أحمد"]);
  });

  it("accepts the number as 01…, +201… or 201…; refuses anything else", async () => {
    const s = await secretary1();
    assert.ok((await callFunction("registerFamily", family([youssef], { phone: "+20 100 000 0077" }), s)).result);
    assert.ok((await callFunction("registerFamily", family([mariam], { phone: "201000000077" }), s)).result);
    assert.equal((await adminDb().collection("children").where("guardianPhone", "==", PHONE).get()).size, 2);
    assert.equal((await callFunction("registerFamily", family([youssef], { phone: "12345" }), s)).error?.details?.field, "phone");
  });

  it("validation errors name the field and the child", async () => {
    const s = await secretary1();
    const future = await callFunction("registerFamily", family([youssef, { ...mariam, birthDate: "2099-01-01" }]), s);
    assert.equal(future.error?.status, "INVALID_ARGUMENT");
    assert.equal(future.error?.details?.field, "birthDate");
    assert.equal(future.error?.details?.index, 1);
    assert.equal((await callFunction("registerFamily", family([]), s)).error?.details?.field, "children");
    assert.equal((await callFunction("registerFamily", family([youssef], { fullName: "" }), s)).error?.details?.field, "fullName");
    assert.equal((await adminDb().collection("children").get()).size, 0, "nothing created");
  });

  it("a secretary registers only at her clinic; the doctor at any", async () => {
    const other = await callFunction("registerFamily", family([youssef], { clinicId: "clinic-2" }), await secretary1());
    assert.equal(other.error?.details?.reason, "other_clinic");
    assert.ok((await callFunction("registerFamily", family([youssef], { clinicId: "clinic-2" }), await doctor())).result);
  });

  it("a duplicate on the number creates nothing and points to the existing file (FR-65)", async () => {
    await seedChild("existing", { name: "يُوسف  احمد", nameKey: "يوسف احمد", birthDate: "2024-03-15", guardianPhone: PHONE, guardianUid: "g1", registeredBy: "guardian" });
    const res = await callFunction("registerFamily", family([mariam, youssef]), await secretary1());
    assert.equal(res.error?.status, "ALREADY_EXISTS");
    assert.equal(res.error?.details?.reason, "duplicate");
    assert.deepEqual(res.error?.details?.duplicates as Dup[], [{ index: 1, childId: "existing", name: "يُوسف  احمد" }]);
    assert.equal((await adminDb().collection("children").get()).size, 1, "mariam not created either");
    assert.equal((await adminDb().doc(`clinicGuardians/${PHONE}`).get()).exists, false);
  });

  it("the same child twice in one request is a duplicate; another number is not", async () => {
    const s = await secretary1();
    const twice = await callFunction("registerFamily", family([youssef, { ...youssef, name: "يوسف احمد" }]), s);
    assert.equal(twice.error?.details?.reason, "duplicate");
    assert.equal((twice.error?.details?.duplicates as Dup[])[0].index, 1);
    await seedChild("elsewhere", { name: "يوسف أحمد", nameKey: "يوسف احمد", birthDate: "2024-03-15", guardianPhone: "+201000000011" });
    assert.ok((await callFunction("registerFamily", family([youssef]), s)).result);
  });
});
