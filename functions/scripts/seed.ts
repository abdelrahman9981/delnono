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
  // The call number is a placeholder too (003, "اتصلي بالعيادة").
  batch.set(db.doc("settings/clinic"), { whatsappNumber: "+201000000000", phoneNumber: "+201000000000" });

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
    {
      id: "v3", name: "[تطعيم مؤقت ٣]", price: 450, showPrice: false, kind: "additional", active: true,
      suggestedAge: { months: 12, days: 0 }, doses: 2, intervalWeeks: 4, note: "[ملاحظة الدكتور · مؤقتة]",
    },
    {
      id: "v4", name: "[تطعيم مؤقت ٤]", price: 300, showPrice: true, kind: "additional", active: false,
      suggestedAge: { months: 24, days: 0 }, doses: 1, intervalWeeks: 0, note: "[ملاحظة الدكتور · مؤقتة]",
    },
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
    { id: "seed-salma", name: "سلمى", birthDate: "2026-01-20", sex: "female" },
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

  seedChildProfile(batch);
  await batch.commit();
  console.log(
    "Seeded settings (auth, policy, clinic, booking, vaccines, followUp), 4 placeholder vaccines, the placeholder",
    "schedule and follow-up lists, 1 clinic guardian and 3 unlinked clinic children with sample records on",
    CLINIC_PHONE,
  );
}


// Child profile (003). Schedule, follow-up and danger signs are placeholders in brackets until the doctor
// approves them (constitution Principle II, D-36). Records are samples so the screens can be tried
// before staff entry (004). Prescription photos are Phase 2 (D-39).
const SEED_STAFF = "seed-staff";

