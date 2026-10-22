---

description: "Task list for 001 Account and Registration"
---

# Tasks: Account and Registration

**Input**: Design documents from `/specs/001-account-registration/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included. The constitution (Principle VI and Development Workflow) requires automated
tests for every feature, and Security Rules tests must pass before a feature is done. Within each
story, write the tests first and confirm they fail.

**Organization**: Tasks are grouped by user story so each story can be built and tested on its own.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: User story from spec.md (US1–US7)

## Path Conventions

- Flutter app at the repository root: `lib/`, `test/`, `integration_test/`, `l10n/`, `assets/`
- Cloud Functions and all Node tests: `functions/src/`, `functions/test/`
- Firebase config at the root: `firebase.json`, `.firebaserc`, `firestore.rules`, `firestore.indexes.json`
- Every screen matches its mockup in `docs/design/screens/` and the tokens in `docs/design/tokens.css`
  (see the screen table in plan.md). Every user-facing string goes in `l10n/app_ar.arb`.

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialisation. Prerequisite on the machine: Node.js 22 and JDK 21 (quickstart.md).

- [X] T001 Add dependencies to `pubspec.yaml`: `flutter_localizations` (sdk), `intl`, `flutter_riverpod`, `go_router`, `firebase_core`, `firebase_auth`, `cloud_firestore`, `cloud_functions`, `url_launcher`; dev: `mocktail`, `integration_test` (sdk). Add nothing else (research R5). Set `flutter: generate: true`.
- [X] T002 [P] Add Readex Pro (weights 300, 400, 500, 600, 700) and its OFL licence to `assets/fonts/` and register the family `ReadexPro` in `pubspec.yaml`. Do not use `google_fonts`.
- [X] T003 [P] Create `l10n.yaml` (arb dir `l10n`, template `app_ar.arb`, output class `AppLocalizations`) and `l10n/app_ar.arb` with the app title; Arabic is the only locale.
- [X] T004 [P] Create the Functions project in `functions/`: `package.json` (engines node 22; deps `firebase-functions`, `firebase-admin`; dev deps `typescript`, `mocha`, `@types/mocha`, `@types/node`, `tsx`, `@firebase/rules-unit-testing`, `firebase` (its peer), `firebase-tools` (so tests run the emulators on Node 22; see research R6); scripts `build`, `lint` = `tsc --noEmit`, `pretest` = `npm run build` (the Functions emulator loads the compiled `lib/`), `test` = `firebase emulators:exec --only auth,firestore,functions "mocha"`), `tsconfig.json` (strict, outDir `lib`), `.mocharc.json` (spec `test/**/*.test.ts`, `node-option: import=tsx`), `src/index.ts` (empty exports).
- [X] T005 [P] Create `firebase.json` (emulators: auth 9099, firestore 8080, functions 5001, ui enabled; firestore rules `firestore.rules`, indexes `firestore.indexes.json`; functions source `functions`), `.firebaserc` with default project `demo-delnono` (the `demo-` prefix keeps all calls on the emulators), `firestore.rules` that denies everything, and an empty `firestore.indexes.json`.
- [X] T006 Replace the counter app: reduce `lib/main.dart` to `runApp(ProviderScope(child: App()))` after Firebase init, delete `test/widget_test.dart`, and create the folders from plan.md (`lib/app`, `lib/core`, `lib/features/{auth,registration,children,account,shell,welcome}`).

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: App shell, router, settings, server helpers and test harness needed by every story.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [X] T007 Create `lib/core/firebase/firebase_init.dart`: initialise Firebase; when `--dart-define=USE_EMULATOR=true`, connect Auth (9099), Firestore (8080) and Functions (5001) emulators using host `10.0.2.2` on Android and `localhost` elsewhere; enable Firestore offline persistence. Add `lib/core/firebase/firebase_options.dart` with options for project `demo-delnono` (real options come from `flutterfire configure` once the project exists).
- [X] T008 [P] Create `lib/app/theme.dart`: light and dark `ThemeData` (Material 3) built from the colour pairs, radii (14–20) and component shapes in `docs/design/tokens.css`; font family `ReadexPro`; text sizes body 13–15, small 11, titles 20–30 (design README).
- [X] T009 [P] Create `lib/app/app.dart`: `MaterialApp.router` with locale `ar`, `AppLocalizations` and the global Material/Widgets/Cupertino delegates, `theme`/`darkTheme` from T008, `themeMode: system`, router from T016.
- [X] T010 [P] Create `lib/core/settings/settings_repository.dart` and providers that stream `settings/auth` (defaults `codeValiditySeconds` 300, `maxCodeAttempts` 5, `resendWaitSeconds` 60, `dailySmsCapPerNumber` 5, `maxLinkAttempts` 3, `reverifyAfterDays` 90), `settings/policy` (`currentVersion`, `privacyPolicyText`, `termsText`) and `settings/clinic` (`whatsappNumber`), falling back to the defaults when a document is missing.
- [X] T011 [P] Create `lib/core/phone/egypt_phone.dart`: normalise input (`01…`, `1…`, `+20…`, `0020…`, Arabic-Indic digits) to E.164 and validate against `^\+201[0125]\d{8}$`; with tests in `test/core/phone/egypt_phone_test.dart`.
- [X] T012 [P] Create `lib/core/errors/arabic_errors.dart`: map `FirebaseAuthException` codes (`invalid-verification-code`, `session-expired`, `too-many-requests`, `network-request-failed`, `credential-already-in-use`, `quota-exceeded`) and `FirebaseFunctionsException` codes from contracts/callables.md to Arabic messages in `l10n/app_ar.arb`; map `unavailable` and `deadline-exceeded` from callables, and `network-request-failed` from Auth, to one Arabic "you need an internet connection" message (FR-032); unknown codes get a generic Arabic message. Tests in `test/core/errors/arabic_errors_test.dart`.
- [X] T013 [P] Create `lib/features/shell/shell_scaffold.dart` (bottom navigation right to left: Home `/`, Booking `/booking`, My Child `/children`, Content `/content`, then an empty reserved slot of the same width with no route and no tap target, Principle V) and `lib/features/shell/placeholders.dart` (Home, Booking, Content and Notifications screens, each visibly marked as placeholder).
- [X] T014 [P] Create `lib/features/auth/data/auth_repository.dart` with `authStateChanges`, `currentUser` and `signOut`, exposed through a Riverpod provider.
- [X] T015 [P] Create `lib/features/registration/data/guardian_repository.dart` (stream `guardians/{uid}`, update `fullName`, `relation`, `email`) and `lib/features/children/data/children_repository.dart` (stream `children` where `guardianUid == uid`), with providers.
- [X] T016 Create `lib/app/router.dart`: `GoRouter` with every route in contracts/routes.md (placeholders for screens not built yet) and a `redirect` that applies guard steps 1–6 in order, carries `from` through each step, and accepts `from` only if it starts with `/` and not `//`. Guard inputs come from providers for auth state (T014), the guardian doc (T015), settings/policy (T010), a session-only "link skipped" flag and the registration-in-progress flag. Step 5 applies only while that flag is set (contracts/routes.md); a guardian with no children outside registration is never redirected.
- [X] T017 Create `test/app/router_guard_test.dart`: with overridden providers, assert each guard step 1–6 redirects as in contracts/routes.md, that `from` survives the whole chain, that a guardian with no children and no registration in progress (e.g. after a locked link check) is not redirected, and that `from=//evil.com` and `from=https://…` fall back to `/`.
- [X] T018 [P] Create `functions/src/lib/settings.ts`: read `settings/auth` and `settings/policy` with the same defaults as T010.
- [X] T019 [P] Create `functions/src/lib/audit.ts`: `writeAudit({action, actorUid, subjectPhone, childIds?, details?})` writing to `auditLog` with `at` = server time and `expiresAt` = now + 1 year (D-13). Allowed actions: `account.created`, `consent.accepted`, `children.linked`, `children.link_failed`, `children.link_locked`, `phone.changed`, `account.deleted`, `child.allergies_changed`, `account.reverified`, `account.reverify_failed`, `account.reverify_locked`.
- [X] T020 [P] Create `functions/src/lib/validation.ts` with validators quoting data-model.md: guardian `fullName` "required, 2–80 chars", `relation` "`mother` | `father` | `other`", `email` "optional, valid email if present"; child `name` "required, 2–60 chars", `birthDate` "required, not in future, within 18 years" (format `YYYY-MM-DD`), `sex` "`male` | `female`", `birthWeightKg` "0.3–7.0", `allergies` "≤ 500 chars". Throw `HttpsError('invalid-argument')` naming the field.
- [X] T021 [P] Create `functions/src/lib/nameKey.ts`: trim, collapse whitespace, remove Arabic diacritics and tatweel, unify أ/إ/آ → ا, ى → ي, ة → ه, lowercase Latin; with tests in `functions/test/lib/nameKey.test.ts`.
- [X] T022 Create `functions/src/lib/guards.ts`: `requirePhoneUser(request)` (authenticated, token has `phone_number`; else `unauthenticated`) and `requireGuardianWithCurrentConsent(uid)` (guardian doc exists and `consentVersion == settings/policy.currentVersion`; else `failed-precondition`).
- [X] T023 Create `functions/test/helpers/env.ts`: shared setup for `@firebase/rules-unit-testing` (project `demo-delnono`, loads `firestore.rules`, clears data between tests) and for calling callables against the Functions emulator as a phone user, plus seed helpers for settings, guardians, clinic guardians and children.
- [X] T024 Write the base of `firestore.rules`: helpers `signedIn()`, `isOwner(uid)`, `consentCurrent()` (reads `guardians/{uid}.consentVersion` and `settings/policy.currentVersion`); `settings/{doc}` readable by anyone, never writable; `clinicGuardians`, `linkAttempts`, `smsCounters`, `auditLog`, `deletedGuardians` denied for every client; default deny. Tests for those rows in `functions/test/rules/base.test.ts`.
- [X] T025 Create `functions/scripts/seed.ts` that writes the quickstart seed to the running emulators (`settings/auth` defaults, `settings/policy` version 1 with placeholder Arabic text marked as placeholder, `settings/clinic.whatsappNumber` placeholder, `clinicGuardians/+201000000001`, two unlinked clinic children on `+201000000001`, the first born `2024-03-15`), then export it to `emulator-seed/` with `firebase emulators:export emulator-seed`.

