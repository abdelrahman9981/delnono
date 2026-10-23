import { FieldValue } from "firebase-admin/firestore";
import { onDocumentUpdated } from "firebase-functions/firestore";
import { writeAudit } from "../lib/audit";
import { nameKey } from "../lib/nameKey";
import { REGION } from "../lib/region";

/** Fields that describe the child. Bookkeeping fields (nameKey, updatedAt, links) are not history. */
export const TRACKED_FIELDS = ["name", "allergies", "birthDate", "sex", "birthWeightKg"] as const;

type Change = { from: unknown; to: unknown };

export function changedFields(before: Record<string, unknown>, after: Record<string, unknown>): Record<string, Change> {
  const changes: Record<string, Change> = {};
  for (const field of TRACKED_FIELDS) {
    const from = before[field] ?? null;
    const to = after[field] ?? null;
    if (JSON.stringify(from) !== JSON.stringify(to)) changes[field] = { from, to };
  }
  return changes;
}

/**
 * Records every change to a child's details in `children/{id}/history` with who and when (FR-023),
 * writes an audit entry when allergies change (FR-023a), and keeps `nameKey` in step with a renamed
 * child so the duplicate check stays right (FR-022).
 */
export const onChildUpdated = onDocumentUpdated({ document: "children/{childId}", region: REGION }, async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  if (!before || !after) return;

  const changes = changedFields(before, after);
  if (Object.keys(changes).length === 0) return;

  const ref = event.data!.after.ref;
  const changedBy = (after.updatedBy as string | undefined) ?? "system";
  await ref.collection("history").add({ changedFields: changes, changedBy, changedAt: FieldValue.serverTimestamp() });

  if (changes.name && after.nameKey !== nameKey(String(after.name))) {
    await ref.update({ nameKey: nameKey(String(after.name)) });
  }
  if (changes.allergies) {
    await writeAudit({
      action: "child.allergies_changed",
      actorUid: changedBy,
      subjectPhone: String(after.guardianPhone ?? ""),
      childIds: [ref.id],
      details: { from: changes.allergies.from, to: changes.allergies.to },
    });
  }
});
