/**
 * Ten fictional families with realistic activity for the demo (emulators only; see seed_guard.ts):
 * children of all ages (siblings and a newborn), measurements near the WHO medians (values only),
 * doses on the MOHP schedule, three active packages (one ending within 14 days), bookings in the
 * past four weeks, today and the next 7 days at both clinics (confirmed, arrived, done, no-show),
 * walk-ins, payments and audit entries. Bookings go through the same reads, checks and fields as
 * `createBooking`, so slots, family limits and prices match what the app and dashboard save.
 */
import type { Auth } from "firebase-admin/auth";
import { FieldValue, Timestamp, type Firestore } from "firebase-admin/firestore";
import { bookingFields, checkSelection, priceFor, readForSelection } from "../src/lib/booking/book";
import { hoursOf, isVaccineDay } from "../src/lib/booking/schedule";
import { readBookingSettings } from "../src/lib/booking/settings";
import type { Selection } from "../src/lib/booking/selection";
import { addDays, cairoDate, slotId, startsAt } from "../src/lib/booking/time";
import { nameKey } from "../src/lib/nameKey";
import { FAMILIES, SCHEDULE, medianAt, type DemoFamily } from "./demo_data";

const STAFF = { "clinic-1": "staff-sec1", "clinic-2": "staff-sec2" } as const;
type ClinicId = keyof typeof STAFF;
const DAY_MS = 24 * 60 * 60 * 1000;
const RETENTION_MS = 365 * DAY_MS;

/** Deterministic pseudo-random numbers, so every seed run gives the same demo. */
function rng(seed: number) {
  let x = seed;
  return () => {
    x = (x * 1103515245 + 12345) % 2147483648;
    return x / 2147483648;
  };
}

function monthsBetween(birth: string, date: string): number {
  return (Date.parse(date) - Date.parse(birth)) / (30.4375 * DAY_MS);
}

function addMonths(date: string, months: number): string {
  const [y, m, d] = date.split("-").map(Number);
  const last = new Date(Date.UTC(y, m - 1 + months + 1, 0)).getUTCDate();
  return new Date(Date.UTC(y, m - 1 + months, Math.min(d, last))).toISOString().slice(0, 10);
}