**Checkpoint**: app launches on the emulator in Arabic RTL with the shell and placeholders; `npm test` and `flutter test` pass.

---

## Phase 3: User Story 1 – Sign in with a mobile number (Priority: P1) 🎯 MVP

**Goal**: A guardian signs in with an Egyptian number and SMS code and stays signed in.

**Independent Test**: Sign in on the emulator, restart the app, still signed in (quickstart scenarios 3–5, 7).

### Tests for User Story 1

- [ ] T026 [P] [US1] Create `test/features/auth/otp_controller_test.dart` with a fake clock and fake phone auth service: code treated as expired `codeValiditySeconds` after sending (FR-006); `verificationId` discarded after `maxCodeAttempts` wrong entries (FR-007); resend unavailable until `resendWaitSeconds` and remaining seconds exposed (FR-008); values read from settings, not constants.
- [ ] T027 [P] [US1] Create `test/features/auth/phone_screen_test.dart` and `test/features/auth/otp_screen_test.dart`: invalid number blocked before sending; expired, wrong-code and attempts-left messages in Arabic; resend button disabled with countdown.
- [ ] T028 [P] [US1] Create `integration_test/sign_in_test.dart`: sign in with `+201000000099` reading the code from the Auth emulator REST endpoint (quickstart.md), restart the widget tree, assert still signed in (FR-010).

