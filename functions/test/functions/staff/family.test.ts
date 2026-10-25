import { strict as assert } from "node:assert";
import { Timestamp } from "firebase-admin/firestore";
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

describe("merging duplicate files (009 US3, BRD FR-65)", () => {
  const G = "g-merge";
  const day = 24 * 60 * 60 * 1000;
  const booking = (id: string, childIds: string[], inDays: number, status = "confirmed") =>
    adminDb().doc(`bookings/${id}`).set({
      guardianUid: G, clinicId: "clinic-1", status, visitType: "visit", date: "2026-12-01", hour: 18,
      startsAt: Timestamp.fromMillis(Date.now() + inDays * day),
      children: childIds.map((childId) => ({ childId, name: childId, vaccines: [] })),
      price: { visitAmount: 300, visitCovered: false, total: 300, hasHiddenPrices: false, vaccines: childIds.map((childId) => ({ childId, vaccineId: "v1", amount: 0, shown: true })) },
    });

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedBookingSettings();
    await seedChild("keep", { name: "يوسف أحمد", nameKey: "يوسف احمد", guardianPhone: PHONE, guardianUid: G });
    await seedChild("close", { name: "يوسف", nameKey: "يوسف", guardianPhone: PHONE, guardianUid: G });
    await seedChild("other", { name: "علي", nameKey: "علي", guardianPhone: "+201000000011" });
    const c = adminDb().doc("children/close");
    await adminDb().doc("children/keep/measurements/m0").set({ measuredOn: "2026-09-01", weightKg: 11, clinicId: "clinic-1" });
    await c.collection("measurements").doc("m1").set({ measuredOn: "2026-10-01", weightKg: 12, clinicId: "clinic-2", recordedBy: "sec2" });
    await c.collection("measurements/m1/changes").doc("x").set({ from: { weightKg: 11.9 }, to: { weightKg: 12 }, by: "doc" });
    await c.collection("doses").doc("d1").set({ vaccineId: "v1", dose: 1, givenOn: "2024-03-16", lot: "L-1", clinicId: "clinic-1" });
    await c.collection("visits").doc("v1").set({ date: "2026-10-01", type: "clinic", clinicId: "clinic-2" });
    await c.collection("visits/v1/staff").doc("notes").set({ text: "[ملاحظة]" });
  });

  const merge = async (keepId = "keep", closeId = "close") =>
    callFunction<{ moved: Record<string, number> }>("mergeChildren", { keepId, closeId }, await doctor());

  it("moves every record unchanged, with change logs and notes, and closes the other file", async () => {
    const res = await merge();
    assert.ok(res.result, JSON.stringify(res.error));
    assert.deepEqual(res.result.moved, { measurements: 1, doses: 1, visits: 1, bookings: 0 });
    const k = adminDb().doc("children/keep");
    assert.equal((await k.collection("measurements").get()).size, 2);
    const m1 = await k.collection("measurements").doc("m1").get();
    assert.equal(m1.get("clinicId"), "clinic-2");
    assert.equal(m1.get("recordedBy"), "sec2");
    assert.deepEqual((await k.collection("measurements/m1/changes").doc("x").get()).get("to"), { weightKg: 12 });
    assert.equal((await k.collection("doses").doc("d1").get()).get("lot"), "L-1");
    assert.equal((await k.collection("visits/v1/staff").doc("notes").get()).get("text"), "[ملاحظة]");
    const c = adminDb().doc("children/close");
    assert.equal((await c.collection("measurements").get()).size, 0);
    assert.equal((await c.collection("visits/v1/staff").get()).size, 0);
    const closed = await c.get();
    assert.equal(closed.get("merged.into"), "keep");
    assert.equal(closed.get("merged.by"), "doc");
    assert.equal(closed.get("merged.guardianPhone"), PHONE);
    assert.equal(closed.get("merged.name"), "يوسف");
    assert.equal(closed.get("guardianPhone"), null);
    assert.equal(closed.get("guardianUid"), null);
    assert.equal(closed.get("nameKey"), null);
    assert.equal((await k.get()).get("name"), "يوسف أحمد", "kept basic data unchanged");
    const audit = await adminDb().collection("auditLog").where("action", "==", "children.merged").get();
    assert.equal(audit.size, 1);
    assert.equal(audit.docs[0].get("details.closedName"), "يوسف");
  });

  it("the closed file leaves search, the guardian's list and the duplicate check", async () => {
    assert.ok((await merge()).result);
    const s = await secretary1();
    const byPhone = await callFunction<{ children: { id: string }[] }>("searchChildren", { query: "01000000077" }, s);
    assert.deepEqual(byPhone.result?.children.map((c) => c.id), ["keep"]);
    const byName = await callFunction<{ children: { id: string }[] }>("searchChildren", { query: "يوسف" }, s);
    assert.deepEqual(byName.result?.children.map((c) => c.id), ["keep"]);
    assert.equal((await adminDb().collection("children").where("guardianUid", "==", G).get()).size, 1);
    assert.ok((await callFunction("registerFamily", family([{ name: "يوسف", birthDate: "2024-03-15", sex: "male" }]), s)).result,
      "the closed file's name is free again");
  });

  it("opening the closed file says where it went", async () => {
    assert.ok((await merge()).result);
    const res = await callFunction<{ merged: { into: string; name: string } }>("openChildFile", { childId: "close" }, await doctor());
    assert.deepEqual(res.result, { merged: { into: "keep", name: "يوسف أحمد" } });
  });

  it("upcoming bookings move to the kept child; past ones stay", async () => {
    await booking("soon", ["close"], 3);
    await booking("past", ["close"], -3, "done");
    const res = await merge();
    assert.equal(res.result?.moved.bookings, 1);
    const soon = await adminDb().doc("bookings/soon").get();
    assert.deepEqual(soon.get("children").map((c: { childId: string }) => c.childId), ["keep"]);
    assert.deepEqual(soon.get("price").vaccines.map((v: { childId: string }) => v.childId), ["keep"]);
    assert.deepEqual((await adminDb().doc("bookings/past").get()).get("children").map((c: { childId: string }) => c.childId), ["close"]);
  });

  it("refuses: an upcoming booking with both, itself, another number, a closed file, a secretary", async () => {
    await booking("both", ["keep", "close"], 3);
    assert.equal((await merge()).error?.details?.reason, "booked_together");
    await adminDb().doc("bookings/both").delete();
    assert.equal((await merge("keep", "keep")).error?.details?.reason, "same_file");
    assert.equal((await merge("keep", "other")).error?.details?.reason, "other_number");
    const sec = await callFunction("mergeChildren", { keepId: "keep", closeId: "close" }, await secretary1());
    assert.equal(sec.error?.details?.reason, "doctor_only");
    assert.ok((await merge()).result);
    assert.equal((await merge()).error?.details?.reason, "closed");
    assert.equal((await adminDb().collection("auditLog").where("action", "==", "children.merged").get()).size, 1);
  });
});

