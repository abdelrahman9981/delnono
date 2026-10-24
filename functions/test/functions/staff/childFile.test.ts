import { strict as assert } from "node:assert";
import { adminDb, callFunction, clearEmulators, seedChild, seedSettings } from "../../helpers/env";
import { seedBookingSettings } from "../../helpers/booking";
import { doctor, secretary1 } from "../../helpers/staff";

type File = { child: { name: string }; measurements: { id: string; weightKg: number }[]; doses: unknown[]; visits: { id: string; note?: string | null }[] };

describe("child file (005 US4)", () => {
  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedBookingSettings();
    await seedChild("kid", { name: "يوسف أحمد", nameKey: "يوسف احمد", guardianPhone: "+201000000099", guardianUid: "g1" });
    await adminDb().doc("vaccines/v1").set({ name: "[تطعيم ١]", kind: "basic", active: true });
    await adminDb().doc("children/kid/visits/v9").set({ date: "2026-09-15", type: "clinic", clinicId: "clinic-1" });
    await adminDb().doc("children/kid/visits/v9/staff/notes").set({ text: "[ملاحظة الدكتور]" });
  });

  it("search by name start or guardian phone (FR-013)", async () => {
    const s = await secretary1();
    const byName = await callFunction<{ children: { id: string }[] }>("searchChildren", { query: "يوسف" }, s);
    assert.deepEqual(byName.result?.children.map((c) => c.id), ["kid"]);
    const byPhone = await callFunction<{ children: { id: string }[] }>("searchChildren", { query: "0100 000 0099" }, s);
    assert.deepEqual(byPhone.result?.children.map((c) => c.id), ["kid"]);
  });

  it("opening a file is in the audit log; notes only for the doctor (D-13, FR-016)", async () => {
    const s = await secretary1();
    const d = await doctor();
    const sec = await callFunction<File>("openChildFile", { childId: "kid" }, s);
    assert.ok(sec.result, JSON.stringify(sec.error));
    assert.equal(sec.result.visits[0].note, undefined);
    const doc = await callFunction<File>("openChildFile", { childId: "kid" }, d);
    assert.equal(doc.result?.visits[0].note, "[ملاحظة الدكتور]");
    const audit = await adminDb().collection("auditLog").where("action", "==", "child.opened").get();
    assert.equal(audit.size, 2);
  });

  it("the secretary records a measurement and a dose at her clinic; she cannot change them (D-29)", async () => {
    const s = await secretary1();
    const m = await callFunction<{ id: string }>("saveMeasurement", { childId: "kid", measuredOn: "2026-10-01", weightKg: 9.4, clinicId: "clinic-1" }, s);
    assert.ok(m.result, JSON.stringify(m.error));
    const rec = await adminDb().doc(`children/kid/measurements/${m.result.id}`).get();
    assert.equal(rec.get("clinicId"), "clinic-1");
    assert.equal(rec.get("recordedBy"), "sec1");
    const dose = await callFunction("saveDose", { childId: "kid", vaccineId: "v1", dose: 1, givenOn: "2026-10-01", lot: "L-1", clinicId: "clinic-1" }, s);
    assert.ok(dose.result, JSON.stringify(dose.error));
    const edit = await callFunction("saveMeasurement", { childId: "kid", id: m.result.id, measuredOn: "2026-10-01", weightKg: 9.5 }, s);
    assert.equal(edit.error?.details?.reason, "doctor_only");
    const other = await callFunction("saveMeasurement", { childId: "kid", measuredOn: "2026-10-01", weightKg: 9.4, clinicId: "clinic-2" }, s);
    assert.equal(other.error?.status, "PERMISSION_DENIED");
  });

  it("the doctor corrects with a change log and an audit entry (FR-015)", async () => {
    const s = await secretary1();
    const d = await doctor();
    const m = await callFunction<{ id: string }>("saveMeasurement", { childId: "kid", measuredOn: "2026-10-01", weightKg: 9.4, clinicId: "clinic-1" }, s);
    assert.ok((await callFunction("saveMeasurement", { childId: "kid", id: m.result!.id, measuredOn: "2026-10-01", weightKg: 9.6 }, d)).result);
    const changes = await adminDb().collection(`children/kid/measurements/${m.result!.id}/changes`).get();
    assert.deepEqual(changes.docs[0].get("from"), { weightKg: 9.4 });
    assert.deepEqual(changes.docs[0].get("to"), { weightKg: 9.6 });
    assert.equal((await adminDb().collection("auditLog").where("action", "==", "medical.corrected").get()).size, 1);
  });

  it("values are checked; future dates are refused", async () => {
    const s = await secretary1();
    assert.equal((await callFunction("saveMeasurement", { childId: "kid", measuredOn: "2099-01-01", weightKg: 9, clinicId: "clinic-1" }, s)).error?.details?.field, "measuredOn");
    assert.equal((await callFunction("saveMeasurement", { childId: "kid", measuredOn: "2026-10-01", weightKg: 900, clinicId: "clinic-1" }, s)).error?.details?.field, "weightKg");
  });

  it("only the doctor writes notes", async () => {
    const s = await secretary1();
    const d = await doctor();
    assert.equal((await callFunction("saveVisitNote", { childId: "kid", visitId: "v9", text: "x" }, s)).error?.status, "PERMISSION_DENIED");
    assert.ok((await callFunction("saveVisitNote", { childId: "kid", visitId: "v9", text: "[جديدة]" }, d)).result);
  });

  it("staff edit basic data including birth date and sex (001 FR-024)", async () => {
    const s = await secretary1();
    const res = await callFunction("updateChildBasics", { childId: "kid", name: "يوسف", birthDate: "2024-03-16", sex: "male", allergies: "" }, s);
    assert.ok(res.result, JSON.stringify(res.error));
    const kid = await adminDb().doc("children/kid").get();
    assert.equal(kid.get("birthDate"), "2024-03-16");
    assert.equal(kid.get("updatedBy"), "sec1");
  });
});