### Implementation for User Story 1

- [ ] T029 [US1] Create `lib/features/auth/data/phone_auth_service.dart` wrapping `FirebaseAuth.verifyPhoneNumber` (pass `forceResendingToken` on Android; handle `verificationCompleted` auto-retrieval on Android) and `signInWithCredential`.
- [ ] T030 [US1] Create `lib/features/auth/application/otp_controller.dart` (Riverpod `Notifier`): state `phone`, `verificationId`, `sentAt`, `wrongAttempts`, `resendAvailableAt`; enforce FR-006 to FR-008 as in research R1 using `settings/auth`.
- [ ] T031 [P] [US1] Create `lib/features/auth/presentation/phone_screen.dart` matching `docs/design/screens/Phone.dc.html`: number field with Egyptian validation (T011), send button, Arabic errors (T012).
- [ ] T032 [US1] Create `lib/features/auth/presentation/otp_screen.dart` matching `docs/design/screens/Otp.dc.html`: 6-digit input, "valid for 5 minutes" note from settings, resend countdown, attempts left, "change number" link back to `/sign-in`.
- [ ] T033 [US1] Wire `/sign-in` and `/sign-in/code` in `lib/app/router.dart`; after sign-in continue the guard chain with `from` (FR-003); add a sign-out action in `lib/features/auth/data/auth_repository.dart` that also clears the Firestore cache.