function seedChildProfile(batch: FirebaseFirestore.WriteBatch) {
  batch.set(db.doc("settings/vaccines"), {
    source: "[جدول التطعيمات الإجبارية · وزارة الصحة المصرية · يراجعه الدكتور]",
    reviewedOn: "2026-10-01",
    lateAfterDays: 7,
    placeholder: true,
  });
  const schedule: [string, string, number, number, string, number?][] = [
    ["s01", "v1", 1, 0, "عند الولادة"],
    ["s02", "v2", 1, 2, "الشهر الثاني"],
    ["s03", "v1", 2, 2, "الشهر الثاني"],
    ["s04", "v2", 2, 4, "الشهر الرابع"],
    ["s05", "v2", 3, 6, "الشهر السادس"],
    ["s06", "v1", 3, 9, "الشهر التاسع"],
    ["s07", "v2", 4, 12, "السنة الأولى"],
    ["s08", "v1", 4, 18, "سنة ونص", 24],
  ];
  schedule.forEach(([id, vaccineId, dose, months, ageLabel, lastMonths], order) => {
    batch.set(db.doc(`vaccineSchedule/${id}`), {
      vaccineId,
      dose,
      dueAge: { months, days: 0 },
      ...(lastMonths ? { lastAge: { months: lastMonths, days: 0 } } : {}),
      ageLabel,
      order,
      placeholder: true,
    });
  });

  batch.set(db.doc("settings/followUp"), {
    maxAgeMonths: 48,
    dangerSigns: [1, 2, 3, 4].map((n) => `[علامة خطر ${ar(n)} · من قائمة الدكتور]`),
    placeholder: true,
  });
  const bands: [number, number, string][] = [
    [0, 2, "متابعة أول شهرين"],
    [2, 4, "متابعة الشهر التاني والتالت"],
    [4, 6, "متابعة الشهر الرابع والخامس"],
    [6, 9, "متابعة الشهر السادس"],
    [9, 12, "متابعة الشهر التاسع"],
    [12, 18, "متابعة السنة الأولى"],
    [18, 24, "متابعة سنة ونص"],
    [24, 36, "متابعة السنة التانية"],
    [36, 48, "متابعة السنة التالتة"],
  ];
  bands.forEach(([fromMonths, toMonths, title], order) => {
    batch.set(db.doc(`followUp/b${fromMonths}`), {
      fromMonths,
      toMonths,
      title,
      items: [1, 2, 3, 4].map((n) => `[بند متابعة ${ar(n)} من قائمة الدكتور]`),
      order,
      placeholder: true,
    });
  });

  // [childId, date, weightKg, lengthCm, headCm?]
  const measurements: [string, string, number, number, number?][] = [
    ["seed-youssef", "2024-05-15", 5.4, 58, 39],
    ["seed-youssef", "2024-07-15", 6.9, 63.5, 41],
    ["seed-youssef", "2024-09-15", 7.8, 67, 43],
    ["seed-youssef", "2024-12-15", 8.7, 71, 44.5],
    ["seed-youssef", "2025-03-15", 9.4, 75, 45.5],
    ["seed-youssef", "2025-09-15", 10.6, 81],
    ["seed-youssef", "2026-03-15", 11.8, 86.5, 48],
    ["seed-youssef", "2026-09-15", 12.9, 91],
    ["seed-mariam", "2025-01-10", 12.4, 89, 48],
    ["seed-mariam", "2026-04-02", 14.6, 98],
    ["seed-salma", "2026-02-20", 4.3, 54, 37.5],
    ["seed-salma", "2026-03-20", 5.2, 57.5, 38.6],
    ["seed-salma", "2026-05-20", 6.4, 62, 40.5],
    ["seed-salma", "2026-07-20", 7.3, 65.5, 42],
  ];
  const visitOf = new Map<string, number>();
  for (const [childId, date, weightKg, lengthCm, headCm] of measurements) {
    const n = (visitOf.get(childId) ?? 0) + 1;
    visitOf.set(childId, n);
    const visitId = `${childId}-v${n}`;
    const child = db.doc(`children/${childId}`);
    batch.set(child.collection("visits").doc(visitId), {
      date,
      type: "clinic",
      bookingId: null,
      createdAt: new Date(`${date}T18:00:00+02:00`),
    });
    batch.set(child.collection("measurements").doc(`${visitId}-m`), {
      measuredOn: date,
      weightKg,
      lengthCm,
      ...(headCm ? { headCm } : {}),
      visitId,
      recordedBy: SEED_STAFF,
      recordedAt: new Date(`${date}T18:10:00+02:00`),
    });
  }

  // [childId, scheduleId | null, vaccineId, dose, givenOn, lot?]
  const doses: [string, string | null, string, number, string, string?][] = [
    ["seed-youssef", "s01", "v1", 1, "2024-03-16", "LOT-1001"],
    ["seed-youssef", "s02", "v2", 1, "2024-05-15", "LOT-2001"],
    ["seed-youssef", "s03", "v1", 2, "2024-05-15"],
    ["seed-youssef", "s04", "v2", 2, "2024-07-15", "LOT-2002"],
    ["seed-youssef", "s05", "v2", 3, "2024-09-15", "LOT-2003"],
    ["seed-youssef", "s07", "v2", 4, "2025-03-15", "LOT-2004"],
    ["seed-youssef", null, "v3", 1, "2025-03-15", "LOT-3001"],
    ...(["s01", "s02", "s03", "s04", "s05", "s06", "s07", "s08"].map(
      (id, i) => ["seed-mariam", id, i % 2 ? "v2" : "v1", 1, "2024-01-01"] as [string, string, string, number, string],
    )),
    ["seed-salma", "s01", "v1", 1, "2026-01-21", "LOT-1101"],
    ["seed-salma", "s02", "v2", 1, "2026-03-20", "LOT-2101"],
    ["seed-salma", "s03", "v1", 2, "2026-03-20"],
    ["seed-salma", "s04", "v2", 2, "2026-05-20", "LOT-2102"],
    ["seed-salma", "s05", "v2", 3, "2026-07-20", "LOT-2103"],
  ];
  doses.forEach(([childId, scheduleId, vaccineId, dose, givenOn, lot], i) => {
    batch.set(db.doc(`children/${childId}/doses/d${i + 1}`), {
      scheduleId,
      vaccineId,
      dose,
      givenOn,
      ...(lot ? { lot } : {}),
      visitId: null,
      recordedBy: SEED_STAFF,
      recordedAt: new Date(`${givenOn}T18:20:00+02:00`),
    });
  });
}

function ar(n: number) {
  return String(n).replace(/[0-9]/g, (d) => "٠١٢٣٤٥٦٧٨٩"[Number(d)]);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
