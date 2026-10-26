import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../../lib/admin";
import { writeAudit } from "../../lib/audit";
import { hoursOf } from "../../lib/booking/schedule";
import { bookingSettingsFrom } from "../../lib/booking/settings";
import { cairoDate } from "../../lib/booking/time";
import { REGION } from "../../lib/region";
import { requireClinic, requireStaff, str } from "../../lib/staff";

/** Fields of `clinics/{id}` each role may change (005 FR-018, D-47). */
const SECRETARY_FIELDS = [
  "address", "phone", "whatsapp", "workingHours", "holidays", "capacityPerHour", "vaccineWeekdays",
  "cancelWindowHours", "visitPrice", "packagePrice", "packageMonths", "vaccinePrices",
];
const DOCTOR_FIELDS = [...SECRETARY_FIELDS, "name", "area", "active", "order"];
const PRICE_FIELDS = ["visitPrice", "packagePrice", "vaccinePrices"];

/**
 * A clinic's schedule, prices and contact (D-44, D-45). Confirmed bookings keep their fixed prices
 * (FR-047). Removing hours or adding holidays that still hold confirmed bookings is refused, listing
 * them, so families are never left with a booking outside the hours.
 */
export const updateClinic = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const clinicId = requireClinic(staff, data.clinicId);
  const fields = (data.fields ?? {}) as Record<string, unknown>;
  const allowed = staff.role === "doctor" ? DOCTOR_FIELDS : SECRETARY_FIELDS;
  const bad = Object.keys(fields).filter((k) => !allowed.includes(k));
  if (bad.length) throw new HttpsError("permission-denied", `Not allowed: ${bad.join(", ")}`, { fields: bad });
  for (const k of ["capacityPerHour", "cancelWindowHours", "visitPrice", "packagePrice", "packageMonths"]) {
    if (k in fields && (typeof fields[k] !== "number" || (fields[k] as number) < 0)) throw new HttpsError("invalid-argument", k, { field: k });
  }

  const ref = db.doc(`clinics/${clinicId}`);
  const current = await ref.get();
  if (!current.exists) throw new HttpsError("not-found", "Clinic not found.");

  if ("workingHours" in fields || "holidays" in fields) {
    const next = bookingSettingsFrom({ ...current.data(), ...fields }, undefined);
    const upcoming = await db.collection("bookings").where("clinicId", "==", clinicId).where("status", "==", "confirmed")
      .where("startsAt", ">", Timestamp.now()).get();
    const orphaned = upcoming.docs.filter((b) => !hoursOf(next, b.get("date")).includes(b.get("hour")));
    if (orphaned.length) {
      throw new HttpsError("failed-precondition", "Bookings fall outside the new hours.", {
        reason: "bookings_outside_hours",
        bookings: orphaned.map((b) => ({ id: b.id, number: b.get("number"), date: b.get("date"), hour: b.get("hour") })),
      });
    }
  }

  await ref.update({ ...fields, updatedAt: FieldValue.serverTimestamp(), updatedBy: staff.uid });
  const prices = Object.keys(fields).filter((k) => PRICE_FIELDS.includes(k));
  await writeAudit({
    action: "clinic.updated", actorUid: staff.uid,
    details: {
      clinicId, fields: Object.keys(fields),
      ...(prices.length ? { prices: Object.fromEntries(prices.map((k) => [k, { from: current.get(k) ?? null, to: fields[k] }])) } : {}),
    },
  });
  return {};
});

/**
 * The doctor's vaccine list and schedule (FR-040, Principle II): vaccines (name, kind, active, notes,
 * additional details), schedule entries, and the schedule's source; approving sets the review date
 * and clears the placeholder marks.
 */
export const updateCatalogue = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request, { doctor: true });
  const data = (request.data ?? {}) as Record<string, unknown>;
  const batch = db.batch();
  const approve = data.approve === true;
  for (const v of (data.vaccines as Record<string, unknown>[] | undefined) ?? []) {
    const id = str(v, "id");
    const { id: _, ...rest } = v;
    batch.set(db.doc(`vaccines/${id}`), { ...rest, ...(approve ? { placeholder: false, reviewStatus: "approved" } : {}), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  }
  for (const e of (data.schedule as Record<string, unknown>[] | undefined) ?? []) {
    const id = str(e, "id");
    const { id: _, ...rest } = e;
    batch.set(db.doc(`vaccineSchedule/${id}`), { ...rest, ...(approve ? { placeholder: false, reviewStatus: "approved" } : {}) }, { merge: true });
  }
  for (const id of (data.deleteSchedule as string[] | undefined) ?? []) batch.delete(db.doc(`vaccineSchedule/${id}`));
  const info: Record<string, unknown> = {};
  if (typeof data.source === "string") info.source = data.source;
  if (approve) {
    info.reviewedOn = cairoDate();
    info.placeholder = false;
    info.reviewStatus = "approved";
    // Approving covers the whole list the doctor reviewed, including entries not edited this time.
    const sent = new Set(((data.schedule as Record<string, unknown>[] | undefined) ?? []).map((e) => String(e.id)));
    const deleted = new Set((data.deleteSchedule as string[] | undefined) ?? []);
    for (const d of (await db.collection("vaccineSchedule").get()).docs) {
      if (!sent.has(d.id) && !deleted.has(d.id)) batch.set(d.ref, { placeholder: false, reviewStatus: "approved" }, { merge: true });
    }
  }
  if (Object.keys(info).length) batch.set(db.doc("settings/vaccines"), info, { merge: true });
  await batch.commit();
  await writeAudit({ action: "catalogue.updated", actorUid: staff.uid, details: { approve } });
  return {};
});

