# Quickstart: Validate the Clinic Dashboard (005)

```sh
functions/node_modules/.bin/firebase emulators:start --only auth,firestore,functions --import=./emulator-seed
flutter run -d chrome -t lib/dashboard/main.dart --dart-define=USE_EMULATOR=true
```

Seeded staff (emulator only, password `Delnono-2026`):

| Email | Role | Clinic |
|-------|------|--------|
| doctor@demo.delnono | doctor | all |
| sec1@demo.delnono | secretary | clinic 1 |
| sec2@demo.delnono | secretary | clinic 2 |

## Scenarios

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Sign in as each | Secretary sees only her clinic; doctor switches clinics (FR-001, FR-002) |
| 2 | Today: mark arrived, done, no-show | Queue by arrival; visits recorded on done (FR-005, FR-006, FR-010) |
| 3 | Add walk-ins until full; stop walk-ins | Capacity respected; stopped refuses (FR-007, FR-008) |
| 4 | Record payment; sell a package | Amount defaults to the fixed price; package at the clinic price (FR-011, FR-012) |
| 5 | Child file as secretary: add measurement and dose | Saved; edit refused; guardian app shows the values (FR-014) |
| 6 | Child file as doctor: correct, note | Change log; note hidden from secretary and guardian (FR-015, FR-016) |
| 7 | Clinic settings: change clinic 2's hours and price | App booking for clinic 2 changes; confirmed bookings keep price (FR-018, FR-020) |
| 8 | Content and follow-up as secretary, then doctor | Drafts hidden from guardians until published (FR-021) |
| 9 | Reports, CSV | Numbers match; no names or medical data (FR-022, FR-023) |
| 10 | Settings, staff, audit log as doctor | Policy version change asks guardians again; disable a secretary; audit entries (FR-024, FR-025) |

## Scenario coverage (T025)

| # | Automated by |
|---|--------------|
| 1 | `functions/test/functions/staff/accounts.test.ts`; `functions/test/rules/staff.test.ts`; `test/dashboard/router_test.dart`, `shell_test.dart` |
| 2, 3 | `functions/test/functions/staff/queue.test.ts`; `test/dashboard/today_screen_test.dart` |
| 4 | `queue.test.ts` (payment, package sale, coverage at the other clinic); `today_screen_test.dart`, `screens_test.dart` |
| 5, 6 | `functions/test/functions/staff/childFile.test.ts`; `screens_test.dart` (child file per role) |
| 7 | `functions/test/functions/staff/admin.test.ts` (prices, kept booking price, orphaned bookings) |
| 8 | `admin.test.ts` (content, follow-up drafts and publishing); `staff.test.ts` (published content rules); `screens_test.dart` |
| 9 | `admin.test.ts` (report numbers, clinic scope); `screens_test.dart` (CSV columns) |
| 10 | `admin.test.ts` (settings); `accounts.test.ts`; `staff.test.ts` (audit log for the doctor) |
| Layout | `test/dashboard/layout_test.dart` (13 screens × desktop and tablet × light and dark × text ×1 and ×1.5) |

The dashboard has no browser end-to-end runner (plan.md); the guardian app's simulator tests run once
at the end of the feature, and the web build is checked with `flutter build web -t lib/dashboard/main.dart`.

## Not testable locally

Hosting deploy and deployed callables (blocked: Blaze, D-40).
