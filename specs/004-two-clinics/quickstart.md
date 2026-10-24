# Quickstart: Validate Two Clinics (004)

Same setup as 003 (emulators with `emulator-seed/`, the app with `--dart-define=USE_EMULATOR=true`).
The seed now has two placeholder clinics:

| | Clinic 1 (main) | Clinic 2 |
|---|---|---|
| Name | [عيادة المقطم · بيانات مؤقتة] | [عيادة مدينة نصر · بيانات مؤقتة] |
| Hours | Sat–Thu 5–9 pm | Sun–Thu 10 am–2 pm |
| Vaccine days | Mon, Wed | Sun, Tue |
| Capacity | 6 | 5 |
| Visit price | 300 | 350 |
| Cancel window | 3 h | 6 h |

## Scenarios

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Home signed out | Both clinic cards with address, hours, call, WhatsApp (FR-013) |
| 2 | "احجزي هنا" on clinic 2 | After sign-in, booking opens with clinic 2 chosen |
| 3 | Book at each clinic | Each clinic's hours, places and prices; success and My bookings show its name and address (FR-006 to FR-009) |
| 4 | Book clinic 2 on a day you booked clinic 1 | Refused (FR-011) |
| 5 | Third upcoming booking across clinics | Refused (FR-011) |
| 6 | Clinic 2 booking starting in 5 h | No cancel or change; "كلمي العيادة" opens clinic 2's WhatsApp (FR-010) |
| 7 | Package sold at clinic 1, visit at clinic 2 | Covered (FR-014) |
| 8 | Visit history | Clinic name per visit (FR-017) |

## Scenario coverage

| # | Automated by |
|---|--------------|
| 1, 2 | `integration_test/browse_test.dart` (Home signed out, "احجزي هنا" on clinic 2 through sign-in); `test/features/home/home_screen_test.dart`; `booking_screen_test.dart` (preselected clinic) |
| 3 | `integration_test/booking_test.dart` (clinic 2: its price, clinic on success, slot per clinic); `integration_test/cancel_change_test.dart` (clinic 1); `booking_screen_test.dart` (004 group); `booking_success_screen_test.dart`; `functions/test/functions/createBooking.test.ts` (004 group) |
| 4, 5 | `createBooking.test.ts` (one per day and the upcoming maximum across clinics) |
| 6 | `cancelBooking.test.ts` (clinic 2's 6-hour window); `my_bookings_screen_test.dart` (004 group: window and WhatsApp per clinic) |
| 7 | `createBooking.test.ts` (package sold at clinic 1 covers clinic 2) |
| 8 | `visits_screen_test.dart` (clinic per visit, main clinic fallback) |
| Rules | `functions/test/rules/clinics.test.ts` |
| Layout | `test/app/layout_test.dart` (Home, clinic step: light/dark, text ×2, RTL icons) |
