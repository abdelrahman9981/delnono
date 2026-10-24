import { BOOKING_DEFAULTS } from "../../src/lib/booking/settings";
import { addDays, cairoDate } from "../../src/lib/booking/time";
import { isOpenDay, isVaccineDay } from "../../src/lib/booking/schedule";
import { adminDb, seedChild, seedGuardian, signInAsPhoneUser, type PhoneSession } from "./env";

/** Booking tests run on the real clock, so dates are found from the seeded schedule. */
export function nextDay(pred: (date: string) => boolean, from = 1): string {
  const today = cairoDate();
  for (let i = from; i <= BOOKING_DEFAULTS.bookingHorizonDays; i++) {
    const d = addDays(today, i);
    if (pred(d)) return d;
  }
  throw new Error("no matching day within the horizon");
}

export const openNonVaccineDay = (from = 1) => nextDay((d) => isOpenDay(BOOKING_DEFAULTS, d) && !isVaccineDay(BOOKING_DEFAULTS, d), from);
export const vaccineDay = (from = 1) => nextDay((d) => isVaccineDay(BOOKING_DEFAULTS, d), from);
export const closedDay = () => nextDay((d) => !isOpenDay(BOOKING_DEFAULTS, d));

export const CLINIC = "clinic-1";
export const CLINIC_2 = "clinic-2";

/** Clinic 1's vaccine offers (as the 002 vaccine prices); v4 is inactive in the doctor's list. */
export const VACCINE_PRICES = {
  v1: { offered: true, price: 150, shown: true },
  v2: { offered: true, price: 200, shown: true },
  v3: { offered: true, price: 450, shown: false },
  v4: { offered: true, price: 300, shown: true },
};

/**
 * Seeds the main clinic with 002's placeholder schedule and prices plus [overrides], the family-wide
 * `settings/booking`, and the doctor's vaccine list. Overrides go to both documents; each reader picks
 * its own fields (004 research R1).
 */
export async function seedBookingSettings(overrides: Record<string, unknown> = {}) {
  const { bookingHorizonDays, maxUpcomingPerFamily, vaccinePrices: _, ...clinic } = BOOKING_DEFAULTS;
  await adminDb().doc("settings/booking").set({ bookingHorizonDays, maxUpcomingPerFamily, placeholder: true, ...overrides });
  await seedClinic(CLINIC, { ...clinic, order: 0, ...overrides });
  const vaccines = [
    { id: "v1", name: "[تطعيم ١]", active: true },
    { id: "v2", name: "[تطعيم ٢]", active: true },
    { id: "v3", name: "[تطعيم ٣]", active: true },
    { id: "v4", name: "[تطعيم ٤]", active: false },
  ];
  await Promise.all(vaccines.map(({ id, ...v }) => adminDb().doc(`vaccines/${id}`).set({ ...v, kind: "basic", placeholder: true })));
}

/** A clinic document: active, with 002's schedule and clinic 1's vaccine prices unless overridden. */
export async function seedClinic(id: string, fields: Record<string, unknown> = {}) {
  const { bookingHorizonDays: _h, maxUpcomingPerFamily: _m, ...clinic } = BOOKING_DEFAULTS;
  await adminDb()
    .doc(`clinics/${id}`)
    .set({ name: `[${id}]`, address: "[عنوان]", active: true, order: 1, ...clinic, vaccinePrices: VACCINE_PRICES, ...fields });
}

/** A registered guardian with [children] linked children named c1, c2, … (ids `<uid>-c1`, …). */
export async function guardianWithChildren(phone: string, children = 1): Promise<PhoneSession & { childIds: string[] }> {
  const user = await signInAsPhoneUser(phone);
  await seedGuardian(user.uid, { phone });
  const childIds: string[] = [];
  for (let i = 1; i <= children; i++) {
    const id = `${user.uid}-c${i}`;
    await seedChild(id, { name: `طفل ${i}`, guardianUid: user.uid, guardianPhone: phone });
    childIds.push(id);
  }
  return { ...user, childIds };
}

export function visit(date: string, hour: number, childIds: string[], expectedTotal = 300, clinicId = CLINIC) {
  return { clinicId, visitType: "visit", date, hour, children: childIds.map((childId) => ({ childId, vaccines: [] })), expectedTotal };
}

/** The slot document of [clinicId] at [date] and [hour]. */
export const slotPath = (date: string, hour: number, clinicId = CLINIC) => `slots/${clinicId}_${date}_${String(hour).padStart(2, "0")}`;
