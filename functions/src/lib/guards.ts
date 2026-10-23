import { HttpsError, type CallableRequest } from "firebase-functions/https";
import { db } from "./admin";
import { getPolicySettings } from "./settings";

export interface PhoneUser {
  uid: string;
  phone: string;
}

/** The caller must be signed in with a verified phone number. */
export function requirePhoneUser(request: CallableRequest): PhoneUser {
  const phone = request.auth?.token.phone_number;
  if (!request.auth || typeof phone !== "string") {
    throw new HttpsError("unauthenticated", "Sign-in with a verified phone number is required.");
  }
  return { uid: request.auth.uid, phone };
}

/** The caller's guardian doc must exist with the current policy version accepted. */
export async function requireGuardianWithCurrentConsent(uid: string): Promise<FirebaseFirestore.DocumentData> {
  const [guardian, policy] = await Promise.all([db.doc(`guardians/${uid}`).get(), getPolicySettings()]);
  const data = guardian.data();
  if (!data || data.consentVersion !== policy.currentVersion) {
    throw new HttpsError("failed-precondition", "Registration and current consent are required.");
  }
  return data;
}
