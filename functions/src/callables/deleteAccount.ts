import { getAuth } from "firebase-admin/auth";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../lib/admin";
import { writeAudit } from "../lib/audit";
import { slotId } from "../lib/booking/time";
import { REGION } from "../lib/region";

/**
 * Deletes the app account (FR-027 to FR-030). Children stay with the clinic, unlinked but still on
 * the guardian's number; consents are kept in `deletedGuardians` as evidence for the retained
 * record. Firestore changes commit together first; the Auth user is removed last, so a retry after
 * a partial failure finishes the remaining steps and audits only once.
 * contracts/callables.md#deleteaccount
 */
export const deleteAccount = onCall({ region: REGION }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign-in is required.");
  if ((request.data as { confirm?: unknown } | undefined)?.confirm !== true) {
    throw new HttpsError("invalid-argument", "confirm: true is required", { field: "confirm" });
  }
  const uid = request.auth.uid;
  const guardianRef = db.doc(`guardians/${uid}`);
  const archiveRef = db.doc(`deletedGuardians/${uid}`);

  await db.runTransaction(async (tx) => {
    const guardian = await tx.get(guardianRef);
    if (!guardian.exists) return; // Already done on an earlier attempt.
    const consents = await tx.get(guardianRef.collection("consents"));
    const children = await tx.get(db.collection("children").where("guardianUid", "==", uid));
    // Upcoming bookings are cancelled and their places freed (002 research R9).
    const upcoming = await tx.get(
      db.collection("bookings").where("guardianUid", "==", uid).where("status", "==", "confirmed").where("startsAt", ">", Timestamp.now()),
    );
    const slots = await Promise.all(upcoming.docs.map((b) => tx.get(db.doc(`slots/${slotId(b.get("date"), b.get("hour"))}`))));
    const phone = guardian.get("phone") as string;
    const now = FieldValue.serverTimestamp();

    tx.set(archiveRef, { phone, deletedAt: now });
    for (const c of consents.docs) {
      tx.set(archiveRef.collection("consents").doc(c.id), c.data());
      tx.delete(c.ref);
    }
    for (const child of children.docs) {
      tx.update(child.ref, { guardianUid: null, updatedAt: now });
    }
    upcoming.docs.forEach((b, i) => {
      tx.update(b.ref, { status: "cancelled", cancelledAt: now, cancelledBy: uid, updatedAt: now });
      tx.set(b.ref.collection("events").doc(), { type: "cancelled", by: uid, at: now, reason: "account_deleted" });
      tx.set(slots[i].ref, { taken: Math.max(0, ((slots[i].get("taken") as number | undefined) ?? 1) - 1) }, { merge: true });
    });
    tx.delete(db.doc(`familyQuota/${uid}`));
    tx.delete(guardianRef);
    await writeAudit(
      {
        action: "account.deleted",
        actorUid: uid,
        subjectPhone: phone,
        childIds: children.docs.map((c) => c.id),
        details: { cancelledBookings: upcoming.docs.map((b) => b.id) },
      },
      tx,
    );
  });

  const auth = getAuth();
  try {
    await auth.revokeRefreshTokens(uid);
    await auth.deleteUser(uid);
  } catch (e) {
    if ((e as { code?: string }).code !== "auth/user-not-found") throw e;
  }
  return {};
});
