import { strict as assert } from "node:assert";
import { PROD_PROJECT, assertEmulatorOnly, confirmTyped, seedTarget } from "../../scripts/seed_guard";

describe("seed guard (launch checklist: no proposed medical content in production)", () => {
  const emulators = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080", FIREBASE_AUTH_EMULATOR_HOST: "127.0.0.1:9099" };

  it("allows the demo-* project on the emulators", () => {
    assert.doesNotThrow(() => assertEmulatorOnly("demo-delnono", emulators));
    assert.deepEqual(seedTarget(["node", "seed.ts"], emulators), { projectId: "demo-delnono", prod: false, wipe: false });
  });

  it("refuses the real project, even on the emulators", () => {
    assert.throws(() => assertEmulatorOnly("dr-elnono-clinic", emulators), /demo-\* emulator projects only/);
    assert.throws(() => assertEmulatorOnly("demo-delnono", { ...emulators, GCLOUD_PROJECT: "dr-elnono-clinic" }), /GCLOUD_PROJECT/);
  });

  it("refuses without the emulators", () => {
    assert.throws(() => assertEmulatorOnly("demo-delnono", {}), /FIRESTORE_EMULATOR_HOST/);
    assert.throws(() => assertEmulatorOnly("demo-delnono", { FIRESTORE_EMULATOR_HOST: "x" }), /FIREBASE_AUTH_EMULATOR_HOST/);
    assert.throws(() => seedTarget(["node", "seed.ts"], {}), /FIRESTORE_EMULATOR_HOST/);
  });

  it("the client demo needs --demo-prod, the real project's name and no emulator settings (D-43)", () => {
    const prod = { GCLOUD_PROJECT: PROD_PROJECT };
    assert.deepEqual(seedTarget(["node", "seed.ts", "--demo-prod"], prod), { projectId: PROD_PROJECT, prod: true, wipe: false });
    assert.deepEqual(seedTarget(["node", "seed.ts", "--demo-prod", "--wipe"], prod).wipe, true);
    assert.throws(() => seedTarget(["node", "seed.ts", "--demo-prod"], { ...prod, ...emulators }), /FIRESTORE_EMULATOR_HOST is set/);
    assert.throws(() => seedTarget(["node", "seed.ts", "--demo-prod"], { GCLOUD_PROJECT: "other-project" }), /seed:demo-prod/);
    assert.throws(() => seedTarget(["node", "seed.ts", "--wipe"], emulators), /--demo-prod/);
  });

  it("writes nothing unless the project name is typed exactly", async () => {
    await assert.doesNotReject(confirmTyped(PROD_PROJECT, async () => ` ${PROD_PROJECT}\n`, "write"));
    await assert.rejects(confirmTyped(PROD_PROJECT, async () => "yes", "write"), /Not confirmed/);
    await assert.rejects(confirmTyped(PROD_PROJECT, async () => "", "write"), /Not confirmed/);
  });
});
