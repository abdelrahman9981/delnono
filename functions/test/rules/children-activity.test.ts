import { assertFails, assertSucceeds, type RulesTestEnvironment } from "@firebase/rules-unit-testing";
import { doc, getDoc, serverTimestamp, setDoc, updateDoc } from "firebase/firestore";
import { clearEmulators, rulesEnv, seedChild, seedGuardian, seedSettings } from "../helpers/env";

// FR-010a: child data is closed to a guardian inactive for longer than reverifyAfterDays.

const DAY = 24 * 60 * 60 * 1000;

describe("rules: children activity (re-check after inactivity)", () => {
  let env: RulesTestEnvironment;

  before(async () => {
    env = await rulesEnv();
  });
  after(async () => env.cleanup());

  async function seed(daysAgo: number, reverifyAfterDays = 90) {
    await clearEmulators();
    await seedSettings({ auth: { reverifyAfterDays } });
    await seedGuardian("u1", { phone: "+201000000099", lastActiveAt: new Date(Date.now() - daysAgo * DAY) });
    await seedChild("mine", { guardianUid: "u1", guardianPhone: "+201000000099" });
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), "children/mine/history/h1"), { changedBy: "u1" });
    });
  }

  const db = () => env.authenticatedContext("u1").firestore();
  const edit = () => updateDoc(doc(db(), "children/mine"), { name: "يوسف", updatedBy: "u1", updatedAt: serverTimestamp() });

  it("active within the window: read, edit and history are allowed", async () => {
    await seed(89);
    await assertSucceeds(getDoc(doc(db(), "children/mine")));
    await assertSucceeds(edit());
    await assertSucceeds(getDoc(doc(db(), "children/mine/history/h1")));
  });

  it("inactive beyond the window: read, edit and history are denied", async () => {
    await seed(91);
    await assertFails(getDoc(doc(db(), "children/mine")));
    await assertFails(edit());
    await assertFails(getDoc(doc(db(), "children/mine/history/h1")));
  });

  it("the window comes from settings/auth.reverifyAfterDays", async () => {
    await seed(31, 30);
    await assertFails(getDoc(doc(db(), "children/mine")));
    await seed(29, 30);
    await assertSucceeds(getDoc(doc(db(), "children/mine")));
  });

  it("the guardian cannot refresh lastActiveAt themselves", async () => {
    await seed(91);
    await assertFails(updateDoc(doc(db(), "guardians/u1"), { lastActiveAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  });
});
