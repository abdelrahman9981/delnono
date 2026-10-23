# Quickstart: Validate Booking (002)

Same setup as [001 quickstart](../001-account-registration/quickstart.md): emulators with
`emulator-seed/` (which 002 extends with `settings/booking` and placeholder `vaccines`), the app with
`--dart-define=USE_EMULATOR=true`, codes from the Auth emulator.

## Automated checks

```sh
cd functions && npm test               # rules (contracts/firestore-access.md) + callables + race test
flutter test                           # unit, widget, layout and RTL tests
# integration, one file at a time:
functions/node_modules/.bin/firebase emulators:exec --only auth,firestore,functions \
  --import=./emulator-seed "flutter test integration_test/<file> --dart-define=USE_EMULATOR=true -d <simulator>"
```

## Scenarios

Use a registered guardian with two children (sign up a new number and add two children, or link the
seeded clinic children on `+201000000001`).

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Booking tab → clinic visit → a working day → an hour with places | Hours show "فاضل N من ٦"; full hours "مكتمل" and disabled; closed days disabled (FR-001 to FR-005) |
| 2 | Pick both children → confirm | Success screen with "نونو N", day, hour, both children, one visit price (FR-013) |
| 3 | Two devices (or the race test) take the last place together | Exactly one succeeds; the other sees "الميعاد اتحجز" (FR-009) |
| 4 | Vaccine only on a non-vaccine day | Day not selectable (FR-008) |
| 5 | Vaccine only on a vaccine day, one vaccine for one child | Total = vaccine price; one place taken (D-31) |
| 6 | Second booking the same day | Refused, pointing to the existing booking (FR-011) |
| 7 | Third upcoming booking | Refused (FR-011a) |
| 8 | My bookings | Upcoming and past tabs with status and amounts (FR-018) |
| 9 | Raise `settings/booking.visitPrice` in the Emulator UI, reopen the booking | Old price still shown (FR-015) |
| 10 | Cancel a booking more than 3 h ahead | Cancelled; the hour's places go up at once (FR-021) |
| 11 | Change a booking to another hour | Same number, new time, old place freed (FR-022) |
| 12 | Booking within 3 h | No cancel or change; "كلمي العيادة" opens WhatsApp (FR-020) |
| 13 | Add an active `packages` doc for the guardian | "مغطّى بالباقة"; vaccines still charged (FR-016) |
| 14 | Delete the account with an upcoming booking | Booking cancelled; place freed (research R9) |
| 15 | Dark mode, large text, RTL chevrons on all booking screens | No overflow; forward ‹, back › |

## Not testable locally

Reminders (007) and online payment (Phase 2).
