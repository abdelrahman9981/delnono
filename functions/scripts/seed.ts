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
  console.log("Seeded settings, 1 clinic guardian and 2 unlinked clinic children on", CLINIC_PHONE);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
