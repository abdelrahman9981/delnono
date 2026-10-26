/**
 * Writes the quickstart seed data (specs/001-account-registration/quickstart.md) to the running
 * emulators. Regenerate emulator-seed/ from the repository root with:
 *
 *   functions/node_modules/.bin/firebase emulators:exec --only auth,firestore \
 *     --export-on-exit emulator-seed "cd functions && npm run seed"
 */
import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { nameKey } from "../src/lib/nameKey";
import { BANDS, DANGER_SIGNS, DANGER_SIGNS_SOURCES, HOLIDAYS, PROPOSED, SCHEDULE, SRC, TIPS, VACCINES } from "./demo_data";
import { seedDemoFamilies } from "./seed_demo";
import { assertEmulatorOnly } from "./seed_guard";

// Emulators of a demo-* project only: the seed holds proposed (unapproved) medical content.
assertEmulatorOnly("demo-delnono", process.env);

const app = getApps()[0] ?? initializeApp({ projectId: "demo-delnono" });
const db = getFirestore(app);

const PLACEHOLDER = "[نص مؤقت · يراجعه المحامي قبل الإطلاق]";
/** The seeded family: already registered, children linked; signs in straight to Home (D-51: 123456). */
const FAMILY_PHONE = "+201000000001";
export const FAMILY_UID = "seed-guardian-1";
/** A family the clinic registered that has no app account yet: links its children at first sign-in (001 FR-021). */
const CLINIC_PHONE = "+201000000003";
const CLINIC_1 = "clinic-1";
const CLINIC_2 = "clinic-2";

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
  // Contact numbers live on each clinic since 004 (D-44).
  batch.set(db.doc("settings/clinic"), {});

  // Family-wide booking limits (002, D-49). Clinic schedules and prices are on each clinic (004).
  batch.set(db.doc("settings/booking"), { bookingHorizonDays: 14, maxUpcomingPerFamily: 2, placeholder: true });

  // Two clinics (004, D-44, D-45) with realistic hours (several ranges), capacity, Egyptian public
  // holidays (Nov 2026 – Dec 2027) and Cairo prices (docs/demo-data-sources.md). Weekdays are ISO
  // numbers: 1 = Monday … 7 = Sunday. Clinic 1 is the main clinic (order 0). Names, addresses and
  // phone numbers are for the demo; the doctor confirms them.
  const c1Hours = [{ from: 13, to: 15 }, { from: 18, to: 22 }];
  const c2Long = [{ from: 11, to: 14 }, { from: 17, to: 20 }];
  const c2Evening = [{ from: 17, to: 21 }];
  const priceAt = (clinic: 1 | 2, price: number) => (clinic === 1 ? price : Math.round((price * 1.1) / 5) * 5);
  const offers = (clinic: 1 | 2) => Object.fromEntries(VACCINES.map((v) => [v.id, {
    // Clinic 2 does not stock the meningococcal vaccine (shows a clinic that offers fewer).
    offered: !(clinic === 2 && v.id === "v12"), price: priceAt(clinic, v.price), shown: true,
  }]));
  const clinics = [
    {
      id: CLINIC_1,
      name: "عيادة المقطم",
      area: "المقطم",
      address: "شارع ٩، المقطم، القاهرة",
      phone: "+201000000000",
      whatsapp: "+201000000000",
      order: 0,
      capacityPerHour: 6,
      workingHours: { "1": c1Hours, "2": c1Hours, "3": c1Hours, "4": c1Hours, "5": [], "6": c1Hours, "7": c1Hours },
      vaccineWeekdays: [7, 3],
      cancelWindowHours: 3,
      visitPrice: 400,
      packagePrice: 4000,
      vaccinePrices: offers(1),
    },
    {
      id: CLINIC_2,
      name: "عيادة مدينة نصر",
      area: "مدينة نصر",
      address: "شارع عباس العقاد، مدينة نصر، القاهرة",
      phone: "+201000000002",
      whatsapp: "+201000000002",
      order: 1,
      capacityPerHour: 5,
      workingHours: { "1": c2Evening, "2": c2Long, "3": c2Long, "4": c2Evening, "5": [], "6": [], "7": c2Long },
      vaccineWeekdays: [1, 4],
      cancelWindowHours: 6,
      visitPrice: 450,
      packagePrice: 4500,
      vaccinePrices: offers(2),
    },
  ];
  for (const { id, ...c } of clinics) {
    batch.set(db.doc(`clinics/${id}`), { ...c, holidays: HOLIDAYS, packageMonths: 12, active: true, placeholder: false });
  }

  // Vaccine list: the MOHP basic schedule (free) and common optional vaccines with approximate prices
  // (demo_data.ts). Proposed until the doctor approves the list in the dashboard.
  for (const { id, price: _, ...v } of VACCINES) {
    batch.set(db.doc(`vaccines/${id}`), { ...v, active: true, placeholder: false, reviewStatus: PROPOSED });
  }

  // The seeded family: a registered guardian (Auth user FAMILY_UID, created in seedFamily) with
  // current consent and three linked children with sample records.
  batch.set(db.doc(`guardians/${FAMILY_UID}`), {
    phone: FAMILY_PHONE,
    fullName: "سارة محمود",
    relation: "mother",
    consentVersion: 1,
    clinicChildrenPending: false,
    lastActiveAt: new Date(),
    createdAt: new Date(),
    updatedAt: new Date(),
  });
  batch.set(db.doc(`guardians/${FAMILY_UID}/consents/seed`), {
    policyVersion: 1,
    scopes: ["privacy_policy", "terms", "child_data"],
    acceptedAt: new Date(),
  });
  batch.set(db.doc(`clinicGuardians/${FAMILY_PHONE}`), { fullName: "سارة محمود", relation: "mother", createdAt: new Date() });

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
      guardianPhone: FAMILY_PHONE,
      guardianUid: FAMILY_UID,
      registeredBy: "clinic",
      createdAt: new Date(),
    });
  }

  // The clinic-registered family without an account (001 FR-021): birth date of one child links both.
  batch.set(db.doc(`clinicGuardians/${CLINIC_PHONE}`), { fullName: "منى إبراهيم", relation: "mother", createdAt: new Date() });
  for (const c of [
    { id: "seed-omar", name: "عمر", birthDate: "2023-05-10", sex: "male" },
    { id: "seed-nour", name: "نور", birthDate: "2021-08-08", sex: "female" },
  ]) {
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
  seedContent(batch);
  await batch.commit();
  await seedStaff();
  // The seeded family's Auth user, with the uid its guardian doc and children use.
  await getAuth(app).createUser({ uid: FAMILY_UID, phoneNumber: FAMILY_PHONE });
  // Ten fictional families with bookings, visits, doses, packages and audit entries (seed_demo.ts).
  await seedDemoFamilies(db, getAuth(app));
  console.log(
    "Seeded settings (auth, policy, booking, vaccines, followUp, content), 8 channel videos (3 published),",
    `${TIPS.length} proposed tips, 2 clinics, ${VACCINES.length} proposed vaccines, the proposed MOHP schedule and follow-up lists,`,
    "10 demo families with activity, the registered family on", FAMILY_PHONE, `(uid ${FAMILY_UID}, 3 children with sample records)`,
    "and an unlinked clinic family on", CLINIC_PHONE,
  );
}


