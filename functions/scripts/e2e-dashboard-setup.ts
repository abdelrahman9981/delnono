/**
 * Test data for the dashboard browser test (integration_test/dashboard), emulator only: a family
 * with today's 6 pm booking at each clinic and the seeded child Youssef linked to it. Clinic 1 keeps
 * its seeded hours; only when today is a closed day or a holiday (Friday, an Eid) is today opened
 * with the seeded Moqattam ranges, so the test runs on any day. Run by scripts/dashboard_e2e.sh.
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error("Emulator only.");
const db = getFirestore(initializeApp({ projectId: "demo-delnono" }));

const today = new Intl.DateTimeFormat("en-CA", { timeZone: "Africa/Cairo", year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date());
/** The seeded Moqattam ranges (functions/scripts/seed.ts); 6 pm is inside them. */
const moqattam = [{ from: 13, to: 15 }, { from: 18, to: 22 }];

async function main() {
  const clinic = db.doc("clinics/clinic-1");
  const snap = await clinic.get();
  const weekday = String(((new Date(`${today}T12:00:00Z`).getUTCDay() + 6) % 7) + 1); // ISO: 1 = Monday
  const hours = (snap.get("workingHours") ?? {}) as Record<string, unknown[]>;
  const holidays = (snap.get("holidays") ?? []) as string[];
  if (!hours[weekday]?.length || holidays.includes(today)) {
    await clinic.update({ [`workingHours.${weekday}`]: moqattam, holidays: holidays.filter((d) => d !== today) });
  }
  await db.doc("guardians/e2e-guardian").set({
    phone: "+201000000001", fullName: "[سارة محمود]", relation: "mother", consentVersion: 1, clinicChildrenPending: false, lastActiveAt: new Date(),
  });
  await db.doc("children/seed-youssef").update({ guardianUid: "e2e-guardian" });
  const booking = (clinicId: string, number: number) => ({
    clinicId, guardianUid: "e2e-guardian", guardianPhone: "+201000000001", date: today, hour: 18,
    startsAt: Timestamp.fromDate(new Date(`${today}T18:00:00+02:00`)), status: "confirmed", visitType: "visit", number,
    children: [{ childId: "seed-youssef", name: "يوسف", vaccines: [] }],
    price: { visit: { amount: 300, covered: false }, vaccines: [], total: 300, hasHiddenPrices: false, packageId: null },
    createdAt: new Date(),
  });
  await db.doc("bookings/e2e-clinic1").set(booking("clinic-1", 901));
  await db.doc("bookings/e2e-clinic2").set(booking("clinic-2", 902));
  console.log("Dashboard e2e data ready for", today);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
