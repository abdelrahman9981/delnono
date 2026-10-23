import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { collection, doc, getDoc, getDocs, query, setDoc, updateDoc, where } from "firebase/firestore";
import { adminDb, clearEmulators, rulesEnv, seedGuardian, seedSettings } from "../helpers/env";

// contracts/firestore-access.md (002): bookings, bookings/{id}/events, packages.

const DAY = 24 * 60 * 60 * 1000;

describe("rules: bookings and packages", () => {
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
    const db = adminDb();
    await db.doc("bookings/b1").set({ guardianUid: "u1", status: "confirmed", number: 1 });
    await db.doc("bookings/b1/events/e1").set({ type: "created", by: "u1" });
    await db.doc("bookings/b2").set({ guardianUid: "u2", status: "confirmed", number: 2 });
    await db.doc("packages/p1").set({ guardianUid: "u1", active: true, startsOn: "2026-01-01", endsOn: "2026-12-31" });
  });

  const as = (uid: string) => env.authenticatedContext(uid).firestore();

  it("the owner reads their booking, its events and lists with the guardianUid filter", async () => {
    await assertSucceeds(getDoc(doc(as("u1"), "bookings/b1")));
    await assertSucceeds(getDocs(collection(as("u1"), "bookings/b1/events")));
    await assertSucceeds(getDocs(query(collection(as("u1"), "bookings"), where("guardianUid", "==", "u1"))));
  });

  it("other guardians and unfiltered lists are denied", async () => {
    await assertFails(getDoc(doc(as("u1"), "bookings/b2")));
    await assertFails(getDocs(collection(as("u2"), "bookings/b1/events")));
    await assertFails(getDocs(collection(as("u1"), "bookings")));
  });

  it("outdated consent or inactivity closes bookings (001 rules)", async () => {
    await seedSettings({ policy: { currentVersion: 2 } });
    await assertFails(getDoc(doc(as("u1"), "bookings/b1")));
    await seedSettings();
    await seedGuardian("u1", { phone: "+201000000099", lastActiveAt: new Date(Date.now() - 91 * DAY) });
    await assertFails(getDoc(doc(as("u1"), "bookings/b1")));
  });

  it("no client writes to bookings or events", async () => {
    await assertFails(setDoc(doc(as("u1"), "bookings/b3"), { guardianUid: "u1", status: "confirmed" }));
    await assertFails(updateDoc(doc(as("u1"), "bookings/b1"), { status: "cancelled" }));
    await assertFails(updateDoc(doc(as("u1"), "bookings/b1"), { "price.total": 0 }));
    await assertFails(setDoc(doc(as("u1"), "bookings/b1/events/e2"), { type: "cancelled" }));
  });

  it("packages: the owner reads, nobody writes", async () => {
    await assertSucceeds(getDoc(doc(as("u1"), "packages/p1")));
    await assertFails(getDoc(doc(as("u2"), "packages/p1")));
    await assertFails(setDoc(doc(as("u1"), "packages/p2"), { guardianUid: "u1", active: true }));
  });
});