**Checkpoint**: US1 tests pass; a guardian can sign in and stay signed in.

---

## Phase 4: User Story 2 – First-run registration with consent (Priority: P1)

**Goal**: Guardian details → explicit consent → first child, with nothing stored before consent.

**Independent Test**: Quickstart scenarios 6, 7 and 15.

### Tests for User Story 2

- [ ] T034 [P] [US2] Create `functions/test/functions/completeRegistration.test.ts`: success writes `guardians/{uid}` (with `consentVersion`, `clinicChildrenPending`), one `consents` doc and audit `account.created` + `consent.accepted` in one transaction; `already-exists`; `failed-precondition` for wrong `policyVersion` or a missing scope; `invalid-argument` per field; `hasClinicChildren` true when unlinked children exist on the caller's phone, including a child with `registeredBy: guardian` left unlinked by a deleted account.
- [ ] T035 [P] [US2] Create `functions/test/functions/acceptPolicy.test.ts`: records a new consent and updates `consentVersion`; `failed-precondition` for a non-current version; `not-found` without a guardian.
- [ ] T036 [P] [US2] Create `functions/test/functions/createChild.test.ts`: creates a child with `registeredBy: guardian`, `guardianUid`, `guardianPhone`, `nameKey`; `already-exists` when `nameKey` + `birthDate` match a child on the same phone, with `details.existingLinked` true for a linked child and false for an unlinked clinic child; `invalid-argument` for each constraint in T020; `failed-precondition` without current consent.
- [ ] T037 [P] [US2] Create `functions/test/rules/guardians.test.ts` covering every `guardians/{uid}` and `consents` row in contracts/firestore-access.md, including denial of client changes to `phone`, `consentVersion` and `clinicChildrenPending`.
- [ ] T038 [P] [US2] Create `functions/test/rules/children-read.test.ts` covering the `children/{id}` read, create and delete rows, including denial for another guardian, for an unlinked clinic child on the same phone, and for a guardian whose consent is outdated.
- [ ] T039 [P] [US2] Create `integration_test/registration_test.dart`: full first run; and a run that stops at consent, restarts and lands on guardian details with no `guardians` doc in the emulator (FR-015).

### Implementation for User Story 2

