# Research: Account and Registration (001)

Sources checked on 2026-10-22: [Firebase Auth limits](https://firebase.google.com/docs/auth/limits),
[blocking functions](https://firebase.google.com/docs/auth/extend-with-blocking-functions),
[functions.identity reference](https://firebase.google.com/docs/reference/functions/2nd-gen/node/firebase-functions.identity),
[SMS region policy](https://docs.cloud.google.com/identity-platform/docs/admin/sms-regions),
[Flutter phone auth](https://firebase.google.com/docs/auth/flutter/phone-auth).

## R1. What Firebase Phone Auth lets us control (FR-006 to FR-009)

Facts found:

- Code validity and wrong-attempt limits are set by Firebase. They are not documented and not
  configurable. An expired code returns `session-expired` / "The SMS code has expired".
- Limits page: per project 3,000 SMS/day on plain Firebase Auth (no stated cap with Identity
  Platform); per IP 50 SMS/min, 500/hour, 150 verification requests/hour; per phone number "a limit"
  with no published value.
- Verification SMS is Blaze-only. Test phone numbers work on Spark and send no SMS.
- The resend token (`forceResendingToken`) exists on Android only; iOS returns null. There is no
  server-side resend timer.
- `beforeSmsSent` blocking function runs before every SMS, sees the phone number and can return
  `recaptchaActionOverride: "BLOCK"`. Blocking functions require upgrading to Firebase Authentication
  with Identity Platform and must answer within 7 seconds. Emulator support for this trigger was not
  confirmed.
- SMS region policy (allowlist) blocks numbers outside chosen country codes, enforced immediately.

| Req | Rule | Enforceable exactly? | Approach |
|-----|------|----------------------|----------|
| FR-006 | Code valid 5 min | Upper bound only | Client discards the `verificationId` 5 min after sending and shows "code expired". Firebase may expire it earlier; never later from the app's point of view. |
| FR-007 | 5 wrong entries | Client-side only | Client counts wrong entries per `verificationId` and discards it at 5. Firebase's own server limit also applies. A modified client could exceed 5 until Firebase's limit; accepted risk, since the code is short-lived and per-IP limits apply. |
| FR-008 | Resend after 60 s | Client-side only | Countdown in the UI; resend button disabled until 0. Android passes the resend token. |
| FR-009 | Daily cap per number | Yes, after upgrade | `beforeSmsSent` increments `smsCounters/{phone}_{date}` and returns BLOCK above `settings/auth.dailySmsCapPerNumber` (default 5). Needs Identity Platform, so it ships with the Blaze upgrade (D-38). Until then the cap is not enforced; dev uses test numbers that send no SMS. |
| — | SMS pumping protection | Yes | SMS region allowlist: Egypt (+20) only. Configure at the Blaze upgrade. |

**Decision**: enforce FR-006 to FR-008 in the client with values read from `settings/auth`; enforce
FR-009 with `beforeSmsSent` once the project is on Blaze with Identity Platform; add the Egypt-only
region allowlist at the same time.

**Rationale**: closest available enforcement without building our own SMS sender.

**Alternatives considered**: own OTP via an SMS gateway plus custom tokens (full control, but new
vendor, cost and security surface; rejected by Principle VI); callable pre-check before
`verifyPhoneNumber` (bypassable by calling Firebase directly; rejected in favour of `beforeSmsSent`).

**Owner decision needed before the closed test**: upgrading to Identity Platform changes billing to
monthly active users. Phase 1 scale (1,000 guardians, D-22) is expected to stay in the free tier,
but the doctor (account owner) must approve it with the Blaze upgrade.

## R2. Where server logic is required

**Decision**: callable Cloud Functions (2nd gen, TypeScript, Node 22) for `completeRegistration`,
`linkClinicChildren`, `createChild`, `syncPhoneNumber`, `deleteAccount`; a Firestore trigger for
child edit history; `beforeSmsSent` for FR-009. All audit-log writes happen only in functions.

**Rationale**: duplicate detection (FR-022) and linking (FR-021) need to read clinic-registered
children the guardian may not see yet; deletion must remove the Auth user and keep clinic records;
consent and guardian must be written together (FR-015).

**Alternatives considered**: client writes with Security Rules only (cannot read unlinked children
without exposing them; cannot delete Auth user plus related records atomically).

## R3. Phone change conflict (FR-025a)

**Decision**: rely on `updatePhoneNumber`, which fails with `credential-already-in-use` when the
number belongs to another Auth user. The app maps that error to the "contact the clinic" message.
After success the app calls `syncPhoneNumber`, which reads the number from the Auth record and
updates the guardian and linked children.

**Rationale**: Firebase enforces uniqueness natively; no pre-check, so numbers cannot be probed for
existing accounts. Cost: one SMS in the conflict case.

**Alternatives considered**: callable pre-check before sending the code (saves one SMS but lets
anyone test whether a number has an account).

## R4. Consent gate and policy versions (FR-014 to FR-017)

**Decision**: guardian details are held in memory until consent; `completeRegistration` writes the
guardian and an append-only consent record in one transaction. `settings/policy.currentVersion`
holds the version that requires acceptance. The router sends a guardian whose accepted version is
lower to the consent screen, and rules deny child reads in that case.

**Rationale**: no partial state, enforced both in UI and on the server.

## R5. Flutter stack and dependencies

| Package | Reason |
|---------|--------|
| `flutter_localizations`, `intl` | Arabic locale, RTL, date formatting (Principle IV). |
| `flutter_riverpod` | State and dependency injection; testable overrides. No code generation, to keep the build simple. |
| `go_router` | Declarative routes and a redirect guard that keeps the requested location (FR-003). |
| `firebase_core`, `firebase_auth`, `cloud_firestore` | Platform backend (constitution Stack). |
| `cloud_functions` | Calling the callables in R2; not in the input list but required by it. |
| `mocktail` (dev) | Fakes for repositories in widget tests. |
| `integration_test` (dev, SDK) | End-to-end flows against the emulator. |

Readex Pro is bundled as a font asset (no `google_fonts`), so first launch works offline and no
runtime font download happens. Egyptian mobile validation uses a regex
(`^\+201[0125]\d{8}$` after normalising `01…` input), not `libphonenumber`.

## R6. Testing approach

**Decision**: Security Rules tests with `@firebase/rules-unit-testing` and functions tests with
`firebase-functions-test`, both under `functions/` with one `package.json`, run against the emulator
with Mocha. Flutter unit and widget tests with fakes; integration tests against the Auth, Firestore
and Functions emulators using emulator-issued codes.

**Rationale**: one Node project, one emulator config (Principle VI). Rules tests gate "done"
(constitution workflow).

## R7. Audit log scope

**Decision**: in 001, functions log `account.created`, `consent.accepted`, `children.linked`,
`children.link_failed`, `children.link_locked`, `phone.changed`, `account.deleted`. Guardians reading
their own children are not logged.

**Rationale**: D-13 defines "opening a child file" as a staff action in the dashboard (feature 004).
Logging a guardian's own reads would route every read through a function and break offline reading.

## R8. Data location

**Decision**: pick the Firestore and Functions region with the Egypt Law 151/2020 lawyer review
(constitution Principle I), before the project's first Firestore database is created. The region
cannot be changed later. Candidates: `europe-west1` (Belgium) or a Middle East region such as
`me-central1` (Doha). Development uses the emulator, so this does not block implementation.

**Rationale**: Law 151/2020 restricts transfers of personal data outside Egypt; whether a licence or
specific safeguards are needed is a legal question, not a technical one.
