import { FieldValue, Timestamp, type DocumentSnapshot, type Transaction } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../../lib/admin";
import { writeAudit } from "../../lib/audit";
import { hoursOf } from "../../lib/booking/schedule";
import { clinicOf, readBookingSettings } from "../../lib/booking/settings";
import { cairoDate, slotId, startsAt } from "../../lib/booking/time";
import { REGION } from "../../lib/region";
import { requireClinic, requireStaff, str, type Staff } from "../../lib/staff";

/** Writes a visit for each registered child when a booking or walk-in is done (D-48, 005 R4). */
function writeVisits(tx: Transaction, doc: DocumentSnapshot, clinicId: string, kind: "booking" | "walkIn") {
  const children = (doc.get("children") as { childId?: string | null }[] | undefined) ?? [];
  for (const c of children) {
    if (!c.childId) continue;
    tx.set(db.doc(`children/${c.childId}/visits/${doc.id}`), {
      date: doc.get("date"),
      type: kind === "walkIn" ? "walkIn" : doc.get("visitType") === "vaccine_only" ? "vaccine" : "clinic",
      clinicId,
      ...(kind === "booking" ? { bookingId: doc.id } : { walkInId: doc.id }),
      createdAt: FieldValue.serverTimestamp(),
    });
  }
}

function deleteVisits(tx: Transaction, doc: DocumentSnapshot) {
  for (const c of (doc.get("children") as { childId?: string | null }[] | undefined) ?? []) {
    if (c.childId) tx.delete(db.doc(`children/${c.childId}/visits/${doc.id}`));
  }
}

/**
 * Arrival queue (D-06, FR-006, FR-010): arrive, done, no-show; statuses only move forward, the doctor
 * can undo the last step the same day (005 clarification). contracts/callables.md#queueaction
 */
export const queueAction = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const action = data.action;
  const isWalkIn = typeof data.walkInId === "string";
  const ref = db.doc(isWalkIn ? `walkIns/${data.walkInId}` : `bookings/${str(data, "bookingId")}`);

  await db.runTransaction(async (tx) => {
    const now = new Date();
    const doc = await tx.get(ref);
    if (!doc.exists) throw new HttpsError("not-found", "Not found.");
    const clinicId = await clinicOf(doc.data(), tx);
    requireClinic(staff, clinicId);
    const status = doc.get("status") as string;
    const today = cairoDate(now);
    const by = { statusBy: staff.uid, updatedAt: FieldValue.serverTimestamp() };
    const refuse = (reason: string) => {
      throw new HttpsError("failed-precondition", `Cannot ${action} from ${status}.`, { reason });
    };

    switch (action) {
      case "arrive":
        if (isWalkIn || status !== "confirmed") refuse("wrong_status");
        if (doc.get("date") !== today) refuse("not_today");
        tx.update(ref, { status: "arrived", arrivedAt: Timestamp.fromDate(now), ...by });
        break;
      case "done":
        if (status !== "arrived") refuse("wrong_status");
        tx.update(ref, { status: "done", doneAt: Timestamp.fromDate(now), ...by });
        writeVisits(tx, doc, clinicId, isWalkIn ? "walkIn" : "booking");
        break;
      case "noShow": {
        if (isWalkIn || status !== "confirmed") refuse("wrong_status");
        const ended = startsAt(doc.get("date"), (doc.get("hour") as number) + 1);
        if (now < ended) refuse("hour_not_over");
        tx.update(ref, { status: "no_show", ...by });
        break;
      }
      case "undo": {
        if (staff.role !== "doctor") throw new HttpsError("permission-denied", "Doctor only.");
        if (doc.get("date") !== today) refuse("not_today");
        const back: Record<string, string> = { arrived: "confirmed", done: "arrived", no_show: "confirmed" };
        const to = back[status];
        if (!to || (isWalkIn && to === "confirmed")) refuse("wrong_status");
        const update: Record<string, unknown> = { status: to, ...by };
        if (status === "arrived") update.arrivedAt = FieldValue.delete();
        if (status === "done") {
          update.doneAt = FieldValue.delete();
          deleteVisits(tx, doc);
        }
        tx.update(ref, update);
        await writeAudit({ action: "status.undone", actorUid: staff.uid, details: { id: doc.id, from: status, to } }, tx);
        break;
      }
      default:
        throw new HttpsError("invalid-argument", "action", { field: "action" });
    }
  });
  return {};
});

