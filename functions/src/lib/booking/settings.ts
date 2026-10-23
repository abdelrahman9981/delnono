import { db } from "../admin";

export interface HourRange {
  from: number;
  to: number;
}

/** `settings/booking` (data-model.md). Defaults match the seeded placeholders. */
export interface BookingSettings {
  capacityPerHour: number;
  /** ISO weekday ("1" … "7") → open ranges; missing or empty = closed. */
  workingHours: Record<string, HourRange[]>;
  holidays: string[];
  vaccineWeekdays: number[];
  visitPrice: number;
  cancelWindowHours: number;
  bookingHorizonDays: number;
  maxUpcomingPerFamily: number;
}

const evening = [{ from: 17, to: 21 }];

export const BOOKING_DEFAULTS: BookingSettings = {
  capacityPerHour: 6,
  workingHours: { "1": evening, "2": evening, "3": evening, "4": evening, "5": [], "6": evening, "7": evening },
  holidays: [],
  vaccineWeekdays: [1, 3],
  visitPrice: 300,
  cancelWindowHours: 3,
  bookingHorizonDays: 14,
  maxUpcomingPerFamily: 2,
};

export function bookingSettingsFrom(data: Record<string, unknown> | undefined): BookingSettings {
  const s = { ...BOOKING_DEFAULTS };
  if (!data) return s;
  for (const key of ["capacityPerHour", "visitPrice", "cancelWindowHours", "bookingHorizonDays", "maxUpcomingPerFamily"] as const) {
    if (typeof data[key] === "number") s[key] = data[key] as number;
  }
  if (data.workingHours && typeof data.workingHours === "object") s.workingHours = data.workingHours as Record<string, HourRange[]>;
  if (Array.isArray(data.holidays)) s.holidays = data.holidays as string[];
  if (Array.isArray(data.vaccineWeekdays)) s.vaccineWeekdays = data.vaccineWeekdays as number[];
  return s;
}

export async function getBookingSettings(): Promise<BookingSettings> {
  return bookingSettingsFrom((await db.doc("settings/booking").get()).data());
}