/** Follow-up lists and danger signs as drafts (D-19, 005 R7); the app keeps the published ones. */
export const saveFollowUpDraft = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const bands = (data.bands as Record<string, unknown>[] | undefined) ?? [];
  const existing = await db.collection("followUpDrafts").get();
  const batch = db.batch();
  for (const d of existing.docs) if (d.id !== "_settings") batch.delete(d.ref);
  bands.forEach((b, order) => {
    const from = Number(b.fromMonths), to = Number(b.toMonths);
    if (!(from >= 0 && to > from)) throw new HttpsError("invalid-argument", "band ages", { field: "bands" });
    batch.set(db.doc(`followUpDrafts/b${from}`), {
      fromMonths: from, toMonths: to, title: String(b.title ?? ""), items: ((b.items as unknown[]) ?? []).map(String), order,
      dangerSigns: ((b.dangerSigns as unknown[]) ?? []).map(String),
    });
  });
  batch.set(db.doc("followUpDrafts/_settings"), {
    dangerSigns: ((data.dangerSigns as unknown[]) ?? []).map(String), updatedBy: staff.uid, updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  return {};
});

/** The doctor publishes the drafts: they replace the follow-up lists and danger signs the app reads. */
export const publishFollowUp = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request, { doctor: true });
  const [drafts, live] = await Promise.all([db.collection("followUpDrafts").get(), db.collection("followUp").get()]);
  const settings = drafts.docs.find((d) => d.id === "_settings");
  const bands = drafts.docs.filter((d) => d.id !== "_settings");
  if (!settings && bands.length === 0) throw new HttpsError("failed-precondition", "Nothing to publish.", { reason: "no_draft" });
  const batch = db.batch();
  for (const d of live.docs) if (!bands.some((b) => b.id === d.id)) batch.delete(d.ref);
  // Publishing is the doctor's approval: proposed (researched) items become approved.
  for (const b of bands) batch.set(db.doc(`followUp/${b.id}`), { ...b.data(), placeholder: false, reviewStatus: "approved" });
  if (settings) {
    batch.set(db.doc("settings/followUp"), { dangerSigns: settings.get("dangerSigns"), placeholder: false, reviewStatus: "approved" }, { merge: true });
  }
  await batch.commit();
  await writeAudit({ action: "followup.published", actorUid: staff.uid, details: { bands: bands.length } });
  return {};
});

/** App settings and texts the doctor edits (005 FR-024), field by field. */
const SETTINGS_FIELDS: Record<string, string[]> = {
  auth: ["codeValiditySeconds", "maxCodeAttempts", "resendWaitSeconds", "dailySmsCapPerNumber", "maxLinkAttempts", "reverifyAfterDays"],
  policy: ["currentVersion", "privacyPolicyText", "termsText"],
  booking: ["bookingHorizonDays", "maxUpcomingPerFamily"],
  followUp: ["maxAgeMonths"],
  vaccines: ["lateAfterDays", "source"],
};

export const updateSettings = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request, { doctor: true });
  const data = (request.data ?? {}) as Record<string, unknown>;
  const docId = str(data, "doc");
  const allowed = SETTINGS_FIELDS[docId];
  if (!allowed) throw new HttpsError("invalid-argument", "doc", { field: "doc" });
  const fields = (data.fields ?? {}) as Record<string, unknown>;
  const bad = Object.keys(fields).filter((k) => !allowed.includes(k));
  if (bad.length) throw new HttpsError("invalid-argument", `Not allowed: ${bad.join(", ")}`, { fields: bad });
  const ref = db.doc(`settings/${docId}`);
  const current = await ref.get();
  if (docId === "policy" && "currentVersion" in fields && Number(fields.currentVersion) < Number(current.get("currentVersion") ?? 1)) {
    throw new HttpsError("invalid-argument", "The policy version only goes up.", { field: "currentVersion" });
  }
  await ref.set({ ...fields, ...(docId === "policy" ? { updatedAt: FieldValue.serverTimestamp() } : {}) }, { merge: true });
  await writeAudit({ action: "settings.updated", actorUid: staff.uid, details: { doc: docId, fields: Object.keys(fields) } });
  return {};
});
