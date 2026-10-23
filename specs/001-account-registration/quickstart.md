# Quickstart: Validate Account and Registration (001)

Everything runs locally against the Firebase Emulator Suite. No real SMS, no Blaze needed.

## Prerequisites

- Flutter stable (3.47 or later) — installed.
- Firebase CLI — installed.
- **Node.js 22 LTS** — not installed yet; needed for Cloud Functions and rules tests.
- **JDK 21** — needed by the Firestore emulator.
- An Android emulator or iOS simulator.

## Setup

```sh
cd functions && npm ci && npm run build && cd ..
functions/node_modules/.bin/firebase emulators:start --only auth,firestore,functions --import=./emulator-seed
```

Use the project's own Firebase CLI (`functions/node_modules/.bin/firebase`): it runs on Node 22,
like the deployed functions. The standalone CLI bundles Node 20.

`emulator-seed` contains `settings/auth`, `settings/policy` (version 1, placeholder text) and one
clinic-registered guardian with two children on `+201000000001` (birth date of the first:
`2024-03-15`).

Run the app against the emulators:

```sh
flutter run --dart-define=USE_EMULATOR=true
```

The Auth emulator never sends SMS; read codes from the Emulator UI (Auth tab) or
`GET http://localhost:9099/emulator/v1/projects/<project>/verificationCodes`.

## Automated checks

```sh
cd functions && npm test          # Security Rules (contracts/firestore-access.md) + callables
cd functions && npm run test:rules  # Security Rules only
flutter test                      # unit and widget tests
flutter test integration_test --dart-define=USE_EMULATOR=true -d <simulator>  # end-to-end, emulators running
```

All three must pass before 001 is done (constitution: rules tests gate completion).

## Manual scenarios

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Fresh install, open Home and Content | Both open without sign-in (FR-001) |
| 2 | Tap Booking | Sign-in screen; after sign-in and registration, lands on Booking (FR-003) |
| 3 | Sign in with `+201000000099`, wait 5 min, enter code | "Code expired" in Arabic, resend offered (FR-006) |
| 4 | Enter a wrong code 5 times | Code discarded, must resend (FR-007) |
| 5 | Right after sending a code | Resend disabled with countdown from 60 (FR-008) |
| 6 | Register: details → decline consent → close app → reopen | Starts again at guardian details; emulator shows no `guardians` doc (FR-015) |
| 7 | Register fully with one child; restart app | Still signed in, child listed (FR-010, SC-006) |
| 8 | Sign in with `+201000000001`, consent, enter `2024-03-15` | Both clinic children linked; guardian details are the ones you typed (FR-021) |
| 9 | Same number, wrong birth date 3 times | Locked, "contact the clinic"; three `children.link_*` audit entries (FR-021a) |
| 10 | Add a child with the same name and birth date as an existing one | Warning, no new child doc (FR-022) |
| 11 | Edit child name and allergies | Saved; `history` entry with your uid. Birth date and sex not editable (FR-023, FR-024) |
| 12 | Change number to an unused number | Works; old number now starts a new registration (FR-025, FR-026) |
| 13 | Change number to one that already has an account | Refused, "contact the clinic" (FR-025a) |
| 14 | Delete account | Signed out; no `guardians` doc or Auth user; children kept with `guardianUid` null; `account.deleted` audit entry (FR-027 to FR-030) |
| 15 | Bump `settings/policy.currentVersion` to 2, reopen app | Consent screen before any child data (FR-017) |
| 16 | Switch device to dark mode | All screens readable in Arabic RTL with Readex Pro (FR-031) |
| 17 | Account screen: tap "talk to the clinic on WhatsApp" | Opens a chat with `settings/clinic.whatsappNumber`; Notifications entry shows a placeholder (FR-034, FR-035) |
| 18 | Sign in with `+201000000001`, consent, tap "these aren't my children, add a child" | Nothing linked, no attempt counted, add-child screen; birth-date check offered again at next sign-in (US4 scenario 4) |
| 19 | In the emulator, set your `guardians/{uid}.lastActiveAt` to 91 days ago; reopen the app | Birth-date re-check before any child data; correct date restores access; 3 wrong dates lock (FR-010a, FR-010b) |

## Scenario coverage (T088)

Each scenario above is automated; run the integration tests one file at a time with the project's
CLI (`functions/node_modules/.bin/firebase emulators:exec … "flutter test integration_test/<file>"`).

| # | Automated by |
|---|--------------|
| 1, 2 | `integration_test/browse_test.dart` |
| 3, 4, 5 | `test/features/auth/otp_controller_test.dart`, `otp_screen_test.dart` (fake clock) |
| 6, 7 | `integration_test/registration_test.dart`, `sign_in_test.dart` |
| 8 | `integration_test/link_children_test.dart` |
| 9 | `functions/test/functions/linkClinicChildren.test.ts`, `test/features/registration/link_children_screen_test.dart` |
| 10 | `functions/test/functions/createChild.test.ts`, `test/features/children/add_child_screen_test.dart` |
| 11 | `integration_test/children_test.dart` (rules + history trigger) |
| 12, 13 | `integration_test/change_phone_test.dart` |
| 14 | `integration_test/delete_account_test.dart` (also re-links the child after signing up again) |
| 15 | `integration_test/policy_update_test.dart` |
| 16 | `test/app/layout_test.dart` (13 screens × light/dark × text ×1/×2 at 375 pt) |
| 17 | `test/features/account/account_screen_test.dart` |
| 18 | `test/features/registration/link_children_screen_test.dart` |
| 19 | `integration_test/reverify_test.dart` |

## Not testable locally

- FR-009 daily SMS cap and the Egypt-only region policy: need Blaze plus Identity Platform
  (research R1). Verify on the real project with a test number after the upgrade.
