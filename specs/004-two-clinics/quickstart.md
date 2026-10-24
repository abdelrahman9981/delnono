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

Filled in by the polish task.
