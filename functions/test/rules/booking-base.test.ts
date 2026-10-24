import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { collection, deleteDoc, doc, getDoc, getDocs, setDoc } from "firebase/firestore";
import { adminDb, clearEmulators, rulesEnv, seedSettings } from "../helpers/env";

// contracts/firestore-access.md (002): settings/booking, vaccines, slots, counters, familyQuota.

describe("rules: booking base", () => {
  let env: RulesTestEnvironment;

  before(async () => {
    env = await rulesEnv();
  });
  after(async () => env.cleanup());

  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    const db = adminDb();
    await db.doc("settings/booking").set({ capacityPerHour: 6 });
    await db.doc("vaccines/v1").set({ name: "[تطعيم]", price: 150, showPrice: true, active: true });
    await db.doc("slots/2026-11-15_18").set({ date: "2026-11-15", hour: 18, taken: 2 });
    await db.doc("counters/bookings").set({ next: 1 });
    await db.doc("familyQuota/u1").set({ active: [] });
  });

  const user = () => env.authenticatedContext("u1").firestore();
  const anon = () => env.unauthenticatedContext().firestore();

  it("settings/booking is readable like other settings, never writable", async () => {
    await assertSucceeds(getDoc(doc(anon(), "settings/booking")));
    await assertFails(setDoc(doc(user(), "settings/booking"), { capacityPerHour: 99 }));
  });

  it("vaccines: signed-in read only", async () => {
    await assertSucceeds(getDoc(doc(user(), "vaccines/v1")));
    await assertSucceeds(getDocs(collection(user(), "vaccines")));
    await assertFails(getDoc(doc(anon(), "vaccines/v1")));
    await assertFails(setDoc(doc(user(), "vaccines/v1"), { price: 0 }));
  });

  it("slots: signed-in read only", async () => {
    await assertSucceeds(getDoc(doc(user(), "slots/2026-11-15_18")));
    await assertFails(getDoc(doc(anon(), "slots/2026-11-15_18")));
    await assertFails(setDoc(doc(user(), "slots/2026-11-15_18"), { taken: 0 }));
    await assertFails(deleteDoc(doc(user(), "slots/2026-11-15_18")));
  });

  it("counters and familyQuota are server only", async () => {
    for (const path of ["counters/bookings", "familyQuota/u1"]) {
      await assertFails(getDoc(doc(user(), path)));
      await assertFails(setDoc(doc(user(), path), { x: 1 }));
    }
  });
});