interface WalkInChild {
  childId: string | null;
  name: string;
}

/**
 * A family without a booking joins today's queue in an hour of the clinic (FR-058, FR-059, D-07):
 * it takes a place in that hour; refused when the hour is full or walk-ins are stopped today.
 */
export const addWalkIn = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const clinicId = requireClinic(staff, data.clinicId);
  const hour = data.hour;
  if (typeof hour !== "number" || !Number.isInteger(hour)) throw new HttpsError("invalid-argument", "hour", { field: "hour" });
  const familyName = str(data, "familyName", { max: 80 });
  const phone = str(data, "phone", { max: 20 });
  const visitType = data.visitType === "vaccine_only" ? "vaccine_only" : "visit";
  const rawChildren = Array.isArray(data.children) ? (data.children as Record<string, unknown>[]) : [];
  const children: WalkInChild[] = rawChildren
    .map((c) => ({ childId: typeof c.childId === "string" && c.childId ? c.childId : null, name: String(c.name ?? "").trim() }))
    .filter((c) => c.name);
  if (children.length === 0) throw new HttpsError("invalid-argument", "children", { field: "children" });

  return db.runTransaction(async (tx) => {
    const now = new Date();
    const date = cairoDate(now);
    const settings = await readBookingSettings(clinicId, tx);
    const slotRef = db.doc(`slots/${slotId(clinicId, date, hour)}`);
    const [slot, day] = await Promise.all([tx.get(slotRef), tx.get(db.doc(`days/${clinicId}_${date}`))]);
    if (day.get("walkInsStopped") === true) throw new HttpsError("failed-precondition", "Walk-ins stopped.", { reason: "walk_ins_stopped" });
    if (!hoursOf(settings, date).includes(hour)) throw new HttpsError("failed-precondition", "Outside hours.", { reason: "outside_hours" });
    if (startsAt(date, hour + 1) <= now) throw new HttpsError("failed-precondition", "That hour is over.", { reason: "started" });
    const taken = (slot.get("taken") as number | undefined) ?? 0;
    if (taken >= settings.capacityPerHour) throw new HttpsError("resource-exhausted", "The hour is full.", { reason: "full" });

    const ref = db.collection("walkIns").doc();
    tx.set(ref, {
      clinicId, date, hour, familyName, phone, children, visitType,
      status: "arrived", arrivedAt: Timestamp.fromDate(now), createdBy: staff.uid, createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(slotRef, { clinicId, date, hour, taken: taken + 1 }, { merge: true });
    return { walkInId: ref.id };
  });
});

/** Stops or resumes walk-ins for a day at a clinic (D-07, FR-008). */
export const setWalkInsStopped = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const clinicId = requireClinic(staff, data.clinicId);
  const date = typeof data.date === "string" ? data.date : cairoDate();
  await db.doc(`days/${clinicId}_${date}`).set(
    { clinicId, date, walkInsStopped: data.stopped === true, by: staff.uid, at: FieldValue.serverTimestamp() },
    { merge: true },
  );
  return {};
});

/** The family's package covering [date], if any. */
async function activePackage(guardianUid: string | null, date: string, tx: Transaction): Promise<string | null> {
  if (!guardianUid) return null;
  const q = await tx.get(db.collection("packages").where("guardianUid", "==", guardianUid).where("active", "==", true));
  return q.docs.find((p) => p.get("startsOn") <= date && date <= p.get("endsOn"))?.id ?? null;
}

