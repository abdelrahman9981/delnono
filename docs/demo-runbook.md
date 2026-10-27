# Client demo runbook (D-43)

The client demo is two web links on the real project `dr-elnono-clinic`:

| Link | What | Hosting site (proposed) | Address |
|---|---|---|---|
| 1 | Guardian app (Flutter Web). Desktop: centred 390×844 phone frame with the app name; phone: full screen | default site `dr-elnono-clinic` | https://dr-elnono-clinic.web.app |
| 2 | Clinic dashboard (Flutter Web), desktop | second site `dr-elnono-dashboard` (if taken: `dr-elnono-clinic-dashboard`) | https://dr-elnono-dashboard.web.app |

Everything is prepared in the repository (builds, Hosting targets in `firebase.json` / `.firebaserc`,
rules, indexes, functions in `me-central1`, demo seed). **Nothing is deployed and no console setting
is changed without the owner.** Part A is done by the owner in the console; part B is run by Claude
Code only after the owner approves each step.

## A. Owner does in the Firebase / Google Cloud console

1. **Blaze + budget alert** (D-40). Firebase console → ⚙ → Usage and billing → Details & settings →
   Modify plan → Blaze, with the clinic's billing account. Then Google Cloud console → Billing →
   Budgets & alerts → Create budget: scope `dr-elnono-clinic`, amount **1 USD**, alerts at 50 %, 90 %,
   100 % to the owner and the developer.
2. **Web app** (gives the web config). Firebase console → ⚙ Project settings → General → Your apps →
   **Add app → Web (</>)** → nickname `drelnono-web` → do **not** tick "Also set up Firebase Hosting"
   → Register app. From the `firebaseConfig` shown, send the developer `appId` and `apiKey` (public
   client identifiers, not secrets).
   Alternative after approval: Claude Code runs
   `flutterfire configure --project=dr-elnono-clinic --platforms=web --out=/tmp/web_options.dart`
   (creates the same Web app) and copies the two values.
3. **Second Hosting site** for the dashboard. Firebase console → Hosting → Get started (if first
   time; skip the CLI steps) → Advanced → **Add another site** → site id `dr-elnono-dashboard`
   (if taken, `dr-elnono-clinic-dashboard`, and tell the developer so `.firebaserc` matches).
4. **Authorized domains.** Authentication → Settings → Authorized domains: check `dr-elnono-clinic.web.app`
   and `dr-elnono-clinic.firebaseapp.com` are there (they are by default) and **Add domain**
   `dr-elnono-dashboard.web.app` (and `localhost` stays for testing). Phone sign-in on the web uses an
   invisible reCAPTCHA on these domains.
5. Already done (D-53, D-54): Firestore in me-central1, phone sign-in, test numbers 0001, 0003, 0099,
   0201 with 123456, Email/Password sign-in for staff.

## B. Claude Code runs, after the owner approves each step

Prerequisite on the developer's machine: `functions/node_modules/.bin/firebase login` as an owner of
the project, and `gcloud auth application-default login` (for the seed script). No keys are stored in
files or git.

1. **Web builds** with the Web app config from A2:
   `FIREBASE_WEB_APP_ID=… FIREBASE_WEB_API_KEY=… scripts/build_web_demo.sh prod`
   (builds `build/web_app` and `build/web_dashboard`; refuses a build that contains emulator-only
   code such as the D-51 code swap).
2. **Rules and indexes:**
   `functions/node_modules/.bin/firebase deploy --project prod --only firestore:rules,firestore:indexes`
3. **Functions** (region me-central1, same as Firestore):
   `functions/node_modules/.bin/firebase deploy --project prod --only functions`
4. **Hosting** (both sites):
   `functions/node_modules/.bin/firebase deploy --project prod --only hosting:app,hosting:dashboard`
5. **Demo data:** `cd functions && npm run seed:demo-prod` → type `dr-elnono-clinic` at the prompt.
   It writes the clinics, prices, the proposed medical content (badged «مقترح · يراجعه الدكتور»), the
   content library and ten fictional families with bookings around the run day, and creates the
   staff accounts (doctor, one secretary per clinic) with **random passwords printed once in the
   terminal** (never saved). Only the console test numbers get sign-in accounts (0001 family, 0201
   family); 0003 links its clinic children at sign-in; 0099 is a new guardian.
6. **Check:** open both links; sign in on link 1 with 0201 and 123456; on link 2 with the doctor's
   email and printed password.

## Demo day

- Guardian (link 1): **0201** (هالة, newborn آدم and ياسمين, a package), **0001** (سارة, three
  children with records), **0003** (clinic family: link with birth date 2023-05-10), **0099** (new
  guardian). Code **123456** for all; no SMS is sent.
- Dashboard (link 2): the doctor and the two secretaries with the printed passwords.

## Reseed the day before

The demo's dates count from the day the seed runs («اليوم» and the next 7 days). The day before:

1. `cd functions && npm run seed:demo-prod -- --wipe` → type `dr-elnono-clinic` (deletes all demo
   data and all Auth accounts, including anyone who signed in to try it).
2. `cd functions && npm run seed:demo-prod` → type `dr-elnono-clinic`; save the new staff passwords.

## Roll back

- Hosting: Firebase console → Hosting → site → Release history → ⋮ → **Rollback** to the previous
  release (or `firebase hosting:rollback` is not available; use the console).
- Functions: redeploy the previous commit (`git checkout <previous> && firebase deploy --project prod --only functions`).
- Rules/indexes: redeploy the previous commit's `firestore.rules` / `firestore.indexes.json` the same way.
- Data: wipe and reseed (above).

## Take it down after the demo

1. Data and accounts: `cd functions && npm run seed:demo-prod -- --wipe`.
2. Hosting: `functions/node_modules/.bin/firebase hosting:disable --project prod --site dr-elnono-clinic`
   and `--site dr-elnono-dashboard` (the links stop working; releases stay in history).
3. Keep or delete functions: `firebase functions:delete <name> --project prod --region me-central1`
   for each, or leave them (no traffic, no cost).
4. Before the real launch, follow [launch-checklist.md](launch-checklist.md): every demo family,
   booking and account gone, and every "proposed" item approved or removed.
