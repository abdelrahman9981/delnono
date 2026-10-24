import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../../lib/admin";
import { mainClinicId } from "../../lib/booking/settings";
import { DATE_PATTERN } from "../../lib/booking/time";
import { REGION } from "../../lib/region";
import { requireClinic, requireStaff, str } from "../../lib/staff";

export interface ReportRow {
  key: string;
  bookings: number;
  arrivals: number;
  noShows: number;
  walkIns: number;
  cash: number;
  packagesSold: number;
}

const empty = (key: string): ReportRow => ({ key, bookings: 0, arrivals: 0, noShows: 0, walkIns: 0, cash: 0, packagesSold: 0 });

/**
 * Daily or monthly numbers (D-20, 005 FR-022): bookings (not cancelled), arrivals (bookings that
 * arrived or were done), no-shows, walk-ins, cash collected (bookings and walk-ins) and packages sold,
 * for a clinic or, for the doctor, all clinics. Numbers only: no names, phones or medical data.
 */
export const report = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const all = data.clinicId === "all";
  if (all && staff.role !== "doctor") throw new HttpsError("permission-denied", "Doctor only.");
  const clinicId = all ? null : requireClinic(staff, data.clinicId);
  const from = str(data, "from"), to = str(data, "to");
  if (!DATE_PATTERN.test(from) || !DATE_PATTERN.test(to) || from > to) throw new HttpsError("invalid-argument", "date range", { field: "from" });
  const byMonth = data.groupBy === "month";
  const keyOf = (date: string) => (byMonth ? date.slice(0, 7) : date);

  const inRange = <T extends FirebaseFirestore.Query>(q: T, field: string) => q.where(field, ">=", from).where(field, "<=", to);
  const [bookings, walkIns, packages, main] = await Promise.all([
    inRange(db.collection("bookings"), "date").get(),
    inRange(db.collection("walkIns"), "date").get(),
    inRange(db.collection("packages"), "soldOn").get(),
    mainClinicId(),
  ]);
  // Records before 004 have no clinic: they count for the main clinic (004 FR-018).
  const mine = (c: unknown) => all || (typeof c === "string" && c ? c : main) === clinicId;

  const rows = new Map<string, ReportRow>();
  const row = (date: string) => {
    const k = keyOf(date);
    if (!rows.has(k)) rows.set(k, empty(k));
    return rows.get(k)!;
  };
  for (const b of bookings.docs) {
    if (!mine(b.get("clinicId"))) continue;
    const status = b.get("status");
    if (status === "cancelled") continue;
    const r = row(b.get("date"));
    r.bookings++;
    if (status === "arrived" || status === "done") r.arrivals++;
    if (status === "no_show") r.noShows++;
    r.cash += Number(b.get("payment.cash") ?? 0);
  }
  for (const w of walkIns.docs) {
    if (!mine(w.get("clinicId"))) continue;
    const r = row(w.get("date"));
    r.walkIns++;
    r.cash += Number(w.get("payment.cash") ?? 0);
  }
  for (const p of packages.docs) {
    if (!mine(p.get("soldAtClinicId"))) continue;
    const r = row(p.get("soldOn"));
    r.packagesSold++;
    r.cash += Number(p.get("price") ?? 0);
  }
  const list = [...rows.values()].sort((a, b) => a.key.localeCompare(b.key));
  const total = list.reduce((t, r) => {
    for (const k of ["bookings", "arrivals", "noShows", "walkIns", "cash", "packagesSold"] as const) t[k] += r[k];
    return t;
  }, empty("total"));
  return { rows: list, total };
});
