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
  | "account.reverify_locked";

export interface AuditEntry {
  action: AuditAction;
  actorUid: string;
  subjectPhone: string;
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
    subjectPhone: entry.subjectPhone,
    ...(entry.childIds ? { childIds: entry.childIds } : {}),
    ...(entry.details ? { details: entry.details } : {}),
    at: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(Date.now() + RETENTION_MS),
  };
  if (tx) tx.set(ref, doc);
  else await ref.set(doc);
}
