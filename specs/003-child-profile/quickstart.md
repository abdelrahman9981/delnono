# Quickstart: Validate Child Profile and Vaccines (003)

Same setup as [001 quickstart](../001-account-registration/quickstart.md): emulators with
`emulator-seed/` (which 003 extends with the placeholder schedule, follow-up lists and sample records for
the clinic's children), the app with
`--dart-define=USE_EMULATOR=true`, codes from the Auth emulator.

## Automated checks

```sh
cd functions && npm test               # rules and functions
flutter test                           # unit, widget, layout, RTL and no-judgment tests
# integration, one file at a time:
functions/node_modules/.bin/firebase emulators:exec --only auth,firestore,functions \
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
| 5 | Visits | Newest first, with what was recorded; no photo entry (FR-013, FR-015) |
| 6 | Another guardian reads the child's measurements, doses or visits | Refused (FR-021, SC-004) |
| 7 | Follow-up for a child under 4 | Current age band and danger signs; both call buttons open the dialer (FR-016, FR-017) |
| 8 | Follow-up for the seeded 4-year-old | Age list hidden, danger signs and buttons remain (FR-018) |
| 9 | Seed an active package | Card with end date and months left (FR-020) |
| 10 | Load, go offline, restart | All sections still show (FR-022) |
| 11 | Dark mode, large text, RTL chevrons | No overflow; forward ‹, back › (FR-024) |

## Scenario coverage (T036)

| # | Automated by |
|---|--------------|
| 1, 2 | `integration_test/child_profile_test.dart`; `test/features/child_profile/my_child_screen_test.dart`; `latest_measurements_test.dart`, `chart_scale_test.dart` |
| 3 | `test/features/child_profile/no_judgment_test.dart` (every 003 screen and every app string) |
| 4 | `child_profile_test.dart`; `vaccines_screen_test.dart`; `dose_state_test.dart` (each boundary, the day before and after); `child_age_test.dart` |
| 5 | `child_profile_test.dart`; `visits_screen_test.dart` |
| 6 | `functions/test/rules/child-records.test.ts` |
| 7, 8 | `child_profile_test.dart`; `follow_up_screen_test.dart` (both `tel:` links, hidden clinic button); `age_band_test.dart` |
| 9 | `my_child_screen_test.dart` (package group); `package_state_test.dart` |
| 10 | `child_profile_test.dart` (network off, app restarted); `my_child_screen_test.dart` (offline group) |
| 11 | `test/app/layout_test.dart` (my child, vaccines, visits, follow-up: light/dark, text ×2, RTL icons); `test/app/rtl_navigation_test.dart` |

## Not testable locally

Staff entry (004), reminders (007). Prescription photos are Phase 2 (D-39).