export async function seedDemoFamilies(db: Firestore, auth: Auth): Promise<void> {
  const today = cairoDate();
  const random = rng(20261027);
  const audit = db.batch();
  const auditAt = (action: string, actorUid: string, at: Date, extra: Record<string, unknown> = {}) =>
    audit.set(db.collection("auditLog").doc(), {
      action, actorUid, ...extra, at: Timestamp.fromDate(at), expiresAt: Timestamp.fromMillis(at.getTime() + RETENTION_MS),
    });

  // Families, children, measurements and doses.
  const base = db.batch();
  for (const [fi, f] of FAMILIES.entries()) {
    const joined = new Date(Date.parse(`${today}T10:00:00Z`) - (120 - fi * 9) * DAY_MS);
    await auth.createUser({ uid: f.uid, phoneNumber: f.phone });
    base.set(db.doc(`guardians/${f.uid}`), {
      phone: f.phone, fullName: f.name, relation: f.relation, consentVersion: 1, clinicChildrenPending: false,
      preferredClinicId: f.clinicId, lastActiveAt: new Date(), createdAt: joined, updatedAt: joined,
    });
    base.set(db.doc(`guardians/${f.uid}/consents/seed`), {
      policyVersion: 1, scopes: ["privacy_policy", "terms", "child_data"], acceptedAt: joined,
    });
    base.set(db.doc(`clinicGuardians/${f.phone}`), { fullName: f.name, relation: f.relation, createdAt: joined });
    auditAt("account.created", f.uid, joined, { subjectPhone: f.phone });
    auditAt("consent.accepted", f.uid, joined, { subjectPhone: f.phone, details: { policyVersion: 1 } });
    if (fi % 3 === 0) {
      auditAt("children.linked", f.uid, joined, { subjectPhone: f.phone, childIds: f.children.map((c) => c.id) });
    }

    for (const c of f.children) {
      base.set(db.doc(`children/${c.id}`), {
        name: c.name, nameKey: nameKey(c.name), birthDate: c.birthDate, sex: c.sex,
        ...(c.allergies ? { allergies: c.allergies } : {}),
        guardianPhone: f.phone, guardianUid: f.uid, registeredBy: fi % 3 === 0 ? "clinic" : "guardian", createdAt: joined,
      });
      seedGrowth(db, base, f, c, today, random);
      seedDoses(db, base, f, c, today);
    }
  }
  await base.commit();

  // Packages: three active, the last one ending within 14 days (the renewal notice).
  const packages: [DemoFamily, ClinicId, string][] = [
    [FAMILIES[0], "clinic-1", addMonths(today, -7)],
    [FAMILIES[4], "clinic-2", addMonths(today, -4)],
    [FAMILIES[7], "clinic-1", addDays(addMonths(today, -12), 9)],
  ];
  for (const [f, clinicId, startsOn] of packages) {
    const price = (await db.doc(`clinics/${clinicId}`).get()).get("packagePrice") as number;
    const ref = db.collection("packages").doc(`demo-pkg-${f.uid}`);
    await ref.set({
      guardianUid: f.uid, soldAtClinicId: clinicId, price, startsOn, endsOn: addMonths(startsOn, 12), active: true,
      soldBy: STAFF[clinicId], soldOn: startsOn, soldAt: Timestamp.fromDate(new Date(`${startsOn}T15:00:00Z`)),
    });
    auditAt("package.sold", STAFF[clinicId], new Date(`${startsOn}T15:00:00Z`), {
      subjectPhone: f.phone, details: { packageId: ref.id, clinicId, price, renew: false },
    });
  }

  // Bookings: past four weeks (done or no-show), today (done, arrived, confirmed) and the next 7 days
  // (confirmed, at most two per family and one a day, never in a day's first two hours so the
  // booking tests keep those hours free).
  let n = 0;
  for (const [fi, f] of FAMILIES.entries()) {
    const clinicId = f.clinicId;
    const other: ClinicId = clinicId === "clinic-1" ? "clinic-2" : "clinic-1";
    const plan: { clinicId: ClinicId; day: number; status: string; slot: "early" | "late" }[] = [
      { clinicId, day: -(6 + fi * 2), status: "done", slot: "early" },
      { clinicId: fi % 2 ? other : clinicId, day: -(15 + fi), status: fi % 4 === 1 ? "no_show" : "done", slot: "late" },
    ];
    if (fi < 6) plan.push({ clinicId: fi % 2 ? "clinic-1" : "clinic-2", day: 0, status: ["done", "arrived", "confirmed"][fi % 3], slot: "early" });
    if (fi < 8) plan.push({ clinicId, day: 1 + (fi % 6), status: "confirmed", slot: "late" });
    for (const p of plan) {
      const done = await book(db, f, p.clinicId, today, p.day, p.status, p.slot, fi + n);
      if (!done) continue;
      n++;
      if (p.status === "done") {
        auditAt("medical.recorded", STAFF[p.clinicId], done.at, { subjectPhone: f.phone, childIds: [f.children[0].id] });
      }
    }
  }

  // Walk-ins: today at both clinics (arrived and done) and a few past ones.
  const walkIns: [ClinicId, number, string, string, string][] = [
    ["clinic-1", 0, "arrived", "عائلة حسن", "+201000000301"],
    ["clinic-2", 0, "done", "عائلة يوسف", "+201000000302"],
    ["clinic-1", -3, "done", "عائلة إبراهيم", "+201000000303"],
    ["clinic-2", -9, "done", "عائلة صلاح", "+201000000304"],
  ];
  for (const [i, [clinicId, day, status, familyName, phone]] of walkIns.entries()) {
    const date = openDay(await readBookingSettings(clinicId), today, day);
    if (!date) continue;
    const settings = await readBookingSettings(clinicId);
    const hours = hoursOf(settings, date);
    const hour = hours[Math.min(hours.length - 1, 2 + i)];
    const arrivedAt = new Date(startsAt(date, hour).getTime() + 5 * 60 * 1000);
    const ref = db.collection("walkIns").doc(`demo-walkin-${i + 1}`);
    await db.runTransaction(async (tx) => {
      const slot = await tx.get(db.doc(`slots/${slotId(clinicId, date, hour)}`));
      tx.set(ref, {
        clinicId, date, hour, familyName, phone, children: [{ childId: null, name: ["كريم", "مريم", "زياد", "هنا"][i] }],
        visitType: "visit", status, arrivedAt: Timestamp.fromDate(arrivedAt), createdBy: STAFF[clinicId],
        createdAt: Timestamp.fromDate(arrivedAt),
        ...(status === "done" ? {
          doneAt: Timestamp.fromDate(new Date(arrivedAt.getTime() + 25 * 60 * 1000)),
          payment: { cash: settings.visitPrice, covered: false, packageId: null, recordedBy: STAFF[clinicId], recordedAt: Timestamp.fromDate(arrivedAt) },
        } : {}),
      });
      tx.set(slot.ref, { clinicId, date, hour, taken: ((slot.get("taken") as number | undefined) ?? 0) + 1 }, { merge: true });
    });
  }

  // Staff opening child files (D-13).
  auditAt("child.opened", "staff-doctor", new Date(Date.now() - 2 * 60 * 60 * 1000), { childIds: ["demo-yehia"] });
  auditAt("child.opened", "staff-sec2", new Date(Date.now() - 26 * 60 * 60 * 1000), { childIds: ["demo-jana"] });
  await audit.commit();
}