// Child profile (003). Schedule, follow-up and danger signs are placeholders in brackets until the doctor
// approves them (constitution Principle II, D-36). Records are samples so the screens can be tried
// before staff entry (004). Prescription photos are Phase 2 (D-39).
const SEED_STAFF = "seed-staff";

function seedChildProfile(batch: FirebaseFirestore.WriteBatch) {
  batch.set(db.doc("settings/vaccines"), {
    source: "جدول التطعيمات الإجبارية · وزارة الصحة والسكان (مقترح · يراجعه الدكتور)",
    lateAfterDays: 7,
    placeholder: false,
    reviewStatus: PROPOSED,
    sourceUrl: SRC.mohp2025,
  });
  SCHEDULE.forEach(({ id, vaccineId, dose, months, ageLabel, lastMonths, sourceUrl }, order) => {
    batch.set(db.doc(`vaccineSchedule/${id}`), {
      vaccineId,
      dose,
      dueAge: { months, days: 0 },
      ...(lastMonths ? { lastAge: { months: lastMonths, days: 0 } } : {}),
      ageLabel,
      order,
      placeholder: false,
      reviewStatus: PROPOSED,
      sourceUrl,
    });
  });

  // Follow-up by age (CDC milestones) and «إمتى تتصلي بالدكتور» (WHO IMCI, AAP): proposed.
  batch.set(db.doc("settings/followUp"), {
    maxAgeMonths: 48,
    dangerSigns: DANGER_SIGNS,
    placeholder: false,
    reviewStatus: PROPOSED,
    sourceUrls: DANGER_SIGNS_SOURCES,
  });
  BANDS.forEach(({ fromMonths, toMonths, title, items, dangerSigns, sourceUrl }, order) => {
    batch.set(db.doc(`followUp/b${fromMonths}`), {
      fromMonths, toMonths, title, items, dangerSigns, order, placeholder: false, reviewStatus: PROPOSED, sourceUrl,
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
    // Visits alternate between the two clinics so the clinic shows on the history (D-48).
    const clinicId = n % 2 === 0 ? CLINIC_2 : CLINIC_1;
    const child = db.doc(`children/${childId}`);
    batch.set(child.collection("visits").doc(visitId), {
      date,
      type: "clinic",
      clinicId,
      bookingId: null,
      createdAt: new Date(`${date}T18:00:00+02:00`),
    });
    batch.set(child.collection("measurements").doc(`${visitId}-m`), {
      measuredOn: date,
      weightKg,
      lengthCm,
      ...(headCm ? { headCm } : {}),
      visitId,
      clinicId,
      recordedBy: SEED_STAFF,
      recordedAt: new Date(`${date}T18:10:00+02:00`),
    });
  }

  // [childId, scheduleId | null, vaccineId, dose, givenOn, lot?]: the seeded children's doses on the
  // MOHP schedule, given on time (Salma's 9-month dose is still due). Youssef also had the rota vaccine.
  const family: [string, string][] = [["seed-youssef", "2024-03-15"], ["seed-mariam", "2022-07-02"], ["seed-salma", "2026-01-20"]];
  const doses: [string, string | null, string, number, string, string?][] = [];
  for (const [childId, birthDate] of family) {
    for (const e of SCHEDULE) {
      const due = addMonths(birthDate, e.months);
      if (due > "2026-10-01") continue;
      const lot = childId === "seed-youssef" && e.id === "s01" ? "LOT-1001" : `LOT-${e.id.slice(1)}${doses.length + 100}`;
      doses.push([childId, e.id, e.vaccineId, e.dose, e.months === 0 ? addDays(birthDate, 1) : due, lot]);
    }
  }
  doses.push(["seed-youssef", null, "v3", 1, "2024-05-15", "LOT-3001"], ["seed-youssef", null, "v3", 2, "2024-07-15", "LOT-3002"]);
  doses.forEach(([childId, scheduleId, vaccineId, dose, givenOn, lot], i) => {
    batch.set(db.doc(`children/${childId}/doses/d${i + 1}`), {
      scheduleId,
      vaccineId,
      dose,
      givenOn,
      ...(lot ? { lot } : {}),
      visitId: null,
      clinicId: i % 3 === 2 ? CLINIC_2 : CLINIC_1,
      recordedBy: SEED_STAFF,
      recordedAt: new Date(`${givenOn}T18:20:00+02:00`),
    });
  });
}

// Content library (006, D-50): real Shorts from the doctor's channel. Titles are the text written on
// each video's frame and categories are guessed from it: "Assumption — needs owner review". Three are
// published for the demo; tips are bracketed placeholders until the doctor writes them.
const VIDEO_SEED: [string, string, string, string, boolean, number?, number?][] = [
  ["skgdeAOm374", "2026-10-26", "تطعيم الحصبه والماسونيه العالميه", "vaccines", false],
  ["eH9QRdN_Hgw", "2026-10-20", "تلت حجات في حديثي الولاده خلي بالك منهم لو هتولدي قريب", "newborn", false, 0, 1],
  ["WjbDIjEH38U", "2026-10-20", "هل ينفع نحط ملح قبل عمر سنه", "feeding", true, 4, 12],
  ["YC_I43gRbpc", "2026-10-19", "الخناق الحنجري منتشر بشكل مرعب بس متقلقوش", "fever", false],
  ["dHP05TFideE", "2026-10-15", "اسرع دوا ينزل الحراره للاطفال في مصر", "fever", false],
  ["TGzE9d9m44A", "2026-10-15", "هو الاكل في الشهر الرابع و لا السادس؟!", "feeding", true, 3, 8],
  ["KDOV-4nbWqU", "2026-10-15", "فيتامين د بيعمل ارهاق للاطفال ومش بيناموا بسببه", "sleep", true, 0, 24],
  ["5bM0xJ8uHFY", "2026-10-15", "رد على سؤال: ابني عنده خنفرة وحساسية أنف من عمر ٥٠ يوم", "allergy", false],
];

function seedContent(batch: FirebaseFirestore.WriteBatch) {
  batch.set(db.doc("settings/content"), {
    categories: [
      { id: "fever", name: "الحرارة" },
      { id: "feeding", name: "الرضاعة والهضم" },
      { id: "sleep", name: "النوم" },
      { id: "allergy", name: "الحساسية" },
      { id: "vaccines", name: "التطعيمات" },
      { id: "newborn", name: "حديثي الولادة" },
    ],
  });
  for (const [youtubeId, date, title, category, published, from, to] of VIDEO_SEED) {
    const at = new Date(`${date}T12:00:00+02:00`);
    batch.set(db.doc(`content/yt-${youtubeId}`), {
      type: "video", title, category, body: null, youtubeId, url: `https://youtube.com/shorts/${youtubeId}`,
      ageFromMonths: from ?? null, ageToMonths: to ?? null, order: 100,
      status: published ? "published" : "draft",
      createdBy: "staff-doctor", createdAt: at, updatedBy: "staff-doctor", updatedAt: at,
      ...(published ? { publishedBy: "staff-doctor", publishedAt: at } : {}),
    });
  }
  // Short researched tips, 2–3 per category, published for the demo but proposed (dashboard badge).
  TIPS.forEach(({ id, category, title, body, ageFromMonths, ageToMonths, sourceUrl }, i) => {
    const at = new Date(Date.UTC(2026, 9, 1 + (i % 20), 10));
    batch.set(db.doc(`content/${id}`), {
      type: "tip", title, category, body, youtubeId: null, url: null,
      ageFromMonths: ageFromMonths ?? null, ageToMonths: ageToMonths ?? null, order: 100, status: "published",
      createdBy: "staff-sec1", createdAt: at, updatedBy: "staff-doctor", updatedAt: at,
      publishedBy: "staff-doctor", publishedAt: at, reviewStatus: PROPOSED, sourceUrl,
    });
  });
}

// Staff accounts (005), emulator only. The real project's doctor account is created during setup
// (docs/demo-plan.md); never with this password.
export const STAFF_PASSWORD = "Delnono-2026";

async function seedStaff() {
  if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) throw new Error("FIREBASE_AUTH_EMULATOR_HOST is not set.");
  const auth = getAuth(app);
  const staff = [
    { uid: "staff-doctor", email: "doctor@demo.delnono", name: "[د. أحمد العبد]", role: "doctor", clinicId: null },
    { uid: "staff-sec1", email: "sec1@demo.delnono", name: "[سكرتيرة المقطم]", role: "secretary", clinicId: CLINIC_1 },
    { uid: "staff-sec2", email: "sec2@demo.delnono", name: "[سكرتيرة مدينة نصر]", role: "secretary", clinicId: CLINIC_2 },
  ];
  for (const s of staff) {
    await auth.createUser({ uid: s.uid, email: s.email, password: STAFF_PASSWORD, displayName: s.name });
    await auth.setCustomUserClaims(s.uid, { role: s.role, clinicId: s.clinicId });
    await db.doc(`staff/${s.uid}`).set({
      name: s.name, email: s.email, role: s.role, clinicId: s.clinicId, active: true, mustChangePassword: false, createdAt: new Date(),
    });
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

function addDays(date: string, days: number): string {
  const d = new Date(`${date}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + days);
  return d.toISOString().slice(0, 10);
}

function addMonths(date: string, months: number): string {
  const [y, m, d] = date.split("-").map(Number);
  const last = new Date(Date.UTC(y, m - 1 + months + 1, 0)).getUTCDate();
  return new Date(Date.UTC(y, m - 1 + months, Math.min(d, last))).toISOString().slice(0, 10);
}