- [ ] T040 [P] [US2] Create `functions/src/callables/completeRegistration.ts` per contracts/callables.md, using T018–T022; set `clinicChildrenPending` from a query for unlinked children on the caller's phone (`guardianPhone == phone` and `guardianUid == null`, any `registeredBy`).
- [ ] T041 [P] [US2] Create `functions/src/callables/acceptPolicy.ts` per contracts/callables.md.
- [ ] T042 [P] [US2] Create `functions/src/callables/createChild.ts` per contracts/callables.md: validate (T020), compute `nameKey` (T021), check duplicates on `guardianPhone` + `nameKey` + `birthDate` inside a transaction, then create.
- [ ] T043 [US2] Export the three callables from `functions/src/index.ts`, set the region from one constant in `functions/src/lib/region.ts` (value decided by research R8; emulator default until then).
- [ ] T044 [US2] Extend `firestore.rules` for `guardians/{uid}` (read and limited update for the owner), `guardians/{uid}/consents` (owner read only) and `children/{id}` read (linked guardian with `consentCurrent()`), per contracts/firestore-access.md.
- [ ] T045 [US2] Create `lib/features/registration/application/registration_controller.dart`: keeps guardian details in memory only until consent (FR-015), calls `completeRegistration`, then `acceptPolicy` for re-consent (FR-017); exposes the registration-in-progress flag used by guard step 5, set after `completeRegistration` and cleared when the first child is added, children are linked, or the guardian leaves the flow.
- [ ] T046 [P] [US2] Create `lib/features/registration/presentation/guardian_details_screen.dart` matching `docs/design/screens/Guardian.dc.html`: full name "required, 2–80 chars", relation "`mother` | `father` | `other`", email "optional, valid email if present".
- [ ] T047 [P] [US2] Create `lib/features/registration/presentation/consent_screen.dart` matching `docs/design/screens/Consent.dc.html`: policy and terms text from `settings/policy`, two separate unticked checkboxes (policy and terms; child data collection), version shown, continue disabled until both are ticked; reused for re-consent.
- [ ] T048 [US2] Create `lib/features/children/presentation/add_child_screen.dart` matching `docs/design/screens/AddChild.dc.html`: name "required, 2–60 chars", birth date "required, not in future, within 18 years", sex "`male` | `female`", birth weight kg "0.3–7.0", allergies "≤ 500 chars"; on `already-exists` show the duplicate warning, and when `existingLinked` is false tell the guardian to contact the clinic. Used by `/register/child` and `/children/add`.
- [ ] T049 [US2] Add `createChild` to `lib/features/children/data/children_repository.dart` and wire `/register/guardian`, `/register/consent`, `/register/child` and guard steps 2, 3 and 5 in `lib/app/router.dart`.
- [ ] T050 [P] [US2] Create widget tests `test/features/registration/guardian_details_screen_test.dart`, `consent_screen_test.dart` and `test/features/children/add_child_screen_test.dart` for the validation and messages above.

**Checkpoint**: US1 + US2 give a complete first-run flow (MVP).

---

## Phase 5: User Story 3 – Browse without an account (Priority: P2)

**Goal**: Welcome, Home and Content are public; protected areas ask for sign-in and return afterwards.

**Independent Test**: Quickstart scenarios 1 and 2.

- [ ] T051 [P] [US3] Create `lib/features/welcome/welcome_screen.dart` matching `docs/design/screens/Main.dc.html`: "register with your mobile" → `/sign-in`, "browse content first" → `/content`; doctor photo is a marked placeholder.
- [ ] T052 [US3] In `lib/app/router.dart`, start signed-out users at `/welcome` and signed-in users at `/`; keep `/`, `/content` and `/welcome` public.
- [ ] T053 [P] [US3] Create `integration_test/browse_test.dart`: fresh start shows Welcome; Home and Content open without sign-in; tapping Booking goes to sign-in and, after sign-in and registration, lands on `/booking` (FR-001 to FR-003).

**Checkpoint**: browsing works signed out; FR-003 return works end to end.

---

## Phase 6: User Story 4 – See children the clinic already registered (Priority: P2)

**Goal**: Clinic-registered children link after a birth-date check; three failures lock linking.

**Independent Test**: Quickstart scenarios 8, 9 and 18.

### Tests for User Story 4

- [ ] T054 [P] [US4] Create `functions/test/functions/linkClinicChildren.test.ts`: correct birth date links every unlinked child on the caller's phone (any `registeredBy`, including one left by a deleted account) (sets `guardianUid`), clears `clinicChildrenPending`, resets `linkAttempts`, writes `children.linked`; wrong date returns `permission-denied` with `details.remaining` and writes `children.link_failed`; the `maxLinkAttempts`-th failure locks, clears `clinicChildrenPending` and writes `children.link_locked`; locked returns `resource-exhausted`; no clinic children returns `not-found`; no current consent returns `failed-precondition`.
- [ ] T055 [P] [US4] Create `test/features/registration/link_children_screen_test.dart`: remaining-attempts message, locked message with "contact the clinic", and "these aren't my children, add a child" sets the session skip flag and opens add child without calling the function.

### Implementation for User Story 4

