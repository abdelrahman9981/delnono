import { HttpsError } from "firebase-functions/https";

/** Constraints quote data-model.md. Each failure names the field in `details.field`. */

function fail(field: string, rule: string): never {
  throw new HttpsError("invalid-argument", `${field}: ${rule}`, { field });
}

const length = (s: string) => [...s].length;

function text(data: Record<string, unknown>, field: string, min: number, max: number, rule: string): string {
  const value = data[field];
  if (typeof value !== "string") fail(field, rule);
  const trimmed = value.trim();
  if (length(trimmed) < min || length(trimmed) > max) fail(field, rule);
  return trimmed;
}

function optionalText(data: Record<string, unknown>, field: string, max: number, rule: string): string | undefined {
  const value = data[field];
  if (value === undefined || value === null || value === "") return undefined;
  if (typeof value !== "string" || length(value.trim()) > max) fail(field, rule);
  return value.trim() || undefined;
}

function oneOf<T extends string>(data: Record<string, unknown>, field: string, values: readonly T[], rule: string): T {
  const value = data[field];
  if (typeof value !== "string" || !values.includes(value as T)) fail(field, rule);
  return value as T;
}

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export const RELATIONS = ["mother", "father", "other"] as const;
export type Relation = (typeof RELATIONS)[number];

export interface GuardianInput {
  fullName: string;
  relation: Relation;
  email?: string;
}

export function validateGuardian(data: Record<string, unknown>): GuardianInput {
  const fullName = text(data, "fullName", 2, 80, "required, 2–80 chars");
  const relation = oneOf(data, "relation", RELATIONS, "`mother` | `father` | `other`");
  const email = optionalText(data, "email", 254, "optional, valid email if present");
  if (email !== undefined && !EMAIL.test(email)) fail("email", "optional, valid email if present");
  return { fullName, relation, ...(email ? { email } : {}) };
}

export const SEXES = ["male", "female"] as const;
export type Sex = (typeof SEXES)[number];

export interface ChildInput {
  name: string;
  birthDate: string;
  sex: Sex;
  birthWeightKg?: number;
  allergies?: string;
}

/** Today's date in Cairo as `YYYY-MM-DD`, so a birth "today" in Egypt is never "in the future". */
export function cairoToday(now: Date = new Date()): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: "Africa/Cairo" }).format(now);
}

const DATE = /^(\d{4})-(\d{2})-(\d{2})$/;

/** `birthDate`: "required, not in future, within 18 years" (format `YYYY-MM-DD`). */
export function validateBirthDate(value: unknown, now: Date = new Date()): string {
  const rule = "required, not in future, within 18 years";
  const m = typeof value === "string" ? DATE.exec(value) : null;
  if (!m) fail("birthDate", rule);
  const [y, mo, d] = [Number(m[1]), Number(m[2]), Number(m[3])];
  const parsed = new Date(Date.UTC(y, mo - 1, d));
  if (parsed.getUTCFullYear() !== y || parsed.getUTCMonth() !== mo - 1 || parsed.getUTCDate() !== d) {
    fail("birthDate", rule);
  }
  const today = cairoToday(now);
  const [ty, tm, td] = today.split("-").map(Number);
  const earliest = `${String(ty - 18).padStart(4, "0")}-${String(tm).padStart(2, "0")}-${String(td).padStart(2, "0")}`;
  const date = m[0];
  if (date > today || date < earliest) fail("birthDate", rule);
  return date;
}

export function validateChild(data: Record<string, unknown>, now: Date = new Date()): ChildInput {
  const name = text(data, "name", 2, 60, "required, 2–60 chars");
  const birthDate = validateBirthDate(data.birthDate, now);
  const sex = oneOf(data, "sex", SEXES, "`male` | `female`");

  let birthWeightKg: number | undefined;
  if (data.birthWeightKg !== undefined && data.birthWeightKg !== null) {
    const w = data.birthWeightKg;
    if (typeof w !== "number" || !Number.isFinite(w) || w < 0.3 || w > 7.0) fail("birthWeightKg", "0.3–7.0");
    birthWeightKg = w;
  }
  const allergies = optionalText(data, "allergies", 500, "≤ 500 chars");

  return {
    name,
    birthDate,
    sex,
    ...(birthWeightKg !== undefined ? { birthWeightKg } : {}),
    ...(allergies ? { allergies } : {}),
  };
}
