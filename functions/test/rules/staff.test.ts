import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { collection, doc, getDoc, getDocs, query, setDoc, where } from "firebase/firestore";
import { adminDb, clearEmulators, rulesEnv, seedChild, seedGuardian, seedSettings } from "../helpers/env";

// contracts/firestore-access.md (005): staff reads by role and clinic; staff never write directly.

describe("rules: staff (005)", () => {
  let env: RulesTestEnvironment;

  before(async () => {
    env = await rulesEnv();
  });
  after(async () => env.cleanup());

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    const db = adminDb();
    const staff = [
      ["doc", "doctor", null, true],
      ["sec1", "secretary", "clinic-1", true],
      ["off", "secretary", "clinic-1", false],
    ] as const;
    for (const [uid, role, clinicId, active] of staff) await db.doc(`staff/${uid}`).set({ role, clinicId, active, name: uid });
    await seedGuardian("g1", { phone: "+201000000099" });
    await seedChild("kid", { guardianUid: "g1", guardianPhone: "+201000000099" });
    await db.doc("bookings/b1").set({ clinicId: "clinic-1", guardianUid: "g1", date: "2026-11-15", status: "confirmed" });
    await db.doc("bookings/b2").set({ clinicId: "clinic-2", guardianUid: "g1", date: "2026-11-15", status: "confirmed" });
    await db.doc("walkIns/w2").set({ clinicId: "clinic-2", date: "2026-11-15" });
    await db.doc("days/clinic-2_2026-11-15").set({ clinicId: "clinic-2", walkInsStopped: true });
    await db.doc("content/pub").set({ status: "published", title: "[نصيحة]" });
    await db.doc("content/draft").set({ status: "draft", title: "[مسودة]" });
    await db.doc("auditLog/a1").set({ action: "child.opened" });
    await db.doc("packages/p1").set({ guardianUid: "g1", active: true });
  });

  const as = (uid: string, claims: Record<string, unknown> = {}) => env.authenticatedContext(uid, claims).firestore();
  const sec1 = () => as("sec1", { role: "secretary", clinicId: "clinic-1" });
  const docr = () => as("doc", { role: "doctor", clinicId: null });

  it("a secretary reads her clinic's bookings, not the other clinic's (D-47)", async () => {
    await assertSucceeds(getDoc(doc(sec1(), "bookings/b1")));
    await assertFails(getDoc(doc(sec1(), "bookings/b2")));
    await assertSucceeds(getDocs(query(collection(sec1(), "bookings"), where("clinicId", "==", "clinic-1"))));
    await assertFails(getDocs(query(collection(sec1(), "bookings"), where("clinicId", "==", "clinic-2"))));
  });

  it("a secretary is refused the other clinic's walk-ins and day status", async () => {
    await assertFails(getDoc(doc(sec1(), "walkIns/w2")));
    await assertFails(getDoc(doc(sec1(), "days/clinic-2_2026-11-15")));
  });

  it("the doctor reads every clinic and the audit log; the secretary not the log (D-13)", async () => {
    await assertSucceeds(getDoc(doc(docr(), "bookings/b2")));
    await assertSucceeds(getDoc(doc(docr(), "walkIns/w2")));
    await assertSucceeds(getDoc(doc(docr(), "auditLog/a1")));
    await assertFails(getDoc(doc(sec1(), "auditLog/a1")));
  });

  it("a disabled staff member reads nothing", async () => {
    const off = as("off", { role: "secretary", clinicId: "clinic-1" });
    await assertFails(getDoc(doc(off, "bookings/b1")));
    await assertFails(getDoc(doc(off, "content/draft")));
  });

  it("a claim without a staff document is refused", async () => {
    await assertFails(getDoc(doc(as("ghost", { role: "doctor" }), "bookings/b1")));
  });

  it("staff read child records only through openChildFile (audit)", async () => {
    await assertFails(getDoc(doc(sec1(), "children/kid")));
    await assertFails(getDoc(doc(docr(), "children/kid")));
  });

  it("content: published for everyone, drafts for staff only (D-19)", async () => {
    const anon = env.unauthenticatedContext().firestore();
    await assertSucceeds(getDoc(doc(anon, "content/pub")));
    await assertFails(getDoc(doc(anon, "content/draft")));
    await assertFails(getDoc(doc(as("g1"), "content/draft")));
    await assertSucceeds(getDoc(doc(sec1(), "content/draft")));
  });

  it("staff documents: self and the doctor", async () => {
    await assertSucceeds(getDoc(doc(sec1(), "staff/sec1")));
    await assertFails(getDoc(doc(sec1(), "staff/doc")));
    await assertSucceeds(getDoc(doc(docr(), "staff/sec1")));
    await assertFails(getDoc(doc(as("g1"), "staff/sec1")));
  });

  it("a guardian still reads her own booking and package, not staff data", async () => {
    await assertSucceeds(getDoc(doc(as("g1"), "bookings/b1")));
    await assertSucceeds(getDoc(doc(as("g1"), "packages/p1")));
    await assertFails(getDoc(doc(as("g1"), "walkIns/w2")));
  });

  it("staff never write directly", async () => {
    await assertFails(setDoc(doc(docr(), "bookings/b1"), { status: "arrived" }));
    await assertFails(setDoc(doc(docr(), "content/new"), { status: "published" }));
    await assertFails(setDoc(doc(docr(), "staff/x"), { role: "doctor" }));
  });

  it("staff register, merge and link only through callables (009)", async () => {
    await assertFails(setDoc(doc(sec1(), "children/new"), { name: "[طفل]", guardianPhone: "+201000000077", guardianUid: null }));
    await assertFails(setDoc(doc(docr(), "children/kid"), { merged: { into: "other" } }, { merge: true }));
    await assertFails(setDoc(doc(sec1(), "clinicGuardians/+201000000077"), { fullName: "[أم]" }));
    await assertFails(getDoc(doc(sec1(), "clinicGuardians/+201000000099")));
    await assertFails(setDoc(doc(sec1(), "linkAttempts/+201000000099"), { failedCount: 0 }));
  });

  it("a closed (merged) file is not readable by its former guardian (009 FR-007)", async () => {
    await seedChild("closed", { guardianUid: null, guardianPhone: null, nameKey: null, merged: { into: "kid", guardianUid: "g1" } });
    await assertFails(getDoc(doc(as("g1"), "children/closed")));
    await assertSucceeds(getDoc(doc(as("g1"), "children/kid")));
  });
});
