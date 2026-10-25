import { FieldValue, Timestamp, type DocumentSnapshot } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../../lib/admin";
import { writeAudit } from "../../lib/audit";
import { DATE_PATTERN, cairoDate } from "../../lib/booking/time";
import { nameKey } from "../../lib/nameKey";
import { phoneE164 } from "../../lib/phone";
import { REGION } from "../../lib/region";
import { requireClinic, requireStaff, num, str, type Staff } from "../../lib/staff";

/** Firestore values as JSON for the dashboard (timestamps as ISO strings). */
function plain(v: unknown): unknown {
  if (v instanceof Timestamp) return v.toDate().toISOString();
  if (Array.isArray(v)) return v.map(plain);
  if (v && typeof v === "object") return Object.fromEntries(Object.entries(v).map(([k, x]) => [k, plain(x)]));
  return v;
}

const withId = (d: DocumentSnapshot) => ({ id: d.id, ...(plain(d.data()) as Record<string, unknown>) });

/** Finds children by guardian phone or name start (005 FR-013). Basic data only; no audit yet. */
export const searchChildren = onCall({ region: REGION }, async (request) => {
  await requireStaff(request);
  const query = str((request.data ?? {}) as Record<string, unknown>, "query", { max: 80 });
  const phone = phoneE164(query);
  const q = phone
    ? db.collection("children").where("guardianPhone", "==", phone).limit(20)
    : db.collection("children").orderBy("nameKey").startAt(nameKey(query)).endAt(`${nameKey(query)}`).limit(20);
  const snap = await q.get();
  return {
    children: snap.docs.map((d) => ({
      id: d.id, name: d.get("name"), birthDate: d.get("birthDate"), sex: d.get("sex"),
      guardianPhone: d.get("guardianPhone"), linked: d.get("guardianUid") != null,
    })),
  };
});

/**
 * Opens a child file and writes "child file opened" to the audit log (D-13, FR-028): staff never
 * read child records directly, so the log cannot be skipped (005 research R3). The doctor also gets
 * the visit notes; the secretary never does (FR-023).
 */
export const openChildFile = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const childId = str((request.data ?? {}) as Record<string, unknown>, "childId");
  const child = await db.doc(`children/${childId}`).get();
  if (!child.exists) throw new HttpsError("not-found", "Child not found.");
  // A closed (merged) file shows nothing but where it went (009 FR-007).
  const merged = child.get("merged") as { into: string } | undefined;
  if (merged) {
    const kept = await db.doc(`children/${merged.into}`).get();
    return { merged: { into: merged.into, name: kept.get("name") ?? null } };
  }
  const [measurements, doses, visits, packages] = await Promise.all([
    child.ref.collection("measurements").get(),
    child.ref.collection("doses").get(),
    child.ref.collection("visits").get(),
    child.get("guardianUid")
      ? db.collection("packages").where("guardianUid", "==", child.get("guardianUid")).get()
      : Promise.resolve(null),
  ]);
  // What staff can do for the family (009 FR-008, FR-008a) and the desk's guardian record (FR-001a).
  const phone = child.get("guardianPhone") as string;
  const uid = child.get("guardianUid") as string | null;
  const [account, reverify, clinicGuardian] = await Promise.all([
    uid ? Promise.resolve(null) : db.collection("guardians").where("phone", "==", phone).limit(1).get(),
    uid ? db.doc(`reverifyAttempts/${uid}`).get() : Promise.resolve(null),
    db.doc(`clinicGuardians/${phone}`).get(),
  ]);
  const notes = staff.role === "doctor"
    ? await Promise.all(visits.docs.map((v) => v.ref.collection("staff").doc("notes").get()))
    : [];
  // Who recorded each value, by name, for the file's history tables.
  const recorders = [...new Set([...measurements.docs, ...doses.docs].map((r) => r.get("recordedBy")).filter((u): u is string => typeof u === "string"))];
  const names = new Map((await Promise.all(recorders.map((u) => db.doc(`staff/${u}`).get()))).map((s) => [s.id, s.get("name") ?? null]));
  const withRecorder = (r: DocumentSnapshot) => ({ ...withId(r), recordedByName: names.get(r.get("recordedBy")) ?? null });
  await writeAudit({ action: "child.opened", actorUid: staff.uid, subjectPhone: child.get("guardianPhone"), childIds: [childId] });
  const d = child.data()!;
  return {
    child: {
      id: child.id, name: d.name, birthDate: d.birthDate, sex: d.sex, allergies: d.allergies ?? null,
      birthWeightKg: d.birthWeightKg ?? null, guardianPhone: d.guardianPhone, guardianUid: d.guardianUid ?? null,
    },
    measurements: measurements.docs.map(withRecorder),
    doses: doses.docs.map(withRecorder),
    // The note field is sent to the doctor only (D-11).
    visits: visits.docs.map((v, i) => (staff.role === "doctor" ? { ...withId(v), note: notes[i]?.get("text") ?? null } : withId(v))),
    packages: packages?.docs.map(withId) ?? [],
    accountOnNumber: uid != null || !(account?.empty ?? true),
    reverifyLocked: reverify?.get("lockedAt") != null,
    clinicGuardian: clinicGuardian.exists ? { fullName: clinicGuardian.get("fullName"), relation: clinicGuardian.get("relation") } : null,
  };
});

async function childOrThrow(childId: string): Promise<DocumentSnapshot> {
  const child = await db.doc(`children/${childId}`).get();
  if (!child.exists) throw new HttpsError("not-found", "Child not found.");
  return child;
}

