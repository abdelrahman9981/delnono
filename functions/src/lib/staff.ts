import { HttpsError, type CallableRequest } from "firebase-functions/https";
import { db } from "./admin";

export type StaffRole = "doctor" | "secretary";

export interface Staff {
  uid: string;
  role: StaffRole;
  /** The secretary's clinic; null for the doctor (all clinics). */
  clinicId: string | null;
  name: string;
}

/**
 * The caller must be an active staff member (005 research R2): a role claim and an active
 * `staff/{uid}` document, so disabling takes effect at once. [doctor] limits to the doctor.
 */
export async function requireStaff(request: CallableRequest, opts: { doctor?: boolean } = {}): Promise<Staff> {
  const role = request.auth?.token.role;
  if (!request.auth || (role !== "doctor" && role !== "secretary")) {
    throw new HttpsError("permission-denied", "Staff only.");
  }
  const snap = await db.doc(`staff/${request.auth.uid}`).get();
  if (!snap.exists || snap.get("active") !== true || snap.get("role") !== role) {
    throw new HttpsError("permission-denied", "This staff account is not active.");
  }
  if (opts.doctor && role !== "doctor") throw new HttpsError("permission-denied", "Doctor only.");
  return {
    uid: request.auth.uid,
    role,
    clinicId: (snap.get("clinicId") as string | null) ?? null,
    name: (snap.get("name") as string) ?? "",
  };
}

/** A secretary may act only for her clinic (D-47); the doctor for any. */
export function requireClinic(staff: Staff, clinicId: unknown): string {
  if (typeof clinicId !== "string" || !clinicId) throw new HttpsError("invalid-argument", "clinicId is required", { field: "clinicId" });
  if (staff.role === "secretary" && staff.clinicId !== clinicId) {
    throw new HttpsError("permission-denied", "Another clinic.", { reason: "other_clinic" });
  }
  return clinicId;
}

export function str(data: Record<string, unknown>, field: string, opts: { optional?: boolean; max?: number } = {}): string {
  const v = data[field];
  if (v == null || v === "") {
    if (opts.optional) return "";
    throw new HttpsError("invalid-argument", `${field} is required`, { field });
  }
  if (typeof v !== "string" || v.length > (opts.max ?? 500)) throw new HttpsError("invalid-argument", `${field}: text`, { field });
  return v.trim();
}

export function num(data: Record<string, unknown>, field: string, opts: { optional?: boolean; min?: number; max?: number } = {}): number | null {
  const v = data[field];
  if (v == null) {
    if (opts.optional) return null;
    throw new HttpsError("invalid-argument", `${field} is required`, { field });
  }
  if (typeof v !== "number" || Number.isNaN(v) || v < (opts.min ?? -Infinity) || v > (opts.max ?? Infinity)) {
    throw new HttpsError("invalid-argument", `${field}: number`, { field });
  }
  return v;
}
