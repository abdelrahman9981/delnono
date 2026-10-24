import { FieldValue, type Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../lib/admin";
import { stillActive, type QuotaEntry } from "../lib/booking/quota";
import { insideCancelWindow } from "../lib/booking/schedule";
import { clinicOf, readBookingSettings } from "../lib/booking/settings";
import { slotId } from "../lib/booking/time";
import { requirePhoneUser } from "../lib/guards";
import { REGION } from "../lib/region";

/**
 * Cancels a confirmed booking before the cancel window and frees its place at once (FR-020, FR-021).
 * contracts/callables.md#cancelbooking
 */
export const cancelBooking = onCall({ region: REGION }, async (request) => {
  const { uid } = requirePhoneUser(request);
  const bookingId = (request.data as { bookingId?: unknown } | undefined)?.bookingId;
  if (typeof bookingId !== "string" || !bookingId) {
    throw new HttpsError("invalid-argument", "bookingId is required", { field: "bookingId" });
  }

  await db.runTransaction(async (tx) => {
    const now = new Date();
    const ref = db.doc(`bookings/${bookingId}`);
    const booking = await tx.get(ref);
    if (!booking.exists || booking.get("guardianUid") !== uid) throw new HttpsError("not-found", "Booking not found.");
    const date = booking.get("date") as string;
    const hour = booking.get("hour") as number;
    // The cancel window is the booking's clinic's, even if the clinic closed since (004 FR-010).
    const clinicId = await clinicOf(booking.data(), tx);
    const settings = await readBookingSettings(clinicId, tx, true);
    const [slot, quota] = await Promise.all([
      tx.get(db.doc(`slots/${slotId(clinicId, date, hour)}`)),
      tx.get(db.doc(`familyQuota/${uid}`)),
    ]);
    if (booking.get("status") !== "confirmed") {
      throw new HttpsError("failed-precondition", "Only confirmed bookings can be cancelled.", { reason: "not_confirmed" });
    }
    if (insideCancelWindow(settings, (booking.get("startsAt") as Timestamp).toDate(), now)) {
      throw new HttpsError("failed-precondition", "Too close to the hour; contact the clinic.", { reason: "inside_window" });
    }

    tx.update(ref, {
      status: "cancelled",
      cancelledAt: FieldValue.serverTimestamp(),
      cancelledBy: uid,
      updatedAt: FieldValue.serverTimestamp(),
    });
    tx.set(slot.ref, { taken: Math.max(0, ((slot.get("taken") as number | undefined) ?? 1) - 1) }, { merge: true });
    tx.set(quota.ref, {
      active: stillActive(quota.get("active") as QuotaEntry[] | undefined, now).filter((e) => e.bookingId !== bookingId),
    });
    tx.set(ref.collection("events").doc(), { type: "cancelled", by: uid, at: FieldValue.serverTimestamp() });
  });
  return {};
});
