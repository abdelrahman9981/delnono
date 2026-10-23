import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../lib/admin";
import { writeAudit } from "../lib/audit";
import { validateConsent } from "../lib/consent";
import { requirePhoneUser } from "../lib/guards";
import { REGION } from "../lib/region";
import { getPolicySettings } from "../lib/settings";

/** Records consent to a new policy version (FR-017). contracts/callables.md#acceptpolicy */
export const acceptPolicy = onCall({ region: REGION }, async (request) => {
  const { uid, phone } = requirePhoneUser(request);
  const policy = await getPolicySettings();
  const consent = validateConsent(request.data, policy.currentVersion);

  const guardianRef = db.doc(`guardians/${uid}`);
  await db.runTransaction(async (tx) => {
    if (!(await tx.get(guardianRef)).exists) throw new HttpsError("not-found", "Guardian is not registered.");
    const now = FieldValue.serverTimestamp();
    tx.update(guardianRef, { consentVersion: consent.policyVersion, updatedAt: now });
    tx.set(guardianRef.collection("consents").doc(), {
      policyVersion: consent.policyVersion,
      scopes: consent.scopes,
      acceptedAt: now,
    });
    await writeAudit(
      { action: "consent.accepted", actorUid: uid, subjectPhone: phone, details: { policyVersion: consent.policyVersion } },
      tx,
    );
  });
  return {};
});
