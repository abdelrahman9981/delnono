import { getAuth } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../../lib/admin";
import { writeAudit } from "../../lib/audit";
import { REGION } from "../../lib/region";
import { requireStaff, str } from "../../lib/staff";

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Staff accounts, by the doctor only (D-12, 005 research R2): create with a temporary password the
 * person must change, update name, role and clinic, disable or enable. Claims carry the role and the
 * secretary's clinic. There is always at least one active doctor.
 */
export const manageStaff = onCall({ region: REGION }, async (request) => {
  const doctor = await requireStaff(request, { doctor: true });
  const data = (request.data ?? {}) as Record<string, unknown>;
  const action = data.action;
  const auth = getAuth();

  async function checkRoleAndClinic(): Promise<{ role: "doctor" | "secretary"; clinicId: string | null }> {
    const role = data.role;
    if (role !== "doctor" && role !== "secretary") throw new HttpsError("invalid-argument", "role", { field: "role" });
    if (role === "doctor") return { role, clinicId: null };
    const clinicId = str(data, "clinicId");
    if (!(await db.doc(`clinics/${clinicId}`).get()).exists) throw new HttpsError("invalid-argument", "clinicId", { field: "clinicId" });
    return { role, clinicId };
  }

  async function otherActiveDoctors(uid: string): Promise<number> {
    const q = await db.collection("staff").where("role", "==", "doctor").where("active", "==", true).get();
    return q.docs.filter((d) => d.id !== uid).length;
  }

  if (action === "create") {
    const name = str(data, "name", { max: 80 });
    const email = str(data, "email", { max: 120 }).toLowerCase();
    if (!EMAIL.test(email)) throw new HttpsError("invalid-argument", "email", { field: "email" });
    const tempPassword = str(data, "tempPassword", { max: 64 });
    if (tempPassword.length < 8) throw new HttpsError("invalid-argument", "tempPassword: at least 8 characters", { field: "tempPassword" });
    const { role, clinicId } = await checkRoleAndClinic();
    let user;
    try {
      user = await auth.createUser({ email, password: tempPassword, displayName: name });
    } catch (e) {
      if ((e as { code?: string }).code === "auth/email-already-exists") {
        throw new HttpsError("already-exists", "email in use", { field: "email" });
      }
      throw e;
    }
    await auth.setCustomUserClaims(user.uid, { role, clinicId });
    await db.doc(`staff/${user.uid}`).set({
      name, email, role, clinicId, active: true, mustChangePassword: true,
      createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(), updatedBy: doctor.uid,
    });
    await writeAudit({ action: "staff.created", actorUid: doctor.uid, details: { uid: user.uid, role, clinicId } });
    return { uid: user.uid };
  }

  const uid = str(data, "uid");
  const ref = db.doc(`staff/${uid}`);
  const current = await ref.get();
  if (!current.exists) throw new HttpsError("not-found", "Staff member not found.");

  if (action === "update") {
    const name = str(data, "name", { max: 80 });
    const { role, clinicId } = await checkRoleAndClinic();
    if (current.get("role") === "doctor" && role !== "doctor" && (await otherActiveDoctors(uid)) === 0) {
      throw new HttpsError("failed-precondition", "The last doctor cannot change role.", { reason: "last_doctor" });
    }
    await auth.setCustomUserClaims(uid, { role, clinicId });
    await auth.updateUser(uid, { displayName: name });
    // New claims apply at the next sign-in; revoking ends the old session now.
    await auth.revokeRefreshTokens(uid);
    await ref.update({ name, role, clinicId, updatedAt: FieldValue.serverTimestamp(), updatedBy: doctor.uid });
    await writeAudit({
      action: "staff.updated", actorUid: doctor.uid,
      details: { uid, from: { role: current.get("role"), clinicId: current.get("clinicId") }, to: { role, clinicId } },
    });
    return {};
  }

  if (action === "disable" || action === "enable") {
    const active = action === "enable";
    if (!active && current.get("role") === "doctor" && (await otherActiveDoctors(uid)) === 0) {
      throw new HttpsError("failed-precondition", "The last doctor cannot be disabled.", { reason: "last_doctor" });
    }
    await auth.updateUser(uid, { disabled: !active });
    if (!active) await auth.revokeRefreshTokens(uid);
    await ref.update({ active, updatedAt: FieldValue.serverTimestamp(), updatedBy: doctor.uid });
    await writeAudit({ action: "staff.updated", actorUid: doctor.uid, details: { uid, active } });
    return {};
  }

  throw new HttpsError("invalid-argument", "action", { field: "action" });
});

/** The staff member set their own password after the temporary one (005 FR-001). */
export const staffPasswordChanged = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  await db.doc(`staff/${staff.uid}`).update({ mustChangePassword: false, updatedAt: FieldValue.serverTimestamp() });
  return {};
});
