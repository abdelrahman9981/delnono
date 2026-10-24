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

export async function seedBookingSettings(overrides: Record<string, unknown> = {}) {
  await adminDb().doc("settings/booking").set({ ...BOOKING_DEFAULTS, placeholder: true, ...overrides });
  const vaccines = [
    { id: "v1", name: "[تطعيم ١]", price: 150, showPrice: true, active: true },
    { id: "v2", name: "[تطعيم ٢]", price: 200, showPrice: true, active: true },
    { id: "v3", name: "[تطعيم ٣]", price: 450, showPrice: false, active: true },
    { id: "v4", name: "[تطعيم ٤]", price: 300, showPrice: true, active: false },
  ];
  await Promise.all(vaccines.map(({ id, ...v }) => adminDb().doc(`vaccines/${id}`).set({ ...v, kind: "basic", placeholder: true })));
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

export function visit(date: string, hour: number, childIds: string[], expectedTotal = 300) {
  return { visitType: "visit", date, hour, children: childIds.map((childId) => ({ childId, vaccines: [] })), expectedTotal };
}
