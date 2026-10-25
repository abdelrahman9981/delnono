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
