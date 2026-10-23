import { getAuth } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../lib/admin";
import { writeAudit } from "../lib/audit";
import { REGION } from "../lib/region";

/**
 * Copies the number from the Auth record to the guardian and their linked children after the app
 * changed it with `updatePhoneNumber` (FR-025, FR-026). Conflicts never reach here: Auth refuses a
 * number that belongs to another account (FR-025a). contracts/callables.md#syncphonenumber
 */
export const syncPhoneNumber = onCall({ region: REGION }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign-in is required.");
  const uid = request.auth.uid;
  const phone = (await getAuth().getUser(uid)).phoneNumber;
  if (!phone) throw new HttpsError("failed-precondition", "The account has no phone number.");

  const guardianRef = db.doc(`guardians/${uid}`);
  await db.runTransaction(async (tx) => {
    const guardian = await tx.get(guardianRef);
    if (!guardian.exists) throw new HttpsError("not-found", "Guardian is not registered.");
    const oldPhone = guardian.get("phone") as string;
    if (oldPhone === phone) return;

    const linked = await tx.get(db.collection("children").where("guardianUid", "==", uid));
    const unlinkedOnNew = await tx.get(
      db.collection("children").where("guardianPhone", "==", phone).where("guardianUid", "==", null).limit(1),
    );
    const locked = (await tx.get(db.doc(`linkAttempts/${phone}`))).get("lockedAt") != null;

    const now = FieldValue.serverTimestamp();
    for (const c of linked.docs) tx.update(c.ref, { guardianPhone: phone, updatedAt: now });
    tx.update(guardianRef, {
      phone,
      clinicChildrenPending: !unlinkedOnNew.empty && !locked,
      updatedAt: now,
    });
    await writeAudit(
      {
        action: "phone.changed",
        actorUid: uid,
        subjectPhone: phone,
        childIds: linked.docs.map((c) => c.id),
        details: { from: oldPhone, to: phone },
      },
      tx,
    );
  });

  return { phone };
});
