import { FieldValue, Timestamp, type DocumentReference, type Transaction } from "firebase-admin/firestore";
import { HttpsError } from "firebase-functions/https";
import { db } from "../admin";
import { priceSelection, type PriceSnapshot, type Vaccine } from "./pricing";
import { stillActive, type QuotaEntry } from "./quota";
import { slotProblem } from "./schedule";
import type { Selection } from "./selection";
import { bookingSettingsFrom, type BookingSettings } from "./settings";
import { slotId, startsAt } from "./time";

/** What every booking transaction reads first (Firestore requires reads before writes). */
export interface BookingReads {
  settings: BookingSettings;
  children: Map<string, string>; // childId → name, linked to the caller
  vaccines: Map<string, Vaccine>;
  slotRef: DocumentReference;
  taken: number;
  quotaRef: DocumentReference;
  quota: QuotaEntry[];
  packageId: string | null;
  guardianPhone: string;
}

export async function readForSelection(tx: Transaction, uid: string, sel: Selection, now: Date): Promise<BookingReads> {
  const [settingsSnap, guardian, slot, quotaSnap, packages] = await Promise.all([
    tx.get(db.doc("settings/booking")),
    tx.get(db.doc(`guardians/${uid}`)),
    tx.get(db.doc(`slots/${slotId(sel.date, sel.hour)}`)),
    tx.get(db.doc(`familyQuota/${uid}`)),
    tx.get(db.collection("packages").where("guardianUid", "==", uid).where("active", "==", true)),
  ]);
  const childSnaps = await Promise.all(sel.children.map((c) => tx.get(db.doc(`children/${c.childId}`))));
  const vaccineIds = [...new Set(sel.children.flatMap((c) => c.vaccines))];
  const vaccineSnaps = await Promise.all(vaccineIds.map((id) => tx.get(db.doc(`vaccines/${id}`))));

  const children = new Map<string, string>();
  for (const snap of childSnaps) {
    if (!snap.exists || snap.get("guardianUid") !== uid) {
      throw new HttpsError("invalid-argument", "children: not linked to this guardian", { field: "children" });
    }
    children.set(snap.id, snap.get("name") as string);
  }
  const vaccines = new Map<string, Vaccine>();
  for (const snap of vaccineSnaps) {
    if (!snap.exists || snap.get("active") !== true) {
      throw new HttpsError("invalid-argument", "vaccines: unknown or inactive", { field: "vaccines" });
    }
    vaccines.set(snap.id, {
      id: snap.id,
      name: snap.get("name"),
      price: snap.get("price"),
      showPrice: snap.get("showPrice") !== false,
      active: true,
    });
  }
  const pkg = packages.docs.find((p) => p.get("startsOn") <= sel.date && sel.date <= p.get("endsOn"));
  return {
    settings: bookingSettingsFrom(settingsSnap.data()),
    children,
    vaccines,
    slotRef: slot.ref,
    taken: (slot.get("taken") as number | undefined) ?? 0,
    quotaRef: quotaSnap.ref,
    quota: stillActive(quotaSnap.get("active") as QuotaEntry[] | undefined, now),
    packageId: pkg?.id ?? null,
    guardianPhone: guardian.get("phone") as string,
  };
}

/**
 * The checks shared by create and change, in contract order. [ignoreBookingId] is the booking being
 * changed: its own day and place do not count against the new selection.
 */
export function checkSelection(
  r: BookingReads,
  sel: Selection,
  now: Date,
  ignoreBookingId?: string,
  ownSlotTaken = 0,
): void {
  const needsVaccineDay = sel.children.some((c) => c.vaccines.length > 0);
  const problem = slotProblem(r.settings, sel.date, sel.hour, now, needsVaccineDay);
  if (problem) throw new HttpsError("failed-precondition", `slot: ${problem}`, { reason: problem });

  const others = r.quota.filter((e) => e.bookingId !== ignoreBookingId);
  const sameDay = others.find((e) => e.date === sel.date);
  if (sameDay) {
    throw new HttpsError("already-exists", "The family already has a booking that day.", { bookingId: sameDay.bookingId });
  }
  if (others.length >= r.settings.maxUpcomingPerFamily) {
    throw new HttpsError("out-of-range", "Too many upcoming bookings.", { max: r.settings.maxUpcomingPerFamily });
  }
  if (r.taken - ownSlotTaken >= r.settings.capacityPerHour) {
    throw new HttpsError("resource-exhausted", "The hour is full.", { reason: "full" });
  }
}

export function priceFor(r: BookingReads, sel: Selection, previous: PriceSnapshot | null): PriceSnapshot {
  return priceSelection({
    visitType: sel.visitType,
    children: sel.children,
    visitPrice: r.settings.visitPrice,
    vaccines: r.vaccines,
    packageId: sel.visitType === "visit" ? r.packageId : null,
    previous,
  });
}

/** Refuses when the price the app showed is not the price now (research R4, analyze H2). */
export function checkExpectedTotal(price: PriceSnapshot, expectedTotal: number): void {
  if (price.total !== expectedTotal) {
    throw new HttpsError("failed-precondition", "The price changed.", { reason: "price_changed", price });
  }
}

export function bookingFields(r: BookingReads, sel: Selection, price: PriceSnapshot) {
  return {
    visitType: sel.visitType,
    children: sel.children.map((c) => ({ childId: c.childId, name: r.children.get(c.childId)!, vaccines: c.vaccines })),
    date: sel.date,
    hour: sel.hour,
    startsAt: Timestamp.fromDate(startsAt(sel.date, sel.hour)),
    price,
    updatedAt: FieldValue.serverTimestamp(),
  };
}
