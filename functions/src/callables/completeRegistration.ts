import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../lib/admin";
import { writeAudit } from "../lib/audit";
import { validateConsent } from "../lib/consent";
import { requirePhoneUser } from "../lib/guards";
import { REGION } from "../lib/region";
import { getPolicySettings } from "../lib/settings";
import { validateGuardian } from "../lib/validation";

/**
 * Writes the guardian and their first consent together, so no guardian data exists without consent
 * (FR-012 to FR-016). contracts/callables.md#completeregistration
 */
export const completeRegistration = onCall({ region: REGION }, async (request) => {
  const { uid, phone } = requirePhoneUser(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const guardian = validateGuardian(data);
  const policy = await getPolicySettings();
  const consent = validateConsent(data.consent, policy.currentVersion);

  const guardianRef = db.doc(`guardians/${uid}`);
  const consentRef = guardianRef.collection("consents").doc();

  const hasClinicChildren = await db.runTransaction(async (tx) => {
    if ((await tx.get(guardianRef)).exists) {
      throw new HttpsError("already-exists", "Guardian is already registered.");
    }
    // Any child on this number without an app account, whoever registered it (FR-021).
    const unlinked = await tx.get(
      db.collection("children").where("guardianPhone", "==", phone).where("guardianUid", "==", null).limit(1),
    );
    const locked = (await tx.get(db.doc(`linkAttempts/${phone}`))).get("lockedAt") != null;
    const pending = !unlinked.empty && !locked;

    const now = FieldValue.serverTimestamp();
    tx.set(guardianRef, {
      phone,
      ...guardian,
      consentVersion: consent.policyVersion,
      clinicChildrenPending: pending,
      lastActiveAt: now,
      createdAt: now,
      updatedAt: now,
    });
    tx.set(consentRef, { policyVersion: consent.policyVersion, scopes: consent.scopes, acceptedAt: now });
    await writeAudit({ action: "account.created", actorUid: uid, subjectPhone: phone }, tx);
    await writeAudit(
      { action: "consent.accepted", actorUid: uid, subjectPhone: phone, details: { policyVersion: consent.policyVersion } },
      tx,
    );
    return !unlinked.empty;
  });

  return { hasClinicChildren };
});