/** The [offset]th day from today that the clinic is open (moving away from today when closed). */
function openDay(settings: Awaited<ReturnType<typeof readBookingSettings>>, today: string, offset: number): string | null {
  for (let k = 0; k < 7; k++) {
    const date = addDays(today, offset + (offset < 0 ? -k : k));
    if (hoursOf(settings, date).length > 0) return date;
  }
  return null;
}

/** One booking for the family's first child (and a sibling at the same visit for some families). */
async function book(
  db: Firestore, f: DemoFamily, clinicId: ClinicId, today: string, day: number, status: string, slot: "early" | "late", k: number,
): Promise<{ at: Date } | null> {
  const settings = await readBookingSettings(clinicId);
  const date = openDay(settings, today, day);
  if (!date) return null;
  const hours = hoursOf(settings, date);
  // Never a day's first two hours (the integration tests book those); earlier hours for today's done.
  const usable = hours.slice(2);
  if (usable.length === 0) return null;
  const hour = slot === "early" ? usable[k % Math.min(2, usable.length)] : usable[usable.length - 1 - (k % Math.min(3, usable.length))];
  const vaccineOnly = day > 0 && isVaccineDay(settings, date) && k % 3 === 0;
  const children = f.children.slice(0, k % 4 === 0 ? f.children.length : 1);
  const sel: Selection = {
    visitType: vaccineOnly ? "vaccine_only" : "visit",
    date, hour,
    // A vaccine-only visit is for the seasonal flu vaccine (any child from 6 months).
    children: children.map((c, i) => ({ childId: c.id, vaccines: vaccineOnly && i === 0 ? ["v13"] : [] })),
  };
  const now = new Date();
  try {
    return await db.runTransaction(async (tx) => {
      const r = await readForSelection(tx, f.uid, clinicId, sel, day > 0 ? now : new Date(startsAt(date, hour).getTime() - DAY_MS));
      const counter = await tx.get(db.doc("counters/bookings"));
      if (day > 0) checkSelection(r, sel, now);
      else if (r.taken >= settings.capacityPerHour) return null;
      const price = priceFor(r, sel, null);
      const number = (counter.get("next") as number | undefined) ?? 1;
      const ref = db.collection("bookings").doc();
      const fields = bookingFields(r, sel, price);
      const begins = startsAt(date, hour);
      const arrivedAt = new Date(begins.getTime() + 10 * 60 * 1000);
      const doneAt = new Date(begins.getTime() + 35 * 60 * 1000);
      const by = STAFF[clinicId];
      tx.set(ref, {
        ...fields, number, guardianUid: f.uid, guardianPhone: f.phone, status,
        createdAt: Timestamp.fromDate(new Date(begins.getTime() - 3 * DAY_MS)),
        ...(status === "arrived" || status === "done" ? { arrivedAt: Timestamp.fromDate(arrivedAt), statusBy: by } : {}),
        ...(status === "done" ? { doneAt: Timestamp.fromDate(doneAt) } : {}),
        ...(status === "no_show" ? { statusBy: by } : {}),
        ...(status === "arrived" || status === "done" ? {
          payment: {
            cash: price.total, covered: price.visit?.covered === true, packageId: price.visit?.covered ? price.packageId : null,
            recordedBy: by, recordedAt: Timestamp.fromDate(arrivedAt),
          },
        } : {}),
      });
      tx.set(r.slotRef, { clinicId, date, hour, taken: r.taken + 1 }, { merge: true });
      tx.set(db.doc("counters/bookings"), { next: number + 1 });
      if (day > 0 || (day === 0 && status === "confirmed")) {
        tx.set(r.quotaRef, { active: [...r.quota, { bookingId: ref.id, date, startsAt: fields.startsAt, clinicId }] });
      }
      tx.set(ref.collection("events").doc(), { type: "created", by: f.uid, at: FieldValue.serverTimestamp(), to: { date, hour } });
      if (status === "done") {
        // As queueAction "done": a visit per child, linked to the booking; with this visit's measurement.
        for (const c of children) {
          tx.set(db.doc(`children/${c.id}/visits/${ref.id}`), {
            date, type: vaccineOnly ? "vaccine" : "clinic", clinicId, bookingId: ref.id, createdAt: Timestamp.fromDate(doneAt),
          });
        }
        const c = children[0];
        const m = medianAt(c.sex, monthsBetween(c.birthDate, date));
        const head = monthsBetween(c.birthDate, date) <= 24;
        tx.set(db.doc(`children/${c.id}/measurements/${ref.id}-m`), {
          measuredOn: date, weightKg: round(m.weightKg * 1.01, 0.1), lengthCm: round(m.lengthCm, 0.5),
          ...(head ? { headCm: round(m.headCm, 0.1) } : {}), visitId: ref.id, clinicId, recordedBy: by, recordedAt: Timestamp.fromDate(doneAt),
        });
      }
      return { at: doneAt };
    });
  } catch {
    // A family limit, a full hour or a closed day: skip this one (the demo needs no exact count).
    return null;
  }
}

