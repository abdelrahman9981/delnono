import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../lib/admin";
import { writeAudit } from "../lib/audit";
import { REGION } from "../lib/region";
import { getAuthSettings } from "../lib/settings";

const DATE = /^\d{4}-\d{2}-\d{2}$/;

type Outcome = { kind: "ok" } | { kind: "wrong"; remaining: number } | { kind: "locked" };

/**
 * Birth-date re-check after inactivity (FR-010a, FR-010b): a match with one linked child refreshes
 * `lastActiveAt`; `maxLinkAttempts` wrong dates lock child data until staff unlock (004). Outcomes
 * commit before errors are thrown, so failures and the lock are recorded.
 * contracts/callables.md#reverifyguardian
 */
export const reverifyGuardian = onCall({ region: REGION }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign-in is required.");
  const uid = request.auth.uid;
  const birthDate = (request.data as { birthDate?: unknown } | undefined)?.birthDate;
  if (typeof birthDate !== "string" || !DATE.test(birthDate)) {
    throw new HttpsError("invalid-argument", "birthDate: YYYY-MM-DD", { field: "birthDate" });
  }
  const { maxLinkAttempts } = await getAuthSettings();
  const guardianRef = db.doc(`guardians/${uid}`);
  const attemptsRef = db.doc(`reverifyAttempts/${uid}`);

  const outcome = await db.runTransaction<Outcome>(async (tx) => {
    const guardian = await tx.get(guardianRef);
    if (!guardian.exists) throw new HttpsError("not-found", "Guardian is not registered.");
    const phone = guardian.get("phone") as string;
    const attempts = await tx.get(attemptsRef);
    if (attempts.get("lockedAt") != null) return { kind: "locked" };
    const children = await tx.get(db.collection("children").where("guardianUid", "==", uid));

    if (children.docs.some((c) => c.get("birthDate") === birthDate)) {
      tx.update(guardianRef, { lastActiveAt: FieldValue.serverTimestamp() });
      tx.delete(attemptsRef);
      await writeAudit({ action: "account.reverified", actorUid: uid, subjectPhone: phone }, tx);
      return { kind: "ok" };
    }

    const failed = ((attempts.get("failedCount") as number | undefined) ?? 0) + 1;
    await writeAudit({ action: "account.reverify_failed", actorUid: uid, subjectPhone: phone, details: { failed } }, tx);
    if (failed >= maxLinkAttempts) {
      tx.set(attemptsRef, { failedCount: failed, lockedAt: FieldValue.serverTimestamp() });
      await writeAudit({ action: "account.reverify_locked", actorUid: uid, subjectPhone: phone }, tx);
      return { kind: "locked" };
    }
    tx.set(attemptsRef, { failedCount: failed, lockedAt: null });
    return { kind: "wrong", remaining: maxLinkAttempts - failed };
  });

  switch (outcome.kind) {
    case "ok":
      return {};
    case "wrong":
      throw new HttpsError("permission-denied", "Birth date does not match.", { remaining: outcome.remaining });
    case "locked":
      throw new HttpsError("resource-exhausted", "Locked; contact the clinic.");
  }
});
