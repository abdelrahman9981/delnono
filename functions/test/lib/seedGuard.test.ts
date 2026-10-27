import { strict as assert } from "node:assert";
import { assertEmulatorOnly } from "../../scripts/seed_guard";

describe("seed guard (launch checklist: no proposed medical content in production)", () => {
  const emulators = { FIRESTORE_EMULATOR_HOST: "127.0.0.1:8080", FIREBASE_AUTH_EMULATOR_HOST: "127.0.0.1:9099" };

  it("allows the demo-* project on the emulators", () => {
    assert.doesNotThrow(() => assertEmulatorOnly("demo-delnono", emulators));
  });

  it("refuses the real project, even on the emulators", () => {
    assert.throws(() => assertEmulatorOnly("dr-elnono-clinic", emulators), /demo-\* emulator projects only/);
    assert.throws(() => assertEmulatorOnly("demo-delnono", { ...emulators, GCLOUD_PROJECT: "dr-elnono-clinic" }), /GCLOUD_PROJECT/);
  });

  it("refuses without the emulators", () => {
    assert.throws(() => assertEmulatorOnly("demo-delnono", {}), /FIRESTORE_EMULATOR_HOST/);
    assert.throws(() => assertEmulatorOnly("demo-delnono", { FIRESTORE_EMULATOR_HOST: "x" }), /FIREBASE_AUTH_EMULATOR_HOST/);
  });
});
