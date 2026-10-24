import type { BookingSettings } from "./settings";
import { addDays, cairoDate, startsAt, weekday } from "./time";

/** Why an hour cannot be booked (contracts/callables.md, `details.reason`). */
export type SlotProblem = "closed" | "outside_hours" | "beyond_horizon" | "started" | "not_vaccine_day";

export function isOpenDay(s: BookingSettings, date: string): boolean {
  if (s.holidays.includes(date)) return false;
  return (s.workingHours[String(weekday(date))] ?? []).length > 0;
}

export function isVaccineDay(s: BookingSettings, date: string): boolean {
  return isOpenDay(s, date) && s.vaccineWeekdays.includes(weekday(date));
}

/** Working hours of a date, ascending (an hour h covers h:00–h+1:00). */
export function hoursOf(s: BookingSettings, date: string): number[] {
  if (!isOpenDay(s, date)) return [];
  const hours = new Set<number>();
  for (const r of s.workingHours[String(weekday(date))] ?? []) {
    for (let h = r.from; h < r.to; h++) hours.add(h);
  }
  return [...hours].sort((a, b) => a - b);
}

/** First problem with booking [date] at [hour], or null when it can be booked. */
export function slotProblem(
  s: BookingSettings,
  date: string,
  hour: number,
  now: Date,
  needsVaccineDay: boolean,
): SlotProblem | null {
  const today = cairoDate(now);
  if (date < today) return "started";
  if (date > addDays(today, s.bookingHorizonDays)) return "beyond_horizon";
  if (!isOpenDay(s, date)) return "closed";
  if (!hoursOf(s, date).includes(hour)) return "outside_hours";
  if (startsAt(date, hour).getTime() <= now.getTime()) return "started";
  if (needsVaccineDay && !isVaccineDay(s, date)) return "not_vaccine_day";
  return null;
}

/** True once cancelling or changing is no longer allowed (FR-020). */
export function insideCancelWindow(s: BookingSettings, hourStart: Date, now: Date): boolean {
  return now.getTime() >= hourStart.getTime() - s.cancelWindowHours * 60 * 60 * 1000;
}
