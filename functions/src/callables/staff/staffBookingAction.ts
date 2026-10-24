import { FieldValue, type Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../../lib/admin";
import { writeAudit } from "../../lib/audit";
import { bookingFields, checkSelection, priceFor, readForSelection } from "../../lib/booking/book";
import type { PriceSnapshot } from "../../lib/booking/pricing";
import { stillActive, type QuotaEntry } from "../../lib/booking/quota";
import { parseSelection } from "../../lib/booking/selection";
import { clinicOf } from "../../lib/booking/settings";
import { slotId } from "../../lib/booking/time";
import { REGION } from "../../lib/region";
import { requireClinic, requireStaff, str } from "../../lib/staff";

/**
 * Staff cancel or move a booking on the family's behalf (FR-037, 005 FR-009): capacity, hours and the
 * family limits apply; the cancel window does not, since families inside it are told to call. The
 * booking keeps its clinic and its fixed prices for kept items (002 FR-023).
 */
export const staffBookingAction = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const bookingId = str(data, "bookingId");
  const action = data.action;
  if (action !== "cancel" && action !== "change") throw new HttpsError("invalid-argument", "action", { field: "action" });
  const sel = action === "change"
    ? parseSelection({ ...((data.selection as Record<string, unknown>) ?? {}), expectedTotal: 0 })
    : null;

  return db.runTransaction(async (tx) => {
    const now = new Date();
    const ref = db.doc(`bookings/${bookingId}`);
    const booking = await tx.get(ref);
    if (!booking.exists) throw new HttpsError("not-found", "Booking not found.");
    const clinicId = await clinicOf(booking.data(), tx);
    requireClinic(staff, clinicId);
    const uid = booking.get("guardianUid") as string;
    const oldDate = booking.get("date") as string;
    const oldHour = booking.get("hour") as number;

    if (sel === null) {
      const [slot, quota] = await Promise.all([
        tx.get(db.doc(`slots/${slotId(clinicId, oldDate, oldHour)}`)),
        tx.get(db.doc(`familyQuota/${uid}`)),
      ]);
      if (booking.get("status") !== "confirmed") {
        throw new HttpsError("failed-precondition", "Only confirmed bookings can be cancelled.", { reason: "not_confirmed" });
      }
      tx.update(ref, { status: "cancelled", cancelledAt: FieldValue.serverTimestamp(), cancelledBy: staff.uid, updatedAt: FieldValue.serverTimestamp() });
      tx.set(slot.ref, { taken: Math.max(0, ((slot.get("taken") as number | undefined) ?? 1) - 1) }, { merge: true });
      tx.set(quota.ref, {
        active: stillActive(quota.get("active") as QuotaEntry[] | undefined, now).filter((e) => e.bookingId !== bookingId),
      });
      tx.set(ref.collection("events").doc(), { type: "cancelled", by: staff.uid, byStaff: true, at: FieldValue.serverTimestamp() });
      await writeAudit({ action: "booking.staff_cancelled", actorUid: staff.uid, subjectPhone: booking.get("guardianPhone"), details: { bookingId } }, tx);
      return { bookingId };
    }

    const sameSlot = oldDate === sel.date && oldHour === sel.hour;
    const oldSlot = sameSlot ? null : await tx.get(db.doc(`slots/${slotId(clinicId, oldDate, oldHour)}`));
    const r = await readForSelection(tx, uid, clinicId, sel, now);
    if (booking.get("status") !== "confirmed") {
      throw new HttpsError("failed-precondition", "Only confirmed bookings can be changed.", { reason: "not_confirmed" });
    }
    checkSelection(r, sel, now, bookingId, sameSlot ? 1 : 0);
    const price = priceFor(r, sel, booking.get("price") as PriceSnapshot);
    const fields = bookingFields(r, sel, price);
    tx.update(ref, fields);
    if (oldSlot) {
      tx.set(oldSlot.ref, { taken: Math.max(0, ((oldSlot.get("taken") as number | undefined) ?? 1) - 1) }, { merge: true });
      tx.set(r.slotRef, { clinicId, date: sel.date, hour: sel.hour, taken: r.taken + 1 }, { merge: true });
    }
    tx.set(r.quotaRef, {
      active: [...r.quota.filter((e) => e.bookingId !== bookingId), { bookingId, date: sel.date, startsAt: fields.startsAt as Timestamp, clinicId }],
    });
    tx.set(ref.collection("events").doc(), {
      type: "changed", by: staff.uid, byStaff: true, at: FieldValue.serverTimestamp(),
      from: { date: oldDate, hour: oldHour }, to: { date: sel.date, hour: sel.hour },
    });
    await writeAudit({ action: "booking.staff_changed", actorUid: staff.uid, subjectPhone: booking.get("guardianPhone"), details: { bookingId } }, tx);
    return { bookingId, price };
  });
});
