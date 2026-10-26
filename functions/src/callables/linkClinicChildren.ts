import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../lib/admin";
import { writeAudit } from "../lib/audit";
import { requireGuardianWithCurrentConsent, requirePhoneUser } from "../lib/guards";
import { nameKey } from "../lib/nameKey";
import { REGION } from "../lib/region";
import { getAuthSettings } from "../lib/settings";

const DATE = /^\d{4}-\d{2}-\d{2}$/;

type Outcome =
  | { kind: "linked"; linked: { childId: string; name: string; duplicate: boolean }[] }
  | { kind: "wrong"; remaining: number }
  | { kind: "locked" }
  | { kind: "none" };

/**
 * Links the unlinked children on the caller's number after the guardian gives the birth date of
 * one of them (FR-021). After `maxLinkAttempts` wrong dates linking is locked until staff link the
 * children (FR-021a). Outcomes are committed first and errors thrown after, so failed attempts and
 * the lock are recorded. contracts/callables.md#linkclinicchildren
 */
export const linkClinicChildren = onCall({ region: REGION }, async (request) => {
  const { uid, phone } = requirePhoneUser(request);
  await requireGuardianWithCurrentConsent(uid);
  const birthDate = (request.data as { birthDate?: unknown } | undefined)?.birthDate;
  if (typeof birthDate !== "string" || !DATE.test(birthDate)) {
    throw new HttpsError("invalid-argument", "birthDate: YYYY-MM-DD", { field: "birthDate" });
  }
  const { maxLinkAttempts } = await getAuthSettings();

  const guardianRef = db.doc(`guardians/${uid}`);
  const attemptsRef = db.doc(`linkAttempts/${phone}`);

  const outcome = await db.runTransaction<Outcome>(async (tx) => {
    const attempts = await tx.get(attemptsRef);
    const children = await tx.get(
      db.collection("children").where("guardianPhone", "==", phone).where("guardianUid", "==", null),
    );
    // Children the guardian already added in the app: one with the same name and birth date as a
    // clinic child is probably the same child (FR-022), so the app warns and staff merge (FR-065).
    const own = await tx.get(db.collection("children").where("guardianUid", "==", uid));
    const key = (c: FirebaseFirestore.DocumentSnapshot) => `${nameKey(String(c.get("name") ?? ""))}|${c.get("birthDate")}`;
    const ownKeys = new Set(own.docs.map(key));
    const now = FieldValue.serverTimestamp();

    if (attempts.get("lockedAt") != null) {
      tx.update(guardianRef, { clinicChildrenPending: false });
      return { kind: "locked" };
    }
    if (children.empty) {
      tx.update(guardianRef, { clinicChildrenPending: false });
      return { kind: "none" };
    }

    if (children.docs.some((c) => c.get("birthDate") === birthDate)) {
      for (const c of children.docs) {
        tx.update(c.ref, { guardianUid: uid, updatedAt: now, updatedBy: uid });
      }
      tx.update(guardianRef, { clinicChildrenPending: false, lastActiveAt: now });
      tx.delete(attemptsRef);
      await writeAudit(
        { action: "children.linked", actorUid: uid, subjectPhone: phone, childIds: children.docs.map((c) => c.id) },
        tx,
      );
      return {
        kind: "linked",
        linked: children.docs.map((c) => ({
          childId: c.id,
          name: c.get("name") as string,
          duplicate: ownKeys.has(key(c)),
        })),
      };
    }

    const failed = ((attempts.get("failedCount") as number | undefined) ?? 0) + 1;
    await writeAudit({ action: "children.link_failed", actorUid: uid, subjectPhone: phone, details: { failed } }, tx);
    if (failed >= maxLinkAttempts) {
      tx.set(attemptsRef, { failedCount: failed, lockedAt: now });
      tx.update(guardianRef, { clinicChildrenPending: false });
      await writeAudit({ action: "children.link_locked", actorUid: uid, subjectPhone: phone }, tx);
      return { kind: "locked" };
    }
    tx.set(attemptsRef, { failedCount: failed, lockedAt: null });
    return { kind: "wrong", remaining: maxLinkAttempts - failed };
  });

  switch (outcome.kind) {
    case "linked":
      return { linked: outcome.linked };
    case "wrong":
      throw new HttpsError("permission-denied", "Birth date does not match.", { remaining: outcome.remaining });
    case "locked":
      throw new HttpsError("resource-exhausted", "Linking is locked; contact the clinic.");
    case "none":
      throw new HttpsError("not-found", "No unlinked children on this number.");
  }
});
