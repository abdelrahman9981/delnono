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

## Not testable locally

Hosting deploy and deployed callables (blocked: Blaze, D-40).