describe("staff lift a guardian's lock (009 US4, 001 FR-021a)", () => {
  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedBookingSettings();
    await seedGuardian("g1", { phone: PHONE, clinicChildrenPending: true });
    await seedChild("a", { name: "يوسف", nameKey: "يوسف", guardianPhone: PHONE });
    await seedChild("b", { name: "مريم", nameKey: "مريم", guardianPhone: PHONE });
    await seedChild("linked", { name: "سلمى", nameKey: "سلمى", guardianPhone: PHONE, guardianUid: "g1" });
    await seedChild("nobody", { name: "علي", nameKey: "علي", guardianPhone: "+201000000011" });
    await adminDb().doc(`linkAttempts/${PHONE}`).set({ failedCount: 3, lockedAt: new Date() });
  });

  it("links every unlinked child on the number to the account there and clears the lock", async () => {
    const res = await callFunction<{ linked: { childId: string; name: string }[] }>("staffLinkChildren", { childId: "a" }, await secretary1());
    assert.ok(res.result, JSON.stringify(res.error));
    assert.deepEqual(res.result.linked.map((c) => c.childId).sort(), ["a", "b"]);
    for (const id of ["a", "b"]) assert.equal((await adminDb().doc(`children/${id}`).get()).get("guardianUid"), "g1");
    assert.equal((await adminDb().doc(`linkAttempts/${PHONE}`).get()).exists, false);
    assert.equal((await adminDb().doc("guardians/g1").get()).get("clinicChildrenPending"), false);
    const audit = await adminDb().collection("auditLog").where("action", "==", "children.linked_by_staff").get();
    assert.equal(audit.size, 1);
    assert.equal(audit.docs[0].get("actorUid"), "sec1");
  });

  it("refuses with no account on the number, or for a linked child", async () => {
    const s = await secretary1();
    assert.equal((await callFunction("staffLinkChildren", { childId: "nobody" }, s)).error?.details?.reason, "no_account");
    assert.equal((await callFunction("staffLinkChildren", { childId: "linked" }, s)).error?.details?.reason, "already_linked");
  });

  it("unlocks a guardian locked out of re-verification", async () => {
    const s = await secretary1();
    assert.equal((await callFunction("unlockReverify", { childId: "linked" }, s)).error?.details?.reason, "not_locked");
    await adminDb().doc("reverifyAttempts/g1").set({ failedCount: 3, lockedAt: new Date() });
    assert.ok((await callFunction("unlockReverify", { childId: "linked" }, s)).result);
    assert.equal((await adminDb().doc("reverifyAttempts/g1").get()).exists, false);
    assert.equal((await adminDb().collection("auditLog").where("action", "==", "account.reverify_unlocked_by_staff").get()).size, 1);
  });

  it("the child file tells staff what they can do", async () => {
    await adminDb().doc(`clinicGuardians/${PHONE}`).set({ fullName: "[أم يوسف]", relation: "mother" });
    await adminDb().doc("reverifyAttempts/g1").set({ failedCount: 3, lockedAt: new Date() });
    const s = await secretary1();
    type F = { accountOnNumber?: boolean; reverifyLocked?: boolean; clinicGuardian?: { fullName: string } };
    const a = (await callFunction<F>("openChildFile", { childId: "a" }, s)).result!;
    assert.equal(a.accountOnNumber, true);
    assert.equal(a.clinicGuardian?.fullName, "[أم يوسف]");
    assert.equal((await callFunction<F>("openChildFile", { childId: "nobody" }, s)).result!.accountOnNumber, false);
    assert.equal((await callFunction<F>("openChildFile", { childId: "linked" }, s)).result!.reverifyLocked, true);
  });
});