- [ ] T056 [US4] Create `functions/src/callables/linkClinicChildren.ts` per contracts/callables.md, using `settings/auth.maxLinkAttempts` and a transaction over `linkAttempts/{phone}` and the matching children; export it from `functions/src/index.ts`.
- [ ] T057 [US4] Create `lib/features/registration/presentation/link_children_screen.dart` matching `docs/design/screens/LinkChildren.dc.html`: birth-date input, confirm, attempts-left and locked states, and the "these aren't my children, add a child" option (spec US4 scenario 4); on success show the linked children's names.
- [ ] T058 [US4] Wire `/register/link` and guard step 4 (`clinicChildrenPending` and the session skip flag) in `lib/app/router.dart`; after linking, skip `/register/child` because children exist.

**Checkpoint**: clinic children appear only after the birth-date check.

---

## Phase 7: User Story 5 – Manage children (Priority: P2)

**Goal**: Several children per account; guardian edits name and allergies only.

**Independent Test**: Quickstart scenarios 10 and 11.

### Tests for User Story 5

- [ ] T059 [P] [US5] Create `functions/test/rules/children-update.test.ts` covering the `children/{id}` update and `history` rows in contracts/firestore-access.md: allowed when only `name`, `allergies`, `updatedAt`, `updatedBy` change with `updatedBy == request.auth.uid` and `updatedAt == request.time`; denied for `birthDate`, `sex`, `guardianUid`, `guardianPhone`, another guardian, or invalid values; history readable by the linked guardian only and never writable.
- [ ] T060 [P] [US5] Create `functions/test/functions/onChildUpdated.test.ts`: an update writes one `history` entry with `changedFields` {from, to}, `changedBy` and `changedAt`; an `allergies` change also writes audit `child.allergies_changed` (FR-023a); a name-only change writes no audit entry; an update with no field changes writes nothing.

### Implementation for User Story 5

- [ ] T061 [US5] Extend `firestore.rules` with the `children/{id}` update rule and `children/{id}/history/{h}` read rule per contracts/firestore-access.md, validating name "2–60 chars" and allergies "≤ 500 chars".
- [ ] T062 [P] [US5] Create `functions/src/triggers/onChildUpdated.ts` (history entry, plus audit `child.allergies_changed` when `allergies` changed, FR-023a) and export it from `functions/src/index.ts`.
- [ ] T063 [P] [US5] Create `lib/features/children/presentation/children_list_screen.dart` (`/children`): linked children, an empty state when there are none, and an "add child" action to `/children/add`.
- [ ] T064 [US5] Create `lib/features/children/presentation/child_profile_screen.dart` (`/children/:id`): edit name and allergies (saving `updatedBy` = uid and `updatedAt` = server time through `children_repository.dart`); birth date and sex read-only with a "contact the clinic to correct" note (FR-024).
- [ ] T065 [P] [US5] Create `test/features/children/child_profile_screen_test.dart`: only name and allergies are editable; a child over 4 years can be added (FR-020).

**Checkpoint**: guardians manage several children within the edit limits.

---

## Phase 8: User Story 6 – Change mobile number (Priority: P3)

**Goal**: Number change by code on the new number; refused if the number already has an account. Includes the account screen (FR-033 to FR-035), which US7 also uses.

**Independent Test**: Quickstart scenarios 12, 13 and 17.

### Tests for User Story 6

- [ ] T066 [P] [US6] Create `functions/test/functions/syncPhoneNumber.test.ts`: updates `guardians/{uid}.phone` and `guardianPhone` on linked children to the Auth record's number, writes `phone.changed` with old and new numbers, and sets `clinicChildrenPending` if unlinked clinic children exist on the new number.
- [ ] T067 [P] [US6] Create `test/features/account/account_screen_test.dart`: shows guardian name, number, relation, children and accepted policy version; Notifications entry opens the placeholder; WhatsApp link calls the launcher with the `settings/clinic` number and is labelled support-only (FR-033 to FR-035).
- [ ] T068 [P] [US6] Create `integration_test/change_phone_test.dart`: change to an unused number succeeds; change to a number with an existing account shows the "contact the clinic" message (FR-025a).

### Implementation for User Story 6

