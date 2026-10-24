/**
 * Writes the quickstart seed data (specs/001-account-registration/quickstart.md) to the running
 * emulators. Regenerate emulator-seed/ from the repository root with:
 *
 *   functions/node_modules/.bin/firebase emulators:exec --only auth,firestore \
 *     --export-on-exit emulator-seed "cd functions && npm run seed"
 */
import { initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { nameKey } from "../src/lib/nameKey";

if (!process.env.FIRESTORE_EMULATOR_HOST) {
  throw new Error("FIRESTORE_EMULATOR_HOST is not set; refusing to seed anything but the emulator.");
}

const db = getFirestore(initializeApp({ projectId: "demo-delnono" }));

const PLACEHOLDER = "[نص مؤقت · يراجعه المحامي قبل الإطلاق]";
const CLINIC_PHONE = "+201000000001";

async function main() {
  const batch = db.batch();

  batch.set(db.doc("settings/auth"), {
    codeValiditySeconds: 300,
    maxCodeAttempts: 5,
    resendWaitSeconds: 60,
    dailySmsCapPerNumber: 5,
    maxLinkAttempts: 3,
    reverifyAfterDays: 90,
  });
  batch.set(db.doc("settings/policy"), {
    currentVersion: 1,
    privacyPolicyText: `${PLACEHOLDER}\nسياسة الخصوصية`,
    termsText: `${PLACEHOLDER}\nشروط الاستخدام`,
    updatedAt: new Date(),
  });
  // Placeholder number until the clinic supplies its WhatsApp number (D-36).
  batch.set(db.doc("settings/clinic"), { whatsappNumber: "+201000000000" });

  // Booking settings (002). Placeholder values until the doctor sets them in the dashboard (004, D-36).
  // Weekdays are ISO numbers: 1 = Monday … 7 = Sunday. Friday (5) is closed.
  const evening = [{ from: 17, to: 21 }];
  batch.set(db.doc("settings/booking"), {
    capacityPerHour: 6,
    workingHours: { "1": evening, "2": evening, "3": evening, "4": evening, "5": [], "6": evening, "7": evening },
    holidays: [],
    vaccineWeekdays: [1, 3],
    visitPrice: 300,
    cancelWindowHours: 3,
    bookingHorizonDays: 14,
    maxUpcomingPerFamily: 2,
    placeholder: true,
  });

  // Vaccine list (002). Names are placeholders in brackets until the doctor's list arrives
  // (constitution Principle II); the schedule itself comes in feature 003.
  const vaccines = [
    { id: "v1", name: "[تطعيم مؤقت ١]", price: 150, showPrice: true, kind: "basic", active: true },
    { id: "v2", name: "[تطعيم مؤقت ٢]", price: 200, showPrice: true, kind: "basic", active: true },
    { id: "v3", name: "[تطعيم مؤقت ٣]", price: 450, showPrice: false, kind: "additional", active: true },
    { id: "v4", name: "[تطعيم مؤقت ٤]", price: 300, showPrice: true, kind: "additional", active: false },
  ];
  for (const { id, ...v } of vaccines) batch.set(db.doc(`vaccines/${id}`), { ...v, placeholder: true });

  batch.set(db.doc(`clinicGuardians/${CLINIC_PHONE}`), {
    fullName: "سارة محمود",
    relation: "mother",
    createdAt: new Date(),
  });

  const children = [
    { id: "seed-youssef", name: "يوسف", birthDate: "2024-03-15", sex: "male" },
    { id: "seed-mariam", name: "مريم", birthDate: "2022-07-02", sex: "female" },
  ];
  for (const c of children) {
    batch.set(db.doc(`children/${c.id}`), {
      name: c.name,
      nameKey: nameKey(c.name),
      birthDate: c.birthDate,
      sex: c.sex,
      guardianPhone: CLINIC_PHONE,
      guardianUid: null,
      registeredBy: "clinic",
      createdAt: new Date(),
    });
  }

  await batch.commit();
  console.log("Seeded settings (auth, policy, clinic, booking), 4 placeholder vaccines, 1 clinic guardian and 2 unlinked clinic children on", CLINIC_PHONE);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