async function guardianByPhone(phone: string, tx: Transaction): Promise<string | null> {
  const q = await tx.get(db.collection("guardians").where("phone", "==", phone).limit(1));
  return q.empty ? null : q.docs[0].id;
}

/**
 * Cash paid for a visit, or covered by the family's package (FR-049, D-46). The covered visit is
 * counted at the clinic where it happened.
 */
export const recordPayment = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const isWalkIn = typeof data.walkInId === "string";
  const ref = db.doc(isWalkIn ? `walkIns/${data.walkInId}` : `bookings/${str(data, "bookingId")}`);
  const cash = data.cash;
  if (typeof cash !== "number" || cash < 0 || cash > 100000) throw new HttpsError("invalid-argument", "cash", { field: "cash" });
  const covered = data.covered === true;

  await db.runTransaction(async (tx) => {
    const doc = await tx.get(ref);
    if (!doc.exists) throw new HttpsError("not-found", "Not found.");
    const clinicId = await clinicOf(doc.data(), tx);
    requireClinic(staff, clinicId);
    if (!["arrived", "done"].includes(doc.get("status"))) {
      throw new HttpsError("failed-precondition", "Payment is for arrived or done visits.", { reason: "wrong_status" });
    }
    let packageId: string | null = null;
    if (covered) {
      const guardianUid = isWalkIn ? await guardianByPhone(doc.get("phone"), tx) : (doc.get("guardianUid") as string);
      packageId = await activePackage(guardianUid, doc.get("date"), tx);
      if (!packageId) throw new HttpsError("failed-precondition", "No active package.", { reason: "no_package" });
    }
    tx.update(ref, {
      payment: { cash, covered, packageId, recordedBy: staff.uid, recordedAt: FieldValue.serverTimestamp() },
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  return {};
});

function addMonths(date: string, months: number): string {
  const [y, m, d] = date.split("-").map(Number);
  const target = new Date(Date.UTC(y, m - 1 + months, 1));
  const last = new Date(Date.UTC(target.getUTCFullYear(), target.getUTCMonth() + 1, 0)).getUTCDate();
  target.setUTCDate(Math.min(d, last));
  return target.toISOString().slice(0, 10);
}

/**
 * Sells the annual package to a family at this clinic's price (D-14, D-46, FR-048): valid in every
 * clinic from today for the clinic's package months; revenue counts for this clinic.
 */
export const sellPackage = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const clinicId = requireClinic(staff, data.clinicId);
  const guardianUid = str(data, "guardianUid");

  return db.runTransaction(async (tx) => {
    const today = cairoDate();
    const [clinic, guardian] = await Promise.all([tx.get(db.doc(`clinics/${clinicId}`)), tx.get(db.doc(`guardians/${guardianUid}`))]);
    if (!clinic.exists) throw new HttpsError("failed-precondition", "Unknown clinic.", { reason: "clinic_inactive" });
    if (!guardian.exists) throw new HttpsError("not-found", "Family not found.");
    if (await activePackage(guardianUid, today, tx)) {
      throw new HttpsError("already-exists", "The family already has an active package.", { reason: "has_package" });
    }
    const months = (clinic.get("packageMonths") as number | undefined) ?? 12;
    const ref = db.collection("packages").doc();
    const pkg = {
      guardianUid, soldAtClinicId: clinicId, price: (clinic.get("packagePrice") as number | undefined) ?? 0,
      startsOn: today, endsOn: addMonths(today, months), active: true, soldBy: staff.uid, soldOn: today,
      soldAt: FieldValue.serverTimestamp(),
    };
    tx.set(ref, pkg);
    await writeAudit({ action: "package.sold", actorUid: staff.uid, subjectPhone: guardian.get("phone"), details: { packageId: ref.id, clinicId, price: pkg.price } }, tx);
    return { packageId: ref.id, endsOn: pkg.endsOn, price: pkg.price };
  });
});

export type { Staff };