- [ ] T069 [US6] Create `functions/src/callables/syncPhoneNumber.ts` per contracts/callables.md and export it.
- [ ] T070 [US6] Create `lib/features/account/presentation/account_screen.dart` matching `docs/design/screens/Account.dc.html`: guardian details, children, accepted policy version, change number, Notifications placeholder (feature 007), "talk to the clinic on WhatsApp" via `url_launcher` (`whatsapp://send?phone=` with `https://wa.me/` fallback; text says support only, not booking), sign out, delete account.
- [ ] T071 [US6] Create `lib/features/account/presentation/change_phone_screen.dart` (`/account/phone`): reuse the OTP controller (T030) for the new number, call `updatePhoneNumber`, map `credential-already-in-use` to the "contact the clinic" message, then call `syncPhoneNumber`.
- [ ] T072 [US6] Wire `/account` and `/account/phone` in `lib/app/router.dart`, with an account entry point from the shell.

**Checkpoint**: number change works and conflicts go to the clinic.

---

## Phase 9: User Story 7 – Delete account (Priority: P3)

**Goal**: Guardian deletes the app account; clinic records stay.

**Independent Test**: Quickstart scenario 14. Depends on the account screen from T070.

### Tests for User Story 7

- [ ] T073 [P] [US7] Create `functions/test/functions/deleteAccount.test.ts`: consents moved to `deletedGuardians/{uid}/consents`; linked children get `guardianUid: null` and keep `guardianPhone`; `guardians/{uid}` deleted; audit `account.deleted`; Auth user deleted; a retry after a simulated failure between steps completes the rest.

### Implementation for User Story 7

- [ ] T074 [US7] Create `functions/src/callables/deleteAccount.ts` per contracts/callables.md (steps in order, idempotent) and export it.
- [ ] T075 [US7] Create `lib/features/account/presentation/delete_account_screen.dart` (`/account/delete`): explains what is removed and what the clinic keeps (text from the Account mockup), requires an explicit confirm; on success sign out, clear the Firestore cache and go to `/welcome`.
- [ ] T076 [P] [US7] Create `test/features/account/delete_account_screen_test.dart`: nothing is called before confirm; success leads to `/welcome`.

**Checkpoint**: all seven stories work.

---

## Phase 10: Re-check after inactivity (FR-010a, FR-010b; part of User Story 1)

**Goal**: A guardian with linked children who has not used the app for `reverifyAfterDays` must
confirm a child's birth date before child data is shown (research R9). Placed after US7 because it
needs linked children (US2, US4) and the account lock pattern from US4.

**Independent Test**: Quickstart scenario 19.

- [ ] T077 [P] [US1] Create `functions/test/functions/reverify.test.ts`: `touchSession` returns `reverifyRequired: false` and refreshes `lastActiveAt` (at most once a day) when within `reverifyAfterDays` or when there are no linked children, and `reverifyRequired: true` without changes when stale; `reverifyGuardian` with a linked child's birth date sets `lastActiveAt` and resets `reverifyAttempts/{uid}`, a wrong date returns `permission-denied` with `details.remaining`, the `maxLinkAttempts`-th failure locks and later calls return `resource-exhausted`; audit `account.reverified`, `account.reverify_failed`, `account.reverify_locked`.
- [ ] T078 [P] [US1] Create `functions/test/rules/children-activity.test.ts`: child read, child update and history read are denied when the guardian's `lastActiveAt` is older than `settings/auth.reverifyAfterDays` and allowed when newer; a guardian cannot write `lastActiveAt`.
- [ ] T079 [US1] Create `functions/src/callables/touchSession.ts` and `functions/src/callables/reverifyGuardian.ts` per contracts/callables.md and export them; set `lastActiveAt` in `completeRegistration.ts` (T040) and `linkClinicChildren.ts` (T056).
- [ ] T080 [US1] Extend `firestore.rules`: add an `active()` helper (guardian `lastActiveAt` > `request.time - duration.value(reverifyAfterDays, 'd')`) to the `children/{id}` read and update rules and the `history` read rule; exclude `lastActiveAt` from the guardian's updatable keys.
- [ ] T081 [US1] Create `lib/features/auth/application/session_controller.dart` (calls `touchSession` on app start when online, exposes `reverifyRequired`), `lib/features/auth/presentation/reverify_screen.dart` (`/reverify`, birth-date input reusing the layout of `docs/design/screens/LinkChildren.dc.html`, attempts-left and locked states with "contact the clinic"), and guard step 3a in `lib/app/router.dart`.
- [ ] T082 [P] [US1] Create `test/features/auth/reverify_screen_test.dart` and add guard step 3a cases to `test/app/router_guard_test.dart`.

