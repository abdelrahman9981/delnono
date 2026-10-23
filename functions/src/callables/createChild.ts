import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../lib/admin";
import { requireGuardianWithCurrentConsent, requirePhoneUser } from "../lib/guards";
import { nameKey } from "../lib/nameKey";
import { REGION } from "../lib/region";
import { validateChild } from "../lib/validation";

/**
 * Adds a child after the duplicate check on the caller's number (FR-018, FR-022). Runs on the
 * server because the check must see unlinked children the guardian cannot read.
 * contracts/callables.md#createchild
 */
export const createChild = onCall({ region: REGION }, async (request) => {
  const { uid, phone } = requirePhoneUser(request);
  await requireGuardianWithCurrentConsent(uid);
  const child = validateChild((request.data ?? {}) as Record<string, unknown>);
  const key = nameKey(child.name);

  const childId = await db.runTransaction(async (tx) => {
    const existing = await tx.get(
      db
        .collection("children")
        .where("guardianPhone", "==", phone)
        .where("nameKey", "==", key)
        .where("birthDate", "==", child.birthDate)
        .limit(1),
    );
    if (!existing.empty) {
      throw new HttpsError("already-exists", "A child with this name and birth date is already on this number.", {
        existingLinked: existing.docs[0].get("guardianUid") === uid,
      });
    }

    const ref = db.collection("children").doc();
    const now = FieldValue.serverTimestamp();
    tx.set(ref, {
      ...child,
      nameKey: key,
      guardianPhone: phone,
      guardianUid: uid,
      registeredBy: "guardian",
      createdAt: now,
      updatedAt: now,
      updatedBy: uid,
    });
    return ref.id;
  });

  return { childId };
});
