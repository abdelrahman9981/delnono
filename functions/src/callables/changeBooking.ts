import { FieldValue, type Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../lib/admin";
import { bookingFields, checkExpectedTotal, checkSelection, priceFor, readForSelection } from "../lib/booking/book";
import type { PriceSnapshot } from "../lib/booking/pricing";
import { insideCancelWindow } from "../lib/booking/schedule";
import { parseSelection } from "../lib/booking/selection";
import { slotId } from "../lib/booking/time";
import { requireGuardianWithCurrentConsent, requirePhoneUser } from "../lib/guards";
import { REGION } from "../lib/region";

/**
 * Moves a confirmed booking to another hour (and optionally other children or vaccines) before the
 * cancel window, in one transaction: the old place is freed and the new one taken, the number stays,
 * and amounts already fixed are kept (FR-022, FR-023). contracts/callables.md#changebooking
 */
export const changeBooking = onCall({ region: REGION }, async (request) => {
  const { uid } = requirePhoneUser(request);
  await requireGuardianWithCurrentConsent(uid);
  const data = (request.data ?? {}) as { bookingId?: unknown; selection?: Record<string, unknown>; expectedTotal?: unknown };
  if (typeof data.bookingId !== "string" || !data.bookingId) {
    throw new HttpsError("invalid-argument", "bookingId is required", { field: "bookingId" });
  }
  const bookingId = data.bookingId;
  const { expectedTotal, ...sel } = parseSelection({ ...(data.selection ?? {}), expectedTotal: data.expectedTotal });

  return db.runTransaction(async (tx) => {
    const now = new Date();
    const ref = db.doc(`bookings/${bookingId}`);
    const booking = await tx.get(ref);
    if (!booking.exists || booking.get("guardianUid") !== uid) throw new HttpsError("not-found", "Booking not found.");
    const oldDate = booking.get("date") as string;
    const oldHour = booking.get("hour") as number;
    const sameSlot = oldDate === sel.date && oldHour === sel.hour;
    const oldSlot = sameSlot ? null : await tx.get(db.doc(`slots/${slotId(oldDate, oldHour)}`));
    const r = await readForSelection(tx, uid, sel, now);

    if (booking.get("status") !== "confirmed") {
      throw new HttpsError("failed-precondition", "Only confirmed bookings can be changed.", { reason: "not_confirmed" });
    }
    if (insideCancelWindow(r.settings, (booking.get("startsAt") as Timestamp).toDate(), now)) {
      throw new HttpsError("failed-precondition", "Too close to the hour; contact the clinic.", { reason: "inside_window" });
    }
    checkSelection(r, sel, now, bookingId, sameSlot ? 1 : 0);
    const price = priceFor(r, sel, booking.get("price") as PriceSnapshot);
    checkExpectedTotal(price, expectedTotal);

    const fields = bookingFields(r, sel, price);
    tx.update(ref, fields);
    if (oldSlot) {
      tx.set(oldSlot.ref, { taken: Math.max(0, ((oldSlot.get("taken") as number | undefined) ?? 1) - 1) }, { merge: true });
      tx.set(r.slotRef, { date: sel.date, hour: sel.hour, taken: r.taken + 1 }, { merge: true });
    }
    tx.set(r.quotaRef, {
      active: [
        ...r.quota.filter((e) => e.bookingId !== bookingId),
        { bookingId, date: sel.date, startsAt: fields.startsAt },
      ],
    });
    tx.set(ref.collection("events").doc(), {
      type: "changed",
      by: uid,
      at: FieldValue.serverTimestamp(),
      from: { date: oldDate, hour: oldHour },
      to: { date: sel.date, hour: sel.hour },
    });
    return { bookingId, number: booking.get("number") as number, price };
  });
});
