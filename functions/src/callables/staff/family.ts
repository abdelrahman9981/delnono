import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../../lib/admin";
import { writeAudit } from "../../lib/audit";
import { nameKey } from "../../lib/nameKey";
import { phoneE164 } from "../../lib/phone";
import { REGION } from "../../lib/region";
import { requireClinic, requireStaff } from "../../lib/staff";
import { validateChild, validateGuardian, type ChildInput } from "../../lib/validation";

const MAX_CHILDREN = 6;

/** Child validation errors also say which child of the request failed. */
function childAt(data: unknown, index: number): ChildInput {
  try {
    return validateChild((data ?? {}) as Record<string, unknown>);
  } catch (e) {
    if (e instanceof HttpsError) throw new HttpsError(e.code, e.message, { ...(e.details as object), index });
    throw e;
  }
}

/**
 * Registers a family at the desk (009 FR-001–FR-004, BRD FR-64): the guardian's name for staff
 * (`clinicGuardians/{phone}`, never shown in the app) and children on the number with no app
 * account, so the guardian links them in the app after the birth-date check (001 FR-021). Any
 * child already on the number with the same normalised name and birth date, or repeated in the
 * request, creates nothing (BRD FR-65). contracts/callables.md#registerfamily
 */
export const registerFamily = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const clinicId = requireClinic(staff, data.clinicId);
  const phone = typeof data.phone === "string" ? phoneE164(data.phone) : null;
  if (!phone) throw new HttpsError("invalid-argument", "phone: an Egyptian mobile number", { field: "phone" });
  const guardian = validateGuardian(data);
  const raw = data.children;
  if (!Array.isArray(raw) || raw.length < 1 || raw.length > MAX_CHILDREN) {
    throw new HttpsError("invalid-argument", `children: 1–${MAX_CHILDREN}`, { field: "children" });
  }
  const children = raw.map(childAt);

  const childIds = await db.runTransaction(async (tx) => {
    const duplicates: { index: number; childId: string; name: string }[] = [];
    const seen = new Map<string, number>();
    for (const [index, child] of children.entries()) {
      const key = nameKey(child.name);
      const existing = await tx.get(
        db.collection("children")
          .where("guardianPhone", "==", phone)
          .where("nameKey", "==", key)
          .where("birthDate", "==", child.birthDate)
          .limit(1),
      );
      const twice = seen.get(`${key}|${child.birthDate}`);
      if (!existing.empty) duplicates.push({ index, childId: existing.docs[0].id, name: existing.docs[0].get("name") as string });
      else if (twice !== undefined) duplicates.push({ index, childId: "", name: children[twice].name });
      seen.set(`${key}|${child.birthDate}`, index);
    }
    if (duplicates.length > 0) {
      throw new HttpsError("already-exists", "A child with this name and birth date is already on this number.", {
        reason: "duplicate", duplicates,
      });
    }

    const now = FieldValue.serverTimestamp();
    tx.set(db.doc(`clinicGuardians/${phone}`), { ...guardian, createdAt: now, createdBy: staff.uid }, { merge: true });
    const ids: string[] = [];
    for (const child of children) {
      const ref = db.collection("children").doc();
      tx.set(ref, {
        ...child,
        nameKey: nameKey(child.name),
        guardianPhone: phone,
        guardianUid: null,
        registeredBy: "staff",
        registeredAt: clinicId,
        registeredByUid: staff.uid,
        createdAt: now,
        updatedAt: now,
        updatedBy: staff.uid,
      });
      ids.push(ref.id);
    }
    await writeAudit({ action: "family.registered", actorUid: staff.uid, subjectPhone: phone, childIds: ids, details: { clinicId } }, tx);
    return ids;
  });

  return { childIds };
});

const RECORD_KINDS = ["measurements", "doses", "visits"] as const;
/** Staff-only documents under a record that move with it (005: change logs, the doctor's notes). */
const RECORD_SUBCOLLECTIONS: Record<(typeof RECORD_KINDS)[number], string[]> = {
  measurements: ["changes"],
  doses: ["changes"],
  visits: ["staff"],
};
/** A transaction holds at most 500 writes; a merge needing more is refused rather than split. */
const MAX_MERGE_WRITES = 400;