**Checkpoint**: a reassigned number cannot read the previous family's children.

---

## Phase 11: Polish & Cross-Cutting Concerns

- [ ] T083 [P] Create `functions/src/triggers/beforeSmsSent.ts` (FR-009, research R1): increment `smsCounters/{phone}_{YYYYMMDD}` with `expiresAt` = +2 days and return `{ recaptchaActionOverride: "BLOCK" }` above `dailySmsCapPerNumber`; keep the counting in a pure function tested in `functions/test/lib/smsCap.test.ts`. Export it, but note it deploys only after the Identity Platform upgrade.
- [ ] T084 [P] Create `functions/README.md` with the steps for the Blaze upgrade (D-38): Identity Platform upgrade (owner approval), SMS region allowlist Egypt only, Firebase test phone numbers, TTL policies on `smsCounters.expiresAt` and `auditLog.expiresAt`, region from research R8, and `flutterfire configure` for the real project.
- [ ] T085 [P] Check every screen in light and dark mode at 375 pt width and at the largest system text size; no clipped Arabic text; colours match `docs/design/tokens.css`.
- [ ] T086 [P] Check that no user-facing string is hard-coded outside `l10n/app_ar.arb` (search `lib/` for Arabic literals and `Text('`).
- [ ] T087 Profile on a mid-range Android device on throttled 4G: core screens open within 3 s (D-22); sign-in to first child under 3 minutes (SC-001).
- [ ] T088 Run every scenario in quickstart.md (1–19) and `npm test`, `flutter test`, `flutter test integration_test`; all must pass before 001 is done.
- [ ] T089 [P] Create `functions/src/triggers/cleanupAbandonedSignIns.ts` (daily schedule, FR-015a): delete Auth users with no `guardians/{uid}` doc created more than 30 days ago; test the selection logic in `functions/test/functions/cleanupAbandonedSignIns.test.ts` against the Auth emulator. Deploys with Blaze.

---

## Dependencies & Execution Order

### Phase dependencies

- Setup (Phase 1) → Foundational (Phase 2) → user stories → Polish.
- US1 (sign in) is needed by every other story's end-to-end test, but each story's unit, widget,
  rules and function tests can run without it.
- US2 provides `createChild` and the add-child screen, which US4 (skip option) and US5 reuse.
- US7 depends on the account screen built in US6 (T070).
- Phase 10 (re-check after inactivity) needs linked children from US2 and US4.
- US3 and US4 can proceed in parallel after US2.

### Story completion order

```text
Setup → Foundational → US1 → US2 → { US3, US4, US5 } → US6 → US7 → Re-check (FR-010a) → Polish
```

### Parallel opportunities

- Setup: T002–T005 together.
- Foundational: T008–T012, T013–T015 and T018–T021 together; T016 (router) after T013–T015 (app and functions sides are independent).
- US2: tests T034–T039 together; then T040–T042 together, then T046–T047 together.
- US4, US5 tests can be written while US3 is built.

### Parallel example: User Story 2

```text
Tests together:  T034 completeRegistration.test.ts, T035 acceptPolicy.test.ts,
                 T036 createChild.test.ts, T037 guardians rules, T038 children-read rules
Then callables:  T040 completeRegistration.ts, T041 acceptPolicy.ts, T042 createChild.ts
Then screens:    T046 guardian_details_screen.dart, T047 consent_screen.dart
```

---

## Implementation Strategy

### MVP first (US1 + US2)

1. Phases 1–2.
2. US1: sign in and stay signed in.
3. US2: registration with consent and first child.
4. Stop and validate quickstart scenarios 3–7 and 15. This is the smallest slice that lets a real
   guardian onto the closed test.

### Incremental delivery

- Add US3 (browse) and US4 (clinic children) next: both matter for the closed test on 1 November
  (D-35), since walk-in families will already exist.
- US5 completes child management; US6 and US7 complete the account screen.
- Polish before the closed test; T083, T084 and T089 complete only after the Blaze upgrade.
