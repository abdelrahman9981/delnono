---

description: "Task list for 002 Booking"
---

# Tasks: Booking

**Input**: Design documents from `/specs/002-booking/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included (constitution Principle VI; rules tests gate "done"). Within each story, write the
tests first and confirm they fail.

**Organization**: by user story (US1–US6 in spec.md). Paths as in 001: `lib/`, `test/`,
`integration_test/`, `functions/src/`, `functions/test/`, `firestore.rules`. Screens follow
`docs/design/figma/booking.jpg`, `booking-success.jpg`, `my-bookings.jpg`; forward chevrons ‹, back ›.
All user-facing text goes in `l10n/app_ar.arb`.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

- [ ] T001 Add `settings/booking` and placeholder `vaccines` to `functions/scripts/seed.ts` per data-model.md (capacity 6; working hours Sat–Thu 17–21, Fri closed; vaccine weekdays Mon and Wed; visit price 300; cancel window 3; horizon 14; max upcoming 2; `placeholder: true`; vaccine names in brackets, e.g. "[تطعيم مؤقت ١]", some with `showPrice: false`), then re-export `emulator-seed/`.
- [ ] T002 [P] Add the composite indexes for `bookings` (`guardianUid` + `startsAt`; `guardianUid` + `date` + `status`) to `firestore.indexes.json`.
- [ ] T003 [P] Create the folders `lib/features/booking/{data,domain,application,presentation}` and `functions/src/lib/booking/`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T004 [P] Create `functions/src/lib/booking/time.ts`: Cairo date/hour ↔ `startsAt` with the IANA zone `Africa/Cairo` (summer time correct), weekday of a date, `slotId(date, hour)` = `YYYY-MM-DD_HH`; tests in `functions/test/lib/bookingTime.test.ts` including a summer-time date.
- [ ] T005 [P] Create `functions/src/lib/booking/schedule.ts`: from `settings/booking`, decide if a date is open (working weekday, not a holiday, within horizon), if an hour is within working hours and not started, and if a date is a vaccine day; returns the reasons named in contracts/callables.md; tests in `functions/test/lib/bookingSchedule.test.ts`.
- [ ] T006 [P] Create `functions/src/lib/booking/pricing.ts`: price snapshot per research R4 (visit once or covered; vaccine lines per child, `amount: null` when hidden; `total`, `hasHiddenPrices`), and the change rule (kept lines keep amounts, new lines current prices, visit kept unless newly added); tests in `functions/test/lib/bookingPricing.test.ts`.
- [ ] T007 [P] Create `functions/src/lib/booking/settings.ts` reading `settings/booking` with the defaults of data-model.md.
- [ ] T008 Extend `firestore.rules` with `settings/booking` (read anyone, as other settings), `vaccines` (read signed in), `slots` (read signed in), `counters` (deny), and the `guardianActive()` helper (`consentCurrent()` and `active()` from 001) for later rows; tests in `functions/test/rules/booking-base.test.ts`.
- [ ] T009 [P] Create `lib/features/booking/data/booking_settings.dart` (model + stream of `settings/booking` with defaults) and `vaccines_repository.dart` (active vaccines), with providers.
- [ ] T010 [P] Create `lib/features/booking/domain/schedule.dart` mirroring T005 for display (open days within the horizon, hours of a day, started hours, vaccine days) with tests in `test/features/booking/schedule_test.dart` using the same cases as T005.
- [ ] T011 [P] Create `lib/features/booking/domain/price_preview.dart` mirroring T006 for the summary (visit once, covered by package, vaccine lines, hidden prices) with tests in `test/features/booking/price_preview_test.dart` using the same cases as T006.
- [ ] T012 [P] Create `lib/features/booking/data/slots_repository.dart`: live `taken` for the hours of one day; and `lib/features/booking/domain/booking.dart` (Booking model from data-model.md with `fromSnapshot`).
- [ ] T013 Add booking strings to `l10n/app_ar.arb` from the three Figma screens (titles, visit types, "اختاري اليوم", "اختاري الساعة", "الدخول بالأسبقية", "فاضل {n} من {m}", "مكتمل", "مين هييجي؟", "اختاري أكتر من طفل", summary labels, "مغطّى بالباقة", "باقة نشطة", "كاش في العيادة", "تقدري تلغي لحد {n} ساعات قبل الميعاد", success texts, my-bookings texts, statuses, errors including "الميعاد اتحجز").

**Checkpoint**: `npm test` and `flutter test` pass; seed loads.

---

## Phase 3: User Story 1 – Book a clinic visit (P1) 🎯 MVP

**Goal**: Pick day, hour and children; instant confirmation; success screen.

**Independent Test**: quickstart scenarios 1–2.

### Tests for User Story 1

- [ ] T014 [P] [US1] Create `functions/test/functions/createBooking.test.ts`: visit for one and for two children takes one place, visit price once, number assigned, event written; `invalid-argument` (unlinked child, malformed selection); `failed-precondition` reasons `closed`, `outside_hours`, `beyond_horizon`, `started`; `already-exists` for a second booking the same day (`details.bookingId`); `out-of-range` beyond `maxUpcomingPerFamily`; requires current consent.
- [ ] T015 [P] [US1] Create `functions/test/rules/bookings.test.ts` for every `bookings`, `events` and `packages` row in contracts/firestore-access.md (owner read with filter, other guardian, outdated consent, inactive guardian, no client writes).
- [ ] T016 [P] [US1] Create `test/features/booking/booking_screen_test.dart`: closed days disabled, hours show "فاضل N من M" and full hours "مكتمل" disabled, started hours hidden, multi-child selection, summary shows one visit price, confirm calls the API with the selection, errors in Arabic; no-children prompt.
- [ ] T017 [P] [US1] Create `test/features/booking/booking_success_screen_test.dart`: number "نونو ٢٤٨" style, day, hour, children, amount, arrival-order note, both buttons.

### Implementation for User Story 1

- [ ] T018 [US1] Create `functions/src/callables/createBooking.ts` per contracts/callables.md (one transaction: settings, slot, counter, same-day and upcoming queries, vaccines, package; booking, slot increment, counter, event) and export it.
- [ ] T019 [US1] Extend `firestore.rules` with `bookings`, `bookings/{id}/events` and `packages` read rules per contracts/firestore-access.md.
- [ ] T020 [P] [US1] Create `lib/features/booking/data/booking_api.dart` (createBooking, cancelBooking, changeBooking; maps errors to typed exceptions: full, closed reasons, already booked that day, too many upcoming) and `bookings_repository.dart` (stream of the guardian's bookings ordered by `startsAt`).
- [ ] T021 [US1] Create `lib/features/booking/application/booking_form_controller.dart`: selection state (visit type, date, hour, children, vaccines per child), validation, preview via T011, submit.
- [ ] T022 [US1] Create `lib/features/booking/presentation/booking_screen.dart` matching `booking.jpg`: step indicator, visit type cards, day chips (vaccine-day dots), hour cards with places left / "مكتمل", children cards with checkboxes, summary card, confirm; "حجوزاتي" top-bar action.
- [ ] T023 [US1] Create `lib/features/booking/presentation/booking_success_screen.dart` matching `booking-success.jpg`.
- [ ] T024 [US1] Wire `/booking`, `/booking/done/:id` in `lib/app/router.dart` (replacing the Booking placeholder) and add both screens to `test/app/layout_test.dart` (light/dark, text ×2, RTL icons).
- [ ] T025 [P] [US1] Create `integration_test/booking_test.dart`: register, add two children, book a visit for both, see the success screen and one place taken.

**Checkpoint**: a guardian can book and see the confirmation.

---

## Phase 4: User Story 2 – No double booking of the last place (P1)

**Independent Test**: quickstart scenario 3.

- [ ] T026 [P] [US2] Add a race test to `functions/test/functions/createBooking.test.ts`: an hour with one place left, N guardians call `createBooking` with `Promise.all`; exactly one succeeds, the rest get `resource-exhausted` with `reason: full`, and `taken` equals capacity.
- [ ] T027 [P] [US2] Add to `test/features/booking/booking_screen_test.dart`: "الميعاد اتحجز" on `full`, returning to the hour choice with the hour now shown full.
- [ ] T028 [US2] Handle `full` in the controller and screen (message, refresh, keep the rest of the selection).

---

## Phase 5: User Story 3 – Book vaccines (P1)

**Independent Test**: quickstart scenarios 4–5.

- [ ] T029 [P] [US3] Add to `createBooking.test.ts`: vaccine-only on a vaccine day (no visit price, one place), vaccines per child, `not_vaccine_day`, vaccine-only without vaccines, inactive vaccine, hidden-price vaccine (`amount: null`, `hasHiddenPrices`).
- [ ] T030 [P] [US3] Add to `booking_screen_test.dart`: only vaccine days selectable when vaccines are involved, vaccine picker per child, totals, hidden price shown as "بالسعر في العيادة".
- [ ] T031 [US3] Add the vaccine picker per child and vaccine-only flow to `booking_screen.dart` and the controller.

---

## Phase 6: User Story 4 – My bookings (P2)

**Independent Test**: quickstart scenarios 8–9.

- [ ] T032 [P] [US4] Create `test/features/booking/my_bookings_screen_test.dart`: upcoming (confirmed; arrived on its day) soonest first, past (done, cancelled, no-show) latest first, status pills, number, amount from the snapshot, empty state with "احجزي ميعاد جديد".
- [ ] T033 [US4] Create `lib/features/booking/presentation/my_bookings_screen.dart` matching `my-bookings.jpg` (tabs with counts, date tile, status pill, number, amount) and wire `/booking/mine`; add to the layout test.

---

## Phase 7: User Story 5 – Cancel or change (P2)

**Independent Test**: quickstart scenarios 10–12.

### Tests for User Story 5

- [ ] T034 [P] [US5] Create `functions/test/functions/cancelBooking.test.ts`: owner before the window → cancelled, place freed, event; inside the window → `inside_window`; not confirmed → `not_confirmed`; another guardian → `not-found`; uses `cancelWindowHours` from settings.
- [ ] T035 [P] [US5] Create `functions/test/functions/changeBooking.test.ts`: move to another hour (old freed, new taken, same number), same hour no count change, new hour full → original unchanged, inside the window refused, price rule (kept lines keep old amounts after a price rise; added lines current), own day does not count against one-per-day.
- [ ] T036 [P] [US5] Add to `my_bookings_screen_test.dart`: change and cancel before the window; inside it "فاضل أقل من ٣ ساعات" and "كلمي العيادة" opening WhatsApp; cancel needs a confirmation.

### Implementation for User Story 5

- [ ] T037 [US5] Create `functions/src/callables/cancelBooking.ts` and `changeBooking.ts` per contracts/callables.md and export them.
- [ ] T038 [US5] Add cancel (with confirmation), change (`/booking/change/:id`, booking screen pre-filled) and the inside-window card to the app.
- [ ] T039 [P] [US5] Create `integration_test/cancel_change_test.dart`: cancel frees the place; change keeps the number and moves the place.

---

## Phase 8: User Story 6 – Covered by package (P3)

**Independent Test**: quickstart scenario 13.

- [ ] T040 [P] [US6] Add to `createBooking.test.ts` and `bookingPricing.test.ts`: active package covering the date → visit covered, vaccines charged; expired or other family's package → charged.
- [ ] T041 [US6] Create `lib/features/booking/data/packages_repository.dart` (active package for a date) and show "باقة نشطة" / "مغطّى بالباقة" in the summary, success and my bookings.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [ ] T042 Extend `functions/src/callables/deleteAccount.ts` to cancel upcoming confirmed bookings and free their places (research R9); add cases to `functions/test/functions/deleteAccount.test.ts`.
- [ ] T043 [P] Check no hard-coded user-facing strings in `lib/features/booking/` (as 001 T086).
- [ ] T044 [P] Add the booking scenarios to `specs/002-booking/quickstart.md`'s coverage table and run all of them, `npm test`, `flutter test` and every integration file; all must pass.

---

## Dependencies & Execution Order

```text
Setup → Foundational → US1 → { US2, US3 } → US4 → US5 → US6 → Polish
```

- US2 and US3 extend US1's callable and screen; they can run in parallel after US1.
- US5 needs My bookings (US4) for its entry points.
- T042 (deleteAccount) can run any time after T018.

### Parallel opportunities

- Foundational: T004–T007 (functions) with T009–T012 (app).
- US1 tests T014–T017 together; T020 with T018–T019.

## Implementation Strategy

MVP = Setup + Foundational + US1 + US2 (book with exact capacity). Then vaccines (US3), my bookings
(US4), cancel and change (US5), package display (US6), polish.