function dateField(data: Record<string, unknown>, field: string): string {
  const v = str(data, field);
  if (!DATE_PATTERN.test(v) || v > cairoDate()) throw new HttpsError("invalid-argument", `${field}: a date not in the future`, { field });
  return v;
}

/**
 * Creates or corrects a record. Any active staff member creates at their clinic (D-29); only the
 * doctor changes a saved record, which keeps the old and new values in `changes` and the audit log.
 */
async function saveRecord(staff: Staff, childId: string, kind: "measurements" | "doses", id: string, fields: Record<string, unknown>, clinicId: string) {
  const child = await childOrThrow(childId);
  const col = child.ref.collection(kind);
  if (!id) {
    requireClinic(staff, clinicId);
    const ref = col.doc();
    await ref.set({ ...fields, clinicId, recordedBy: staff.uid, recordedAt: FieldValue.serverTimestamp() });
    await writeAudit({ action: "medical.recorded", actorUid: staff.uid, subjectPhone: child.get("guardianPhone"), childIds: [childId], details: { kind, id: ref.id } });
    return { id: ref.id };
  }
  if (staff.role !== "doctor") {
    throw new HttpsError("permission-denied", "Only the doctor corrects a saved record.", { reason: "doctor_only" });
  }
  const ref = col.doc(id);
  await db.runTransaction(async (tx) => {
    const current = await tx.get(ref);
    if (!current.exists) throw new HttpsError("not-found", "Record not found.");
    const from: Record<string, unknown> = {};
    const to: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(fields)) {
      if (JSON.stringify(current.get(k) ?? null) !== JSON.stringify(v ?? null)) {
        from[k] = current.get(k) ?? null;
        to[k] = v ?? null;
      }
    }
    if (Object.keys(to).length === 0) return;
    tx.update(ref, { ...fields, correctedBy: staff.uid, correctedAt: FieldValue.serverTimestamp() });
    tx.set(ref.collection("changes").doc(), { from, to, by: staff.uid, at: FieldValue.serverTimestamp() });
    await writeAudit({ action: "medical.corrected", actorUid: staff.uid, subjectPhone: child.get("guardianPhone"), childIds: [childId], details: { kind, id, from, to } }, tx);
  });
  return { id };
}

/** Weight, length and head circumference (D-29; ranges as 003 data-model.md). */
export const saveMeasurement = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const weightKg = num(data, "weightKg", { optional: true, min: 0.3, max: 50 });
  const lengthCm = num(data, "lengthCm", { optional: true, min: 20, max: 150 });
  const headCm = num(data, "headCm", { optional: true, min: 20, max: 70 });
  if (weightKg == null && lengthCm == null && headCm == null) throw new HttpsError("invalid-argument", "one value is required", { field: "weightKg" });
  const fields: Record<string, unknown> = {
    measuredOn: dateField(data, "measuredOn"),
    weightKg, lengthCm, headCm,
    visitId: str(data, "visitId", { optional: true }) || null,
  };
  return saveRecord(staff, str(data, "childId"), "measurements", str(data, "id", { optional: true }), fields, String(data.clinicId ?? staff.clinicId ?? ""));
});

/** A vaccine dose given: date and lot number (FR-044, D-29). */
export const saveDose = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const vaccineId = str(data, "vaccineId");
  if (!(await db.doc(`vaccines/${vaccineId}`).get()).exists) throw new HttpsError("invalid-argument", "vaccineId", { field: "vaccineId" });
  const fields: Record<string, unknown> = {
    vaccineId,
    scheduleId: str(data, "scheduleId", { optional: true }) || null,
    dose: num(data, "dose", { min: 1, max: 10 }),
    givenOn: dateField(data, "givenOn"),
    lot: str(data, "lot", { optional: true, max: 40 }) || null,
    visitId: str(data, "visitId", { optional: true }) || null,
  };
  return saveRecord(staff, str(data, "childId"), "doses", str(data, "id", { optional: true }), fields, String(data.clinicId ?? staff.clinicId ?? ""));
});

/** The doctor's note on a visit, read by no one else (D-11, FR-016). */
export const saveVisitNote = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request, { doctor: true });
  const data = (request.data ?? {}) as Record<string, unknown>;
  const child = await childOrThrow(str(data, "childId"));
  const visit = child.ref.collection("visits").doc(str(data, "visitId"));
  if (!(await visit.get()).exists) throw new HttpsError("not-found", "Visit not found.");
  await visit.collection("staff").doc("notes").set({ text: str(data, "text", { optional: true, max: 5000 }), by: staff.uid, at: FieldValue.serverTimestamp() });
  await writeAudit({ action: "note.saved", actorUid: staff.uid, subjectPhone: child.get("guardianPhone"), childIds: [child.id], details: { visitId: visit.id } });
  return {};
});

/** Basic data, including birth date and sex (001 FR-024); the history trigger records the change. */
export const updateChildBasics = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const child = await childOrThrow(str(data, "childId"));
  const name = str(data, "name", { max: 60 });
  if (name.length < 2) throw new HttpsError("invalid-argument", "name", { field: "name" });
  const sex = data.sex;
  if (sex !== "male" && sex !== "female") throw new HttpsError("invalid-argument", "sex", { field: "sex" });
  const allergies = str(data, "allergies", { optional: true, max: 500 }) || null;
  await child.ref.update({
    name, nameKey: nameKey(name), birthDate: dateField(data, "birthDate"), sex, allergies,
    updatedBy: staff.uid, updatedAt: FieldValue.serverTimestamp(),
  });
  await writeAudit({ action: "child.basics_changed", actorUid: staff.uid, subjectPhone: child.get("guardianPhone"), childIds: [child.id] });
  return {};
});
