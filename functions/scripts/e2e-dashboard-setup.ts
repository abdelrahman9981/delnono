/**
 * Test data for the dashboard browser test (integration_test/dashboard), emulator only: a family
 * with today's booking at each clinic, the seeded child Youssef linked to it, and clinic 1 open all
 * day so the test runs at any hour. Run by scripts/dashboard_e2e.sh before the browser starts.
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

if (!process.env.FIRESTORE_EMULATOR_HOST) throw new Error("Emulator only.");
const db = getFirestore(initializeApp({ projectId: "demo-delnono" }));

const today = new Intl.DateTimeFormat("en-CA", { timeZone: "Africa/Cairo", year: "numeric", month: "2-digit", day: "2-digit" }).format(new Date());
const allDay = [{ from: 0, to: 24 }];

async function main() {
  await db.doc("clinics/clinic-1").update({
    workingHours: { "1": allDay, "2": allDay, "3": allDay, "4": allDay, "5": allDay, "6": allDay, "7": allDay },
  });
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
