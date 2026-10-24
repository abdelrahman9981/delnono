import { FieldValue } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/https";
import { db } from "../lib/admin";
import { bookingFields, checkExpectedTotal, checkSelection, priceFor, readForSelection } from "../lib/booking/book";
import { parseSelection } from "../lib/booking/selection";
import { requireGuardianWithCurrentConsent, requirePhoneUser } from "../lib/guards";
import { REGION } from "../lib/region";

/**
 * Books an hour for one or more children (FR-001 to FR-017). One transaction over the hour's slot,
 * the booking counter and the family lock, so the first confirmation wins and family limits hold
 * (research R1, R2). contracts/callables.md#createbooking
 */
export const createBooking = onCall({ region: REGION }, async (request) => {
  const { uid } = requirePhoneUser(request);
  await requireGuardianWithCurrentConsent(uid);
  const { expectedTotal, ...sel } = parseSelection((request.data ?? {}) as Record<string, unknown>);

  return db.runTransaction(async (tx) => {
    const now = new Date();
    const r = await readForSelection(tx, uid, sel, now);
    const counterRef = db.doc("counters/bookings");
    const counter = await tx.get(counterRef);
    checkSelection(r, sel, now);
    const price = priceFor(r, sel, null);
    checkExpectedTotal(price, expectedTotal);

    const number = ((counter.get("next") as number | undefined) ?? 1);
    const ref = db.collection("bookings").doc();
    const fields = bookingFields(r, sel, price);
    tx.set(ref, {
      ...fields,
      number,
      guardianUid: uid,
      guardianPhone: r.guardianPhone,
      status: "confirmed",
      createdAt: FieldValue.serverTimestamp(),
    });
    tx.set(r.slotRef, { date: sel.date, hour: sel.hour, taken: r.taken + 1 }, { merge: true });
    tx.set(counterRef, { next: number + 1 });
    tx.set(r.quotaRef, { active: [...r.quota, { bookingId: ref.id, date: sel.date, startsAt: fields.startsAt }] });
    tx.set(ref.collection("events").doc(), { type: "created", by: uid, at: FieldValue.serverTimestamp(), to: { date: sel.date, hour: sel.hour } });
    return { bookingId: ref.id, number, price };
  });
});
