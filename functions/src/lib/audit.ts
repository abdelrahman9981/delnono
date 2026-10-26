import { FieldValue, Timestamp, Transaction } from "firebase-admin/firestore";
import { db } from "./admin";

export type AuditAction =
  | "account.created"
  | "consent.accepted"
  | "children.linked"
  | "children.link_failed"
  | "children.link_locked"
  | "phone.changed"
  | "account.deleted"
  | "child.allergies_changed"
  | "account.reverified"
  | "account.reverify_failed"
  | "account.reverify_locked"
  // Staff (005, D-13).
  | "staff.created"
  | "staff.updated"
  | "child.opened"
  | "child.basics_changed"
  | "medical.recorded"
  | "medical.corrected"
  | "note.saved"
  | "clinic.updated"
  | "catalogue.updated"
  | "settings.updated"
  | "content.published"
  | "followup.published"
  | "status.undone"
  | "booking.staff_cancelled"
  | "booking.staff_changed"
  | "package.sold"
  // Dashboard completion (009).
  | "family.registered"
  | "children.merged"
  | "children.linked_by_staff"
  | "account.reverify_unlocked_by_staff"
  // Content library (006).
  | "content.unpublished"
  | "content.archived"
  | "content.restored"
  | "content.categories_updated";

export interface AuditEntry {
  action: AuditAction;
  actorUid: string;
  /** The family concerned, when there is one. */
  subjectPhone?: string;
  childIds?: string[];
  details?: Record<string, unknown>;
}

/** Kept for one year (D-13); a TTL policy on `expiresAt` deletes older entries. */
const RETENTION_MS = 365 * 24 * 60 * 60 * 1000;

/** Writes to `auditLog`, inside [tx] when given so the entry commits with the change it records. */
export async function writeAudit(entry: AuditEntry, tx?: Transaction): Promise<void> {
  const ref = db.collection("auditLog").doc();
  const doc = {
    action: entry.action,
    actorUid: entry.actorUid,
    ...(entry.subjectPhone ? { subjectPhone: entry.subjectPhone } : {}),
    ...(entry.childIds ? { childIds: entry.childIds } : {}),
    ...(entry.details ? { details: entry.details } : {}),
    at: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + RETENTION_MS),
  };
  if (tx) tx.set(ref, doc);
  else await ref.set(doc);
}