function round(v: number, step: 0.1 | 0.5): number {
  return step === 0.5 ? Math.round(v * 2) / 2 : Number(v.toFixed(1));
}

/** Clinic visits with measurements at the usual follow-up ages, near the WHO medians (values only). */
function seedGrowth(
  db: Firestore, batch: FirebaseFirestore.WriteBatch, f: DemoFamily, c: DemoFamily["children"][number], today: string, random: () => number,
) {
  const factor = 0.96 + random() * 0.08;
  const ages = [0.25, 1, 2, 4, 6, 9, 12, 18, 24, 36];
  let v = 0;
  for (const months of ages) {
    const date = months < 1 ? addDays(c.birthDate, 7) : addMonths(c.birthDate, months);
    // Leave the last month for the seeded bookings' own visits.
    if (date > addDays(today, -35)) break;
    v++;
    const id = `${c.id}-v${v}`;
    const clinicId = v % 3 === 0 ? (f.clinicId === "clinic-1" ? "clinic-2" : "clinic-1") : f.clinicId;
    const m = medianAt(c.sex, months);
    const child = db.doc(`children/${c.id}`);
    batch.set(child.collection("visits").doc(id), {
      date, type: "clinic", clinicId, bookingId: null, createdAt: new Date(`${date}T16:00:00Z`),
    });
    batch.set(child.collection("measurements").doc(`${id}-m`), {
      measuredOn: date,
      weightKg: Number((m.weightKg * factor).toFixed(1)),
      lengthCm: Math.round(m.lengthCm * (0.99 + (factor - 1) / 3) * 2) / 2,
      ...(months <= 24 ? { headCm: Number(m.headCm.toFixed(1)) } : {}),
      visitId: id, clinicId, recordedBy: STAFF[clinicId as ClinicId], recordedAt: new Date(`${date}T16:10:00Z`),
    });
  }
}

/** Doses on the MOHP schedule given a few days after they were due; ريان's latest one is still due. */
function seedDoses(db: Firestore, batch: FirebaseFirestore.WriteBatch, f: DemoFamily, c: DemoFamily["children"][number], today: string) {
  let i = 0;
  for (const e of SCHEDULE) {
    const due = addMonths(c.birthDate, e.months);
    if (due > addDays(today, -3)) continue;
    if (c.id === "demo-rayan" && e.months === 9) continue;
    i++;
    const givenOn = e.months === 0 ? addDays(c.birthDate, 1) : addDays(due, i % 4);
    batch.set(db.doc(`children/${c.id}/doses/${e.id}`), {
      scheduleId: e.id, vaccineId: e.vaccineId, dose: e.dose, givenOn, lot: `EG-${e.id.toUpperCase()}-${(i * 37) % 900 + 100}`,
      visitId: null, clinicId: f.clinicId, recordedBy: STAFF[f.clinicId], recordedAt: new Date(`${givenOn}T15:00:00Z`),
    });
  }
  // A few optional vaccines, as families often choose them.
  if (["demo-layan", "demo-yasmin", "demo-seif"].includes(c.id)) {
    const [vaccineId, months] = c.id === "demo-layan" ? ["v3", 2] : ["v10", 12];
    const givenOn = addMonths(c.birthDate, months);
    if (givenOn <= today) {
      batch.set(db.doc(`children/${c.id}/doses/opt-${vaccineId}`), {
        scheduleId: null, vaccineId, dose: 1, givenOn, lot: `EG-${vaccineId.toUpperCase()}-201`, visitId: null,
        clinicId: f.clinicId, recordedBy: STAFF[f.clinicId], recordedAt: new Date(`${givenOn}T15:00:00Z`),
      });
    }
  }
}
