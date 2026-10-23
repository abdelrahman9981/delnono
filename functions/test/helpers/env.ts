import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { initializeTestEnvironment, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { getApps, initializeApp, type App } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, type Firestore } from "firebase-admin/firestore";
import { setLogLevel } from "firebase/firestore";

/**
 * Shared test setup. Run through `npm test`, which starts the Auth, Firestore and Functions
 * emulators with `firebase emulators:exec` and sets FIRESTORE_EMULATOR_HOST and
 * FIREBASE_AUTH_EMULATOR_HOST for this process.
 */
export const PROJECT_ID = "demo-delnono";
export const FUNCTIONS_HOST = "127.0.0.1:5001";
/** Until research R8 fixes the region, the emulator serves callables in the default region. */
export const DEFAULT_REGION = "us-central1";

function emulatorHost(variable: string): string {
  const host = process.env[variable];
  if (!host) throw new Error(`${variable} is not set. Run the tests with \`npm test\`.`);
  return host;
}

// ---- Security Rules ----

export async function rulesEnv(): Promise<RulesTestEnvironment> {
  // Denied requests are the expected outcome in most rules tests; keep their SDK warnings out of the output.
  setLogLevel("error");
  return initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: { rules: readFileSync(resolve(__dirname, "../../../firestore.rules"), "utf8") },
  });
}

// ---- Admin access to the emulators (bypasses rules) ----

function adminApp(): App {
  return getApps().find((a) => a.name === "test") ?? initializeApp({ projectId: PROJECT_ID }, "test");
}

export function adminDb(): Firestore {
  return getFirestore(adminApp());
}

/** Deletes all Firestore documents and Auth users in the emulators. */
export async function clearEmulators(): Promise<void> {
  const firestore = emulatorHost("FIRESTORE_EMULATOR_HOST");
  const auth = emulatorHost("FIREBASE_AUTH_EMULATOR_HOST");
  await Promise.all([
    fetch(`http://${firestore}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`, {
      method: "DELETE",
    }),
    fetch(`http://${auth}/emulator/v1/projects/${PROJECT_ID}/accounts`, { method: "DELETE" }),
  ]);
}

// ---- Seed data ----

export const DEFAULT_POLICY_VERSION = 1;

export async function seedSettings(overrides: { auth?: object; policy?: object; clinic?: object } = {}) {
  const db = adminDb();
  await Promise.all([
    db.doc("settings/auth").set({
      codeValiditySeconds: 300,
      maxCodeAttempts: 5,
      resendWaitSeconds: 60,
      dailySmsCapPerNumber: 5,
      maxLinkAttempts: 3,
      reverifyAfterDays: 90,
      ...overrides.auth,
    }),
    db.doc("settings/policy").set({
      currentVersion: DEFAULT_POLICY_VERSION,
      privacyPolicyText: "[نص مؤقت]",
      termsText: "[نص مؤقت]",
      ...overrides.policy,
    }),
    db.doc("settings/clinic").set({ whatsappNumber: "+201000000000", ...overrides.clinic }),
  ]);
}

export async function seedGuardian(uid: string, data: Record<string, unknown> = {}) {
  await adminDb()
    .doc(`guardians/${uid}`)
    .set({
      phone: "+201000000099",
      fullName: "ولي أمر تجريبي",
      relation: "mother",
      consentVersion: DEFAULT_POLICY_VERSION,
      clinicChildrenPending: false,
      lastActiveAt: new Date(),
      ...data,
    });
}

export async function seedClinicGuardian(phone: string, data: Record<string, unknown> = {}) {
  await adminDb()
    .doc(`clinicGuardians/${phone}`)
    .set({ fullName: "ولي أمر العيادة", relation: "mother", createdAt: new Date(), ...data });
}

export async function seedChild(id: string, data: Record<string, unknown> = {}) {
  await adminDb()
    .doc(`children/${id}`)
    .set({
      name: "طفل تجريبي",
      nameKey: "طفل تجريبي",
      birthDate: "2024-03-15",
      sex: "male",
      guardianPhone: "+201000000099",
      guardianUid: null,
      registeredBy: "clinic",
      createdAt: new Date(),
      ...data,
    });
}

// ---- Calling callables as a phone user ----

export interface PhoneSession {
  uid: string;
  phone: string;
  idToken: string;
}

/** Creates (or reuses) an Auth emulator user with [phone] and returns an ID token for it. */
export async function signInAsPhoneUser(phone: string, uid = `u${phone.replace(/\D/g, "")}`): Promise<PhoneSession> {
  const auth = getAuth(adminApp());
  try {
    await auth.createUser({ uid, phoneNumber: phone });
  } catch (e) {
    if ((e as { code?: string }).code !== "auth/uid-already-exists") throw e;
  }
  const token = await auth.createCustomToken(uid);
  const host = emulatorHost("FIREBASE_AUTH_EMULATOR_HOST");
  const res = await fetch(
    `http://${host}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo-api-key`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ token, returnSecureToken: true }),
    },
  );
  const body = (await res.json()) as { idToken?: string; error?: unknown };
  if (!body.idToken) throw new Error(`Sign-in failed: ${JSON.stringify(body.error)}`);
  return { uid, phone, idToken: body.idToken };
}

export interface CallableResult<T> {
  result?: T;
  error?: { status: string; message: string; details?: Record<string, unknown> };
}

/** Calls a callable through the Functions emulator, as the browser and mobile SDKs do. */
export async function callFunction<T = unknown>(
  name: string,
  data: unknown,
  session?: PhoneSession,
  region = DEFAULT_REGION,
): Promise<CallableResult<T>> {
  const res = await fetch(`http://${FUNCTIONS_HOST}/${PROJECT_ID}/${region}/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(session ? { Authorization: `Bearer ${session.idToken}` } : {}),
    },
    body: JSON.stringify({ data }),
  });
  return (await res.json()) as CallableResult<T>;
}

/** Reads the claims of an ID token without verifying it (emulator tokens are unsigned). */
export function tokenClaims(idToken: string): Record<string, unknown> {
  return JSON.parse(Buffer.from(idToken.split(".")[1], "base64url").toString("utf8"));
}
