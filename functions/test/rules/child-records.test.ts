import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { collection, deleteDoc, doc, getDoc, getDocs, setDoc, updateDoc } from "firebase/firestore";
import { adminDb, clearEmulators, rulesEnv, seedChild, seedGuardian, seedSettings } from "../helpers/env";

// contracts/firestore-access.md (003): measurements, doses, visits and staff-only documents under a
// child; the schedule and follow-up lists.

const DAY = 24 * 60 * 60 * 1000;
const RECORDS = ["measurements/m1", "doses/d1", "visits/v1"];

describe("rules: child records (003)", () => {
  let env: RulesTestEnvironment;

  before(async () => {
    env = await rulesEnv();
  });
  after(async () => env.cleanup());

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedGuardian("u1", { phone: "+201000000099" });
    await seedGuardian("u2", { phone: "+201000000088" });
    await seedChild("mine", { guardianUid: "u1", guardianPhone: "+201000000099" });
    await seedChild("theirs", { guardianUid: "u2", guardianPhone: "+201000000088" });
    const db = adminDb();
    for (const child of ["mine", "theirs"]) {
      await db.doc(`children/${child}/measurements/m1`).set({ measuredOn: "2026-09-15", weightKg: 9.4 });
      await db.doc(`children/${child}/measurements/m1/changes/c1`).set({ from: 9.3, to: 9.4 });
      await db.doc(`children/${child}/doses/d1`).set({ scheduleId: "s01", vaccineId: "v1", givenOn: "2026-01-21", lot: "L1" });
      await db.doc(`children/${child}/visits/v1`).set({ date: "2026-09-15", type: "clinic" });
      await db.doc(`children/${child}/visits/v1/staff/notes`).set({ text: "[ملاحظة]" });
    }
    await db.doc("vaccineSchedule/s01").set({ vaccineId: "v1", dose: 1, dueAge: { months: 0, days: 0 }, order: 0 });
    await db.doc("followUp/b0").set({ fromMonths: 0, toMonths: 2, title: "[متابعة]", items: [] });
    await db.doc("settings/vaccines").set({ source: "[مصدر]", lateAfterDays: 7 });
    await db.doc("settings/followUp").set({ maxAgeMonths: 48, dangerSigns: [] });
  });

  const as = (uid: string) => env.authenticatedContext(uid).firestore();
  const anon = () => env.unauthenticatedContext().firestore();

  it("the linked guardian reads and lists the child's records", async () => {
    for (const path of RECORDS) {
      await assertSucceeds(getDoc(doc(as("u1"), `children/mine/${path}`)));
      await assertSucceeds(getDocs(collection(as("u1"), `children/mine/${path.split("/")[0]}`)));
    }
  });

  it("another guardian, a user without a guardian doc, and anonymous are denied", async () => {
    for (const path of RECORDS) {
      await assertFails(getDoc(doc(as("u1"), `children/theirs/${path}`)));
      await assertFails(getDocs(collection(as("u1"), `children/theirs/${path.split("/")[0]}`)));
      await assertFails(getDoc(doc(as("u9"), `children/mine/${path}`)));
      await assertFails(getDoc(doc(anon(), `children/mine/${path}`)));
    }
  });

  it("a guardian whose consent is outdated is denied (001 FR-017)", async () => {
    await seedSettings({ policy: { currentVersion: 2 } });
    for (const path of RECORDS) await assertFails(getDoc(doc(as("u1"), `children/mine/${path}`)));
  });

  it("a guardian inactive beyond reverifyAfterDays is denied (001 FR-010a)", async () => {
    await seedGuardian("u1", { phone: "+201000000099", lastActiveAt: new Date(Date.now() - 91 * DAY) });
    for (const path of RECORDS) await assertFails(getDoc(doc(as("u1"), `children/mine/${path}`)));
  });

  it("the linked guardian cannot create, change or delete records", async () => {
    for (const path of RECORDS) {
      const ref = doc(as("u1"), `children/mine/${path}`);
      await assertFails(setDoc(doc(as("u1"), `children/mine/${path}-new`), { measuredOn: "2026-10-01" }));
      await assertFails(updateDoc(ref, { lot: "X" }));
      await assertFails(deleteDoc(ref));
    }
  });

  it("staff-only documents (doctor's notes, correction log) are denied to the linked guardian", async () => {
    for (const path of ["visits/v1/staff/notes", "measurements/m1/changes/c1"]) {
      await assertFails(getDoc(doc(as("u1"), `children/mine/${path}`)));
      await assertFails(setDoc(doc(as("u1"), `children/mine/${path}`), { text: "x" }));
    }
  });

  it("schedule and follow-up lists: signed-in read only", async () => {
    for (const path of ["vaccineSchedule/s01", "followUp/b0"]) {
      await assertSucceeds(getDoc(doc(as("u1"), path)));
      await assertSucceeds(getDocs(collection(as("u1"), path.split("/")[0])));
      await assertFails(getDoc(doc(anon(), path)));
      await assertFails(setDoc(doc(as("u1"), path), { order: 9 }));
    }
  });

  it("settings/vaccines and settings/followUp are readable like other settings, never writable", async () => {
    for (const path of ["settings/vaccines", "settings/followUp"]) {
      await assertSucceeds(getDoc(doc(anon(), path)));
      await assertFails(setDoc(doc(as("u1"), path), { x: 1 }));
    }
  });
});
