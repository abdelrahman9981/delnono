# Quickstart: Validate Child Profile and Vaccines (003)

Same setup as [001 quickstart](../001-account-registration/quickstart.md), now with the Storage emulator:
emulators with `emulator-seed/` (which 003 extends with the placeholder schedule, follow-up lists, sample
records for the clinic's children and a sample prescription photo), the app with
`--dart-define=USE_EMULATOR=true`, codes from the Auth emulator.

## Automated checks

```sh
cd functions && npm test               # rules (Firestore + Storage) and functions
flutter test                           # unit, widget, layout, RTL and no-judgment tests
# integration, one file at a time:
functions/node_modules/.bin/firebase emulators:exec --only auth,firestore,functions,storage \
  --import=./emulator-seed "flutter test integration_test/<file> --dart-define=USE_EMULATOR=true -d <simulator>"
```

## Scenarios

Sign up `+201000000001` and link the clinic's children with a birth date from the seed (15 Mar 2024).

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Open "طفلي" | Switcher with the children; latest weight, length, head with dates; chart (FR-001 to FR-004) |
| 2 | Switch the chart to length and head | Points are the child's own values only; no curves or ranges (FR-004) |
| 3 | Scan every screen for "طبيعي", "في المعدل", percentiles | None (FR-005, SC-003) |
| 4 | Vaccines | Source and review date; doses by age with given (date, lot), scheduled, due, late, missed; "إضافي" section (FR-006 to FR-012) |
| 5 | Visits → prescription | Newest first; photo opens full screen with zoom (FR-013, FR-014) |
| 6 | Another guardian reads the photo path | Refused (FR-015, SC-004) |
| 7 | Follow-up for a child under 4 | Current age band and danger signs; both call buttons open the dialer (FR-016, FR-017) |
| 8 | Follow-up for the seeded 4-year-old | Age list hidden, danger signs and buttons remain (FR-018) |
| 9 | Seed an active package | Card with end date and months left (FR-020) |
| 10 | Load, go offline, restart | All sections and the opened photo still show (FR-022) |
| 11 | Dark mode, large text, RTL chevrons | No overflow; forward ‹, back › (FR-024) |

## Not testable locally

Deployed Storage (blocked: Blaze), staff entry (004), reminders (007).
