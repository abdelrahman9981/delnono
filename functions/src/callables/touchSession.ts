import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../lib/admin";
import { REGION } from "../lib/region";
import { getAuthSettings } from "../lib/settings";

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Called on app start (FR-010a). Refreshes `lastActiveAt` (at most once a day) while the guardian is
 * active, or has no linked children to protect; otherwise reports that a birth-date re-check is
 * needed and changes nothing. contracts/callables.md#touchsession
 */
export const touchSession = onCall({ region: REGION }, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign-in is required.");
  const uid = request.auth.uid;
  const guardianRef = db.doc(`guardians/${uid}`);
  const [guardian, settings, linked] = await Promise.all([
    guardianRef.get(),
    getAuthSettings(),
    db.collection("children").where("guardianUid", "==", uid).limit(1).get(),
  ]);
  if (!guardian.exists) return { reverifyRequired: false };

  const last = (guardian.get("lastActiveAt") as Timestamp | undefined)?.toMillis() ?? 0;
  const age = Date.now() - last;
  if (!linked.empty && age > settings.reverifyAfterDays * DAY_MS) return { reverifyRequired: true };

  if (age > DAY_MS) await guardianRef.update({ lastActiveAt: FieldValue.serverTimestamp() });
  return { reverifyRequired: false };
});