function refuse(reason: string, message: string): never {
  throw new HttpsError("failed-precondition", message, { reason });
}

/**
 * Merges two files of one child (009 FR-005–FR-007, BRD FR-65), doctor only. In one transaction:
 * every measurement, dose and visit of the closed file (with change logs and staff notes) moves to
 * the kept file unchanged; upcoming confirmed bookings name the kept child; the closed file keeps
 * its data under `merged` and loses its number, link and name key, so search, the guardian's app,
 * linking and duplicate checks no longer see it (research R1). contracts/callables.md#mergechildren
 */
export const mergeChildren = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  if (staff.role !== "doctor") {
    throw new HttpsError("permission-denied", "Only the doctor merges files.", { reason: "doctor_only" });
  }
  const data = (request.data ?? {}) as Record<string, unknown>;
  const keepId = typeof data.keepId === "string" ? data.keepId : "";
  const closeId = typeof data.closeId === "string" ? data.closeId : "";
  if (!keepId || !closeId) throw new HttpsError("invalid-argument", "keepId and closeId are required", { field: "keepId" });
  if (keepId === closeId) refuse("same_file", "A file cannot be merged with itself.");

  const moved = await db.runTransaction(async (tx) => {
    const keepRef = db.doc(`children/${keepId}`);
    const closeRef = db.doc(`children/${closeId}`);
    const [keep, close] = await Promise.all([tx.get(keepRef), tx.get(closeRef)]);
    if (!keep.exists || !close.exists) throw new HttpsError("not-found", "Child not found.");
    if (keep.get("merged") != null || close.get("merged") != null) refuse("closed", "A closed file cannot be merged.");
    const phone = close.get("guardianPhone") as string | null;
    if (!phone || phone !== keep.get("guardianPhone")) refuse("other_number", "The files are on different numbers.");

    // Reads first (transactions read before they write).
    const records = [];
    for (const kind of RECORD_KINDS) {
      for (const doc of (await tx.get(closeRef.collection(kind))).docs) {
        const subs = [];
        for (const sub of RECORD_SUBCOLLECTIONS[kind]) subs.push(...(await tx.get(doc.ref.collection(sub))).docs);
        const clash = (await tx.get(keepRef.collection(kind).doc(doc.id))).exists;
        records.push({ kind, doc, subs, target: clash ? keepRef.collection(kind).doc() : keepRef.collection(kind).doc(doc.id) });
      }
    }
    const guardianUid = close.get("guardianUid") as string | null;
    const now = Date.now();
    const bookings = guardianUid
      ? (await tx.get(db.collection("bookings").where("guardianUid", "==", guardianUid).where("status", "==", "confirmed"))).docs
          .filter((b) => (b.get("startsAt")?.toMillis?.() ?? 0) > now)
          .filter((b) => (b.get("children") as { childId: string }[]).some((c) => c.childId === closeId))
      : [];
    if (bookings.some((b) => (b.get("children") as { childId: string }[]).some((c) => c.childId === keepId))) {
      refuse("booked_together", "An upcoming booking lists both children.");
    }
    const writes = records.reduce((n, r) => n + 2 + 2 * r.subs.length, 0) + bookings.length + 2;
    if (writes > MAX_MERGE_WRITES) refuse("too_large", "Too many records to merge at once.");

    for (const r of records) {
      tx.set(r.target, r.doc.data()!);
      for (const sub of r.subs) {
        tx.set(r.target.collection(sub.ref.parent.id).doc(sub.id), sub.data());
        tx.delete(sub.ref);
      }
      tx.delete(r.doc.ref);
    }
    const repoint = <T extends { childId: string }>(list: T[] | undefined) =>
      (list ?? []).map((x) => (x.childId === closeId ? { ...x, childId: keepId } : x));
    for (const b of bookings) {
      const price = b.get("price") as { vaccines?: { childId: string }[] } | undefined;
      tx.update(b.ref, {
        children: repoint(b.get("children") as { childId: string }[]),
        ...(price ? { "price.vaccines": repoint(price.vaccines) } : {}),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    tx.update(closeRef, {
      merged: {
        into: keepId,
        at: FieldValue.serverTimestamp(),
        by: staff.uid,
        guardianPhone: phone,
        guardianUid,
        name: close.get("name"),
        birthDate: close.get("birthDate"),
      },
      guardianPhone: null,
      guardianUid: null,
      nameKey: null,
      updatedAt: FieldValue.serverTimestamp(),
      updatedBy: staff.uid,
    });
    const counts = {
      measurements: records.filter((r) => r.kind === "measurements").length,
      doses: records.filter((r) => r.kind === "doses").length,
      visits: records.filter((r) => r.kind === "visits").length,
      bookings: bookings.length,
    };
    await writeAudit({
      action: "children.merged", actorUid: staff.uid, subjectPhone: phone, childIds: [keepId, closeId],
      details: { kept: keepId, closed: closeId, closedName: close.get("name"), closedBirthDate: close.get("birthDate"), ...counts },
    }, tx);
    return counts;
  });

  return { moved };
});

/** An open child and its number, for the staff link and unlock below. */
async function openChild(data: unknown) {
  const childId = (data as { childId?: unknown } | undefined)?.childId;
  if (typeof childId !== "string" || !childId) throw new HttpsError("invalid-argument", "childId is required", { field: "childId" });
  const child = await db.doc(`children/${childId}`).get();
  if (!child.exists || child.get("merged") != null) throw new HttpsError("not-found", "Child not found.");
  return child;
}

/**
 * Links a number's unlinked children to the guardian account on that number, after staff checked
 * the guardian in person (009 FR-008, 001 FR-021a), and clears the linking lock.
 * contracts/callables.md#stafflinkchildren
 */
export const staffLinkChildren = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const child = await openChild(request.data);
  if (child.get("guardianUid") != null) refuse("already_linked", "The child is already linked.");
  const phone = child.get("guardianPhone") as string;

  const linked = await db.runTransaction(async (tx) => {
    const account = await tx.get(db.collection("guardians").where("phone", "==", phone).limit(1));
    if (account.empty) refuse("no_account", "No app account on this number.");
    const uid = account.docs[0].id;
    const children = await tx.get(db.collection("children").where("guardianPhone", "==", phone).where("guardianUid", "==", null));
    const now = FieldValue.serverTimestamp();
    for (const c of children.docs) tx.update(c.ref, { guardianUid: uid, updatedAt: now, updatedBy: staff.uid });
    tx.update(account.docs[0].ref, { clinicChildrenPending: false });
    tx.delete(db.doc(`linkAttempts/${phone}`));
    await writeAudit(
      { action: "children.linked_by_staff", actorUid: staff.uid, subjectPhone: phone, childIds: children.docs.map((c) => c.id) },
      tx,
    );
    return children.docs.map((c) => ({ childId: c.id, name: c.get("name") as string }));
  });
  return { linked };
});

/** Lifts a guardian's re-verification lock (009 FR-008a, 001). contracts/callables.md#unlockreverify */
export const unlockReverify = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const child = await openChild(request.data);
  const uid = child.get("guardianUid") as string | null;
  const ref = db.doc(`reverifyAttempts/${uid ?? "-"}`);
  await db.runTransaction(async (tx) => {
    const attempts = uid ? await tx.get(ref) : null;
    if (!attempts?.exists || attempts.get("lockedAt") == null) refuse("not_locked", "The guardian is not locked.");
    tx.delete(ref);
    await writeAudit({ action: "account.reverify_unlocked_by_staff", actorUid: staff.uid, subjectPhone: child.get("guardianPhone") }, tx);
  });
  return { ok: true };
});
