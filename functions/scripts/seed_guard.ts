/**
 * Where the seed (and its proposed, unapproved medical content) may write:
 * - by default only the emulators of a `demo-*` project;
 * - the D-43 client demo on dr-elnono-clinic only with the explicit `--demo-prod` flag, no emulator
 *   settings and the project's name typed at the prompt (docs/demo-runbook.md). Before the real
 *   launch the demo data is wiped (`--demo-prod --wipe`) and every proposed item approved or removed
 *   (docs/launch-checklist.md).
 */
export const PROD_PROJECT = "dr-elnono-clinic";

type Env = Record<string, string | undefined>;
const EMULATOR_KEYS = ["FIRESTORE_EMULATOR_HOST", "FIREBASE_AUTH_EMULATOR_HOST"];

export function assertEmulatorOnly(projectId: string, env: Env): void {
  if (!projectId.startsWith("demo-")) {
    throw new Error(`Refusing to seed "${projectId}": the demo seed is for demo-* emulator projects only.`);
  }
  for (const key of EMULATOR_KEYS) {
    if (!env[key]) throw new Error(`Refusing to seed: ${key} is not set (emulators only).`);
  }
  if (env.GCLOUD_PROJECT && !env.GCLOUD_PROJECT.startsWith("demo-")) {
    throw new Error(`Refusing to seed: GCLOUD_PROJECT is "${env.GCLOUD_PROJECT}".`);
  }
}

export interface SeedTarget {
  projectId: string;
  /** The client demo on dr-elnono-clinic (D-43). */
  prod: boolean;
  /** Delete the demo data instead of writing it (prod only). */
  wipe: boolean;
}

/** Reads the command line: the emulators unless `--demo-prod` is given, checked either way. */
export function seedTarget(argv: string[], env: Env): SeedTarget {
  const prod = argv.includes("--demo-prod");
  const wipe = argv.includes("--wipe");
  if (!prod) {
    if (wipe) throw new Error("--wipe is for the client demo only (with --demo-prod).");
    assertEmulatorOnly("demo-delnono", env);
    return { projectId: "demo-delnono", prod: false, wipe: false };
  }
  for (const key of EMULATOR_KEYS) {
    if (env[key]) throw new Error(`Refusing --demo-prod: ${key} is set (this command is for ${PROD_PROJECT}, not the emulators).`);
  }
  if (env.GCLOUD_PROJECT !== PROD_PROJECT) {
    throw new Error(`Refusing --demo-prod: run it with "npm run seed:demo-prod" (GCLOUD_PROJECT=${PROD_PROJECT}).`);
  }
  return { projectId: PROD_PROJECT, prod: true, wipe };
}

/** The operator types the project's name; anything else stops before a single write. */
export async function confirmTyped(expected: string, ask: (question: string) => Promise<string>, action: string): Promise<void> {
  const answer = await ask(`This will ${action} on ${expected}. Type the project name to continue: `);
  if (answer.trim() !== expected) throw new Error("Not confirmed; nothing was written.");
}
