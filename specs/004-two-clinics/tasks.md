---

description: "Task list for 004 Two clinics"
---

# Tasks: Two Clinics

**Input**: Design documents from `/specs/004-two-clinics/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included (constitution Principle VI). Existing 002 and 003 tests are updated, not deleted.
Per phase: analyze, `flutter test`, `npm test`, `npm run test:rules`; simulator tests once at the end.

**Organization**: by user story (US1–US6 in spec.md). All user-facing text in `l10n/app_ar.arb`.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

- [ ] T001 Seed (`functions/scripts/seed.ts`): two `clinics` per data-model.md (placeholders in brackets, different hours, vaccine days, capacity, prices and cancel window as in quickstart.md, `vaccinePrices` for v1–v4 with one vaccine not offered at clinic 2); reduce `settings/booking` to `bookingHorizonDays` and `maxUpcomingPerFamily`; drop `price`/`showPrice` from `vaccines`; drop the numbers from `settings/clinic`; `clinicId` on every seeded visit, measurement and dose (both clinics used). Re-export `emulator-seed/`.
- [ ] T002 [P] `firestore.rules`: `clinics/{id}` read by anyone, never written; rules tests in `functions/test/rules/clinics.test.ts`.
- [ ] T003 [P] Create `lib/features/clinics/{data,domain}` and `lib/features/home/`.

---

## Phase 2: Foundational

- [ ] T004 `functions/src/lib/booking/settings.ts`: `ClinicSettings` from `clinics/{id}` (schedule, cancel window, visit price, `vaccinePrices`) with 002's defaults, `FamilySettings` from `settings/booking`, and `mainClinicId`; tests in `functions/test/lib/bookingSettings.test.ts`.
- [ ] T005 `functions/src/lib/booking/time.ts`: `slotId(clinicId, date, hour)`; update callers and tests.
- [ ] T006 `functions/src/lib/booking/book.ts`: `readForSelection` reads the clinic and family settings, the clinic's slot, and vaccines that are active and offered at the clinic with the clinic's prices; `checkSelection` uses the clinic's schedule and the family maximum.
- [ ] T007 [P] App: `lib/features/clinics/data/clinics_repository.dart` (Clinic model per data-model.md, `clinicsProvider` of active clinics in order, `clinicProvider(id)`, `mainClinicProvider`); `familySettingsProvider` replacing the clinic part of 002's `bookingSettingsProvider`; tests.
- [ ] T008 App domain: 002's `schedule.dart` and `price_preview.dart` take a clinic (hours, vaccine days, capacity, prices); slots provider keyed by clinic and date; offered vaccines per clinic; tests updated.

---

## Phase 3: User Story 1 – Book at the clinic I choose (P1) 🎯 MVP

- [ ] T009 [US1] Functions tests first in `functions/test/functions/createBooking.test.ts`: booking at each clinic uses its hours, capacity and prices; full hour at one clinic does not affect the other; inactive clinic refused; vaccine not offered refused; booking and slot carry `clinicId`.
- [ ] T010 [US1] `createBooking` takes `clinicId` (contracts/callables.md); update `functions/test/helpers/booking.ts`.
- [ ] T011 [US1] App: booking form holds `clinicId`; clinic step first (skipped with one clinic or `?clinic=`); booking API sends `clinicId`; `Booking` model reads `clinicId` (fallback main clinic).
- [ ] T012 [US1] Success screen and My bookings cards show the clinic's name and address.
- [ ] T013 [US1] Widget tests: clinic step, per-clinic hours and prices, clinic on success and cards; update 002 widget tests and `integration_test/booking_test.dart`, `cancel_change_test.dart`.

## Phase 4: User Story 2 – Family limits across clinics (P1)

- [ ] T014 [US2] Functions tests: same day at the other clinic refused; third upcoming across clinics refused; concurrent last place per clinic (002 race tests per clinic).

## Phase 5: User Story 3 – Home shows both clinics (P1)

- [ ] T015 [US3] `lib/features/home/home_screen.dart` per home.jpg: greeting (name when signed in), doctor card with placeholder photo, "عياداتنا" with one card per active clinic (name, address, working days and hours summary, call, WhatsApp, "احجزي هنا" → `/booking?clinic=<id>`); replace `HomePlaceholder`.
- [ ] T016 [US3] Keep `clinic` through sign-in and registration (001 `from`), and preselect it in the booking form.
- [ ] T017 [US3] Widget tests for Home (cards, buttons, hidden numbers, inactive clinic) and the preselected clinic.

## Phase 6: User Story 4 – Change, cancel and contact by clinic (P2)

- [ ] T018 [US4] Functions: `cancelBooking` and `changeBooking` use the booking's clinic (window, schedule, prices, slot); change cannot move clinics; tests.
- [ ] T019 [US4] App: My bookings uses the booking's clinic cancel window and WhatsApp; change form fixed to the booking's clinic; Account support WhatsApp from the main clinic; tests.

## Phase 7: User Story 5 – Package valid in both clinics (P2)

- [ ] T020 [US5] Functions tests: package sold at clinic 1 covers a visit at clinic 2; vaccines charged at clinic 2 prices; the app's package lookup unchanged; `soldAtClinicId` in the seed and data model.

## Phase 8: User Story 6 – The child's record shows where (P3)

- [ ] T021 [US6] 003 models read `clinicId` (fallback main clinic); visit history shows the clinic name; additional vaccines show each clinic's shown price; follow-up shows one call button per clinic with a phone plus 123; tests updated.

## Phase 9: Polish

- [ ] T022 `deleteAccount` frees slots at each booking's clinic; test.
- [ ] T023 [P] Layout and RTL tests for Home and the clinic step; hard-coded strings check.
- [ ] T024 Quickstart coverage table; run every automated check and all simulator tests once; all pass.

---

## Dependencies & Execution Order

```text
Setup → Foundational → US1 → { US2, US3, US4, US5, US6 } → Polish
```

## Implementation Strategy

MVP = Setup + Foundational + US1 (book at a chosen clinic). Then limits, Home, change/cancel,
package, child record, polish.
