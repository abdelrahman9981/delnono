import type { Timestamp } from "firebase-admin/firestore";

/** One entry per confirmed booking that has not started (research R2). */
export interface QuotaEntry {
  bookingId: string;
  date: string;
  startsAt: Timestamp;
  /** For display; limits count every clinic together (D-49). */
  clinicId?: string;
}

/** Entries still counting: those whose hour has not started. */
export function stillActive(entries: QuotaEntry[] | undefined, now: Date): QuotaEntry[] {
  return (entries ?? []).filter((e) => e.startsAt.toMillis() > now.getTime());
}
