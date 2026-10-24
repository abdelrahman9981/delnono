/** Clinic time (Cairo). Dates are `YYYY-MM-DD`, hours 0–23, weekdays ISO (1 = Monday … 7 = Sunday). */
export const CLINIC_ZONE = "Africa/Cairo";

const parts = new Intl.DateTimeFormat("en-CA", {
  timeZone: CLINIC_ZONE,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  hourCycle: "h23",
});

function cairoFields(instant: Date) {
  const f: Record<string, number> = {};
  for (const p of parts.formatToParts(instant)) if (p.type !== "literal") f[p.type] = Number(p.value);
  return f as { year: number; month: number; day: number; hour: number; minute: number };
}

/** Cairo calendar date of [instant]. */
export function cairoDate(instant: Date = new Date()): string {
  const f = cairoFields(instant);
  return `${f.year}-${String(f.month).padStart(2, "0")}-${String(f.day).padStart(2, "0")}`;
}

/** Cairo's offset from UTC at [instant], in minutes (120 in winter, 180 in summer time). */
function offsetMinutes(instant: Date): number {
  const f = cairoFields(instant);
  return (Date.UTC(f.year, f.month - 1, f.day, f.hour, f.minute) - instant.getTime()) / 60000;
}

/** The instant an hour starts in Cairo, correct across Egypt's summer-time changes. */
export function startsAt(date: string, hour: number): Date {
  const [y, m, d] = date.split("-").map(Number);
  const local = Date.UTC(y, m - 1, d, hour);
  let guess = local - offsetMinutes(new Date(local)) * 60000;
  guess = local - offsetMinutes(new Date(guess)) * 60000;
  return new Date(guess);
}

/** ISO weekday of a date: 1 = Monday … 7 = Sunday. */
export function weekday(date: string): number {
  const [y, m, d] = date.split("-").map(Number);
  const w = new Date(Date.UTC(y, m - 1, d)).getUTCDay();
  return w === 0 ? 7 : w;
}

export function addDays(date: string, days: number): string {
  const [y, m, d] = date.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d + days)).toISOString().slice(0, 10);
}

/** Document id of an hour's slot at a clinic: `<clinicId>_YYYY-MM-DD_HH` (004 research R2). */
export function slotId(clinicId: string, date: string, hour: number): string {
  return `${clinicId}_${date}_${String(hour).padStart(2, "0")}`;
}

export const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
