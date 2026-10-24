---

description: "Task list for 005 Clinic dashboard"
---

# Tasks: Clinic Dashboard

**Input**: Design documents from `/specs/005-clinic-dashboard/`

**Tests**: Included. Per phase: analyze, `flutter test`, `npm test`, `npm run test:rules`; the guardian
app's simulator tests once at the end. All user-facing text in `l10n/app_ar.arb`.

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

- [X] T001 Add the web platform (`flutter create --platforms=web .`), web Firebase options for `demo-delnono` (and `dr-elnono-clinic` for prod), and `lib/dashboard/main.dart` with emulator connection as the app's.
- [X] T002 Seed: `staff` documents and Auth users for the doctor and one secretary per clinic (emulator password `Delnono-2026`, claims set), `packageMonths: 12` on clinics, and today-relative sample bookings are made by the dashboard tests instead (the seed has fixed dates). Re-export `emulator-seed/`.
- [X] T003 [P] Folders `lib/dashboard/{screens,data,widgets}`, `functions/src/callables/staff`, `functions/test/functions/staff`.

## Phase 2: Foundational

- [X] T004 `functions/src/lib/staff.ts`: `requireStaff(request, {role?, clinicId?})` (active staff record and claims; secretaries limited to their clinic); tests.
- [X] T005 `firestore.rules`: staff reads per contracts/firestore-access.md (`isStaff()`, `staffOf(clinicId)`, `isDoctor()`); rules tests in `functions/test/rules/staff.test.ts` (other clinic refused, disabled refused, guardian refused).
- [X] T006 Dashboard shell: theme and l10n from the app, staff session (email sign-in, claims, `staff/{uid}` stream, forced password change), router with guard, side navigation that becomes a drawer, clinic switcher for the doctor; widget tests.
- [X] T007 `lib/dashboard/data/dashboard_api.dart`: one method per callable, mapping errors to Arabic messages.

## Phase 3: User Story 1 – Staff accounts (P1) 🎯

- [X] T008 [US1] `manageStaff` and `staffPasswordChanged` callables (create with temporary password and claims, update, disable with token revoke, never the last doctor); tests.
- [X] T009 [US1] Sign-in, password and Staff screens; widget tests.

## Phase 4: User Story 2 – Today (P1)

- [X] T010 [US2] `queueAction` (arrive, done with visits per child, no-show after the hour, doctor undo same day), `addWalkIn` (capacity, stopped day), `setWalkInsStopped`, `staffBookingAction`; tests.
- [X] T011 [US2] Today screen: hour calendar with places left, bookings per hour with actions, arrival queue by arrival time, walk-in form, stop walk-ins switch; widget tests.

## Phase 5: User Story 3 – Payments and packages (P1)

- [X] T012 [US3] `recordPayment` and `sellPackage`; tests.
- [X] T013 [US3] Payment and package dialogs on Today; widget tests.

## Phase 6: User Story 4 – Child file (P1)

- [X] T014 [US4] `searchChildren`, `openChildFile` (audit), `saveMeasurement`, `saveDose` (create vs doctor correction with change log), `saveVisitNote`, `updateChildBasics`; tests.
- [X] T015 [US4] Child search and file screens (basics, measurements, doses, visits, notes for the doctor); widget tests.

## Phase 7: User Story 5 – Clinic, prices and vaccines (P2)

- [X] T016 [US5] `updateClinic` (field whitelist per role; audit of price changes; refuses removing hours or adding holidays that still hold confirmed bookings, listing them) and `updateCatalogue` (doctor); tests.
- [X] T017 [US5] Clinic and Vaccines screens; widget tests.

## Phase 8: User Story 6 – Content and follow-up (P2)

- [X] T018 [US6] `saveContent`, `saveFollowUpDraft`, `publishFollowUp`; rules for `content` (published public); tests.
- [X] T019 [US6] Content and Follow-up screens; widget tests.

## Phase 9: User Story 7 – Reports (P2)

- [X] T020 [US7] `report` callable (day and month rows, six numbers, per clinic or all for the doctor); tests.
- [X] T021 [US7] Reports screen with date range and CSV without names or medical data; widget tests (CSV content).

## Phase 10: User Story 8 – Settings and audit (P3)

- [X] T022 [US8] `updateSettings` (doctor); tests.
- [X] T023 [US8] Settings and Audit log screens (doctor); widget tests.

## Phase 11: Polish

- [X] T024 Layout tests for the dashboard screens (desktop and tablet width, light and dark, RTL icons); hard-coded strings check.
- [ ] T025 Quickstart coverage table; run every automated check and the guardian app's simulator tests once; build the dashboard for the web (`flutter build web -t lib/dashboard/main.dart`). Hosting deploy is later (blocked: Blaze for the callables, D-40).

## Dependencies

Setup → Foundational → US1 → { US2 → US3, US4, US5, US6, US7, US8 } → Polish
