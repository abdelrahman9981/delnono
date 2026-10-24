import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { adminDb, PROJECT_ID, type PhoneSession } from "./env";

export type Role = "doctor" | "secretary";

/**
 * A staff member: Auth user with role and clinic claims, an active `staff/{uid}` document, and an
 * ID token carrying the claims (005 research R2).
 */
export async function signInAsStaff(uid: string, role: Role, clinicId: string | null = null, active = true): Promise<PhoneSession> {
  const app = getApps().find((a) => a.name === "test") ?? initializeApp({ projectId: PROJECT_ID }, "test");
  const auth = getAuth(app);
  try {
    await auth.createUser({ uid, email: `${uid}@demo.delnono`, password: "Delnono-2026" });
  } catch (e) {
    if ((e as { code?: string }).code !== "auth/uid-already-exists") throw e;
  }
  await auth.setCustomUserClaims(uid, { role, clinicId });
  await adminDb().doc(`staff/${uid}`).set({ name: `[${uid}]`, email: `${uid}@demo.delnono`, role, clinicId, active, mustChangePassword: false });
  const token = await auth.createCustomToken(uid, { role, clinicId });
  const host = process.env.FIREBASE_AUTH_EMULATOR_HOST;
  const res = await fetch(`http://${host}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo-api-key`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ token, returnSecureToken: true }),
  });
  const body = (await res.json()) as { idToken?: string; error?: unknown };
  if (!body.idToken) throw new Error(`Staff sign-in failed: ${JSON.stringify(body.error)}`);
  return { uid, phone: "", idToken: body.idToken };
}

export const doctor = () => signInAsStaff("doc", "doctor");
export const secretary1 = () => signInAsStaff("sec1", "secretary", "clinic-1");
export const secretary2 = () => signInAsStaff("sec2", "secretary", "clinic-2");
