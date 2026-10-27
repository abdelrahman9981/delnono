/**
 * The seed (and its proposed, unapproved medical content) runs only against the emulators of a
 * `demo-*` project. It refuses anything else, so it can never write to dr-elnono-clinic
 * (docs/launch-checklist.md).
 */
export function assertEmulatorOnly(projectId: string, env: Record<string, string | undefined>): void {
  if (!projectId.startsWith("demo-")) {
    throw new Error(`Refusing to seed "${projectId}": the demo seed is for demo-* emulator projects only.`);
  }
  for (const key of ["FIRESTORE_EMULATOR_HOST", "FIREBASE_AUTH_EMULATOR_HOST"]) {
    if (!env[key]) throw new Error(`Refusing to seed: ${key} is not set (emulators only).`);
  }
  if (env.GCLOUD_PROJECT && !env.GCLOUD_PROJECT.startsWith("demo-")) {
    throw new Error(`Refusing to seed: GCLOUD_PROJECT is "${env.GCLOUD_PROJECT}".`);
  }
}
