import type { Transaction } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/https";
import { db } from "../admin";

export interface HourRange {
  from: number;
  to: number;
}

/** A vaccine's offer at one clinic (004 data-model.md, `clinics/{id}.vaccinePrices`). */
export interface ClinicVaccinePrice {
  offered: boolean;
  price: number;
  shown: boolean;
}

/**
 * The rules one booking follows: its clinic's schedule and prices (`clinics/{id}`, 004 R1) together
 * with the family-wide horizon and upcoming maximum (`settings/booking`, D-49). Defaults match the
 * seeded placeholders.
 */
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
  vaccinePrices: Record<string, ClinicVaccinePrice>;
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
  vaccinePrices: {},
};

const CLINIC_NUMBERS = ["capacityPerHour", "visitPrice", "cancelWindowHours"] as const;
const FAMILY_NUMBERS = ["bookingHorizonDays", "maxUpcomingPerFamily"] as const;

/** Settings from a clinic document and the family-wide `settings/booking` document. */
export function bookingSettingsFrom(
  clinic: Record<string, unknown> | undefined,
  family: Record<string, unknown> | undefined,
): BookingSettings {
  const s = { ...BOOKING_DEFAULTS };
  for (const key of CLINIC_NUMBERS) if (typeof clinic?.[key] === "number") s[key] = clinic[key] as number;
  for (const key of FAMILY_NUMBERS) if (typeof family?.[key] === "number") s[key] = family[key] as number;
  if (clinic?.workingHours && typeof clinic.workingHours === "object") s.workingHours = clinic.workingHours as Record<string, HourRange[]>;
  if (Array.isArray(clinic?.holidays)) s.holidays = clinic.holidays as string[];
  if (Array.isArray(clinic?.vaccineWeekdays)) s.vaccineWeekdays = clinic.vaccineWeekdays as number[];
  if (clinic?.vaccinePrices && typeof clinic.vaccinePrices === "object") {
    s.vaccinePrices = clinic.vaccinePrices as Record<string, ClinicVaccinePrice>;
  }
  return s;
}

/**
 * The main clinic: the active clinic with the lowest `order`. Records written before 004 have no
 * `clinicId` and belong to it (004 research R5).
 */
export async function mainClinicId(tx?: Transaction): Promise<string> {
  const q = db.collection("clinics").where("active", "==", true).orderBy("order").limit(1);
  const snap = tx ? await tx.get(q) : await q.get();
  if (snap.empty) throw new HttpsError("failed-precondition", "No active clinic.", { reason: "clinic_inactive" });
  return snap.docs[0].id;
}

/** The clinic of a stored record, falling back to the main clinic. */
export async function clinicOf(data: { clinicId?: unknown } | undefined, tx?: Transaction): Promise<string> {
  return typeof data?.clinicId === "string" && data.clinicId ? data.clinicId : mainClinicId(tx);
}

/** The settings for bookings at [clinicId]; refuses an unknown or inactive clinic. */
export async function readBookingSettings(clinicId: string, tx?: Transaction, allowInactive = false): Promise<BookingSettings> {
  const clinicRef = db.doc(`clinics/${clinicId}`);
  const familyRef = db.doc("settings/booking");
  const [clinic, family] = tx ? await Promise.all([tx.get(clinicRef), tx.get(familyRef)]) : await Promise.all([clinicRef.get(), familyRef.get()]);
  if (!clinic.exists || (!allowInactive && clinic.get("active") !== true)) {
    throw new HttpsError("failed-precondition", "Unknown or inactive clinic.", { reason: "clinic_inactive" });
  }
  return bookingSettingsFrom(clinic.data(), family.data());
}
