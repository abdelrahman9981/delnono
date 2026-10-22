import { db } from "./admin";

/** `settings/auth` with the same defaults as the app (lib/core/settings/settings_repository.dart). */
export interface AuthSettings {
  codeValiditySeconds: number;
  maxCodeAttempts: number;
  resendWaitSeconds: number;
  dailySmsCapPerNumber: number;
  maxLinkAttempts: number;
  reverifyAfterDays: number;
}

export const AUTH_DEFAULTS: AuthSettings = {
  codeValiditySeconds: 300,
  maxCodeAttempts: 5,
  resendWaitSeconds: 60,
  dailySmsCapPerNumber: 5,
  maxLinkAttempts: 3,
  reverifyAfterDays: 90,
};

/** `settings/policy`. */
export interface PolicySettings {
  currentVersion: number;
}

export const POLICY_DEFAULTS: PolicySettings = { currentVersion: 1 };

function withDefaults<T extends object>(defaults: T, data: Record<string, unknown> | undefined): T {
  const out = { ...defaults };
  for (const key of Object.keys(defaults) as (keyof T)[]) {
    const value = data?.[key as string];
    if (typeof value === "number") out[key] = value as T[keyof T];
  }
  return out;
}

export async function getAuthSettings(): Promise<AuthSettings> {
  const snap = await db.doc("settings/auth").get();
  return withDefaults(AUTH_DEFAULTS, snap.data());
}

export async function getPolicySettings(): Promise<PolicySettings> {
  const snap = await db.doc("settings/policy").get();
  return withDefaults(POLICY_DEFAULTS, snap.data());
}
