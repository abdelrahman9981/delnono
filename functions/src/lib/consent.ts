import { HttpsError } from "firebase-functions/https";

/** Every consent must cover all three (FR-014). */
export const REQUIRED_SCOPES = ["privacy_policy", "terms", "child_data"] as const;

export interface ConsentInput {
  policyVersion: number;
  scopes: string[];
}

/** The consent must name the current policy version and all required scopes. */
export function validateConsent(value: unknown, currentVersion: number): ConsentInput {
  const c = value as Partial<ConsentInput> | undefined;
  if (!c || typeof c.policyVersion !== "number" || !Array.isArray(c.scopes)) {
    throw new HttpsError("invalid-argument", "consent: policyVersion and scopes are required", { field: "consent" });
  }
  if (c.policyVersion !== currentVersion) {
    throw new HttpsError("failed-precondition", "consent: policy version is not current", { field: "policyVersion" });
  }
  const missing = REQUIRED_SCOPES.filter((s) => !c.scopes!.includes(s));
  if (missing.length > 0) {
    throw new HttpsError("failed-precondition", `consent: missing ${missing.join(", ")}`, { field: "scopes" });
  }
  return { policyVersion: c.policyVersion, scopes: [...REQUIRED_SCOPES] };
}
