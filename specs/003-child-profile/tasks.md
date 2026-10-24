---

description: "Task list for 003 Child profile and vaccines"
---

# Tasks: Child Profile and Vaccines

**Input**: Design documents from `/specs/003-child-profile/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included (constitution Principle VI; rules tests gate "done"). Within each story, write the
tests first and confirm they fail.

**Organization**: by user story (US1–US6 in spec.md). Paths as in 001 and 002: `lib/`, `test/`,
`integration_test/`, `functions/`, `firestore.rules`, `storage.rules`. Screens follow
`docs/design/figma/child-profile.jpg` and `docs/design/screens/FollowUp.dc.html`; forward chevrons ‹,
back ›. All user-facing text goes in `l10n/app_ar.arb`. No screen may show a medical judgment (D-37).

## Format: `[ID] [P?] [Story] Description`

---

## Phase 1: Setup

- [ ] T001 Add `firebase_storage` and `path_provider` to `pubspec.yaml` (reasons in research R4); in `lib/core/firebase/firebase_init.dart` connect `FirebaseStorage.instance` to the Storage emulator (port 9199) when `USE_EMULATOR` is set.
- [ ] T002 [P] Add the Storage emulator (port 9199) and `"storage": {"rules": "storage.rules"}` to `firebase.json`; create `storage.rules` denying everything; add `storage` to the emulator lists in `functions/package.json` (`test`, `test:rules`), the integration commands in `specs/003-child-profile/quickstart.md`, and the check script. Storage deployment stays **blocked: Blaze**.
- [ ] T003 Extend `functions/scripts/seed.ts` per data-model.md: `settings/vaccines` (source, reviewedOn, `lateAfterDays: 7`), placeholder `vaccineSchedule` (basic doses in brackets at birth, 2, 4, 6, 9, 12, 18 months, some with `lastAge`), additional fields on two `vaccines` with `kind: additional`, `followUp` bands (0–48 months, items in brackets), `settings/followUp` (`maxAgeMonths: 48`, danger signs in brackets), `settings/clinic.phoneNumber`; a third unlinked clinic child under one year; measurements, doses (with and without lot), visits for the clinic children, one with a two-page prescription uploaded to the Storage emulator from `functions/scripts/assets/prescription-sample.png` (a generated placeholder image marked "عينة"). Re-export `emulator-seed/` including `storage_export`.
- [ ] T004 [P] Create the folders `lib/features/child_profile/{data,domain,application,presentation}`.

---

## Phase 2: Foundational (Blocking Prerequisites)

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

- [ ] T005 [P] Rules tests first, in `functions/test/rules/child-records.test.ts`, for every row of contracts/firestore-access.md (measurements, doses, visits, `staff` and `changes` subcollections, `vaccineSchedule`, `followUp`, settings).
- [ ] T006 Extend `firestore.rules` to pass T005: child subcollections readable by `linkedGuardian(get(child))`, never writable; `vaccineSchedule` and `followUp` read when signed in.
- [ ] T007 [P] Storage rules tests first, in `functions/test/rules/storage.test.ts`, for every row of contracts/storage-access.md (linked guardian, other guardian, outdated consent, inactive guardian, doctor and secretary claims, anonymous, writes).
- [ ] T008 Write `storage.rules` to pass T007 (cross-service `firestore.get` of the child and guardian documents and `settings/auth.reverifyAfterDays`, as 001's `linkedGuardian`).
- [ ] T009 [P] Create `lib/features/child_profile/domain/child_age.dart`: age in months and days from a birth date in Cairo time, due date = birth date + `{months, days}` (calendar months clamped to the month's end), Arabic age labels; tests in `test/features/child_profile/child_age_test.dart` (month-end clamping, leap day).
- [ ] T010 [P] Create the read models and repositories in `lib/features/child_profile/data/`: `measurements_repository.dart`, `doses_repository.dart`, `visits_repository.dart`, `vaccine_schedule_repository.dart` (schedule entries, additional vaccines, `settings/vaccines` with defaults), `follow_up_repository.dart` (`followUp`, `settings/followUp` with defaults), with Riverpod stream providers per child.
- [ ] T011 Create `lib/features/child_profile/application/selected_child.dart`: the selected child id, defaulting to the first linked child and stored on the device (research R8); falls back when the child is no longer linked.
- [ ] T012 Create `lib/features/child_profile/presentation/my_child_screen.dart` with the top bar ("دكتور النونو", "ملف طفلي"), the child switcher (initial, name, age) and entries to vaccines, visits and follow-up, plus "تعديل البيانات" (001 details) and "إضافة طفل"; without children, 001's add-child prompt. Route `/children` to it and add the nested routes of contracts/routes.md in `lib/app/router.dart`; remove the old list screen and update its tests.
- [ ] T013 [P] Add the 003 Arabic strings to `l10n/app_ar.arb` (no judgment words) and regenerate localizations.

**Checkpoint**: rules pass; `/children` shows the switcher and entries.

---

## Phase 3: User Story 1 – Latest measurements and growth chart (P1) 🎯 MVP

**Goal**: latest weight, length, head with dates; chart of the child's own values; no judgments.

**Independent Test**: a child with three seeded measurements shows the latest values and the chart points.

- [ ] T014 [P] [US1] Tests first: `test/features/child_profile/latest_measurements_test.dart` (latest per value with its own date; missing head shows "لسه متسجلش"; birth weight as the birth point) and `test/features/child_profile/chart_scale_test.dart` (round ticks, single point, age axis).
- [ ] T015 [US1] Create `lib/features/child_profile/domain/latest_measurements.dart` and `domain/chart_scale.dart` to pass T014.
- [ ] T016 [US1] Create `lib/features/child_profile/presentation/growth_chart.dart` (CustomPainter, research R5: points, line, area fill, weight/length/head tabs, no reference curves or ranges) and, on `my_child_screen.dart`, the child's age and allergies line (FR-002) and the measurement cards per the design ("آخر قياسات …", "اتحدثت …").
- [ ] T017 [US1] Widget test `test/features/child_profile/my_child_screen_test.dart`: switcher changes all sections, latest values and dates, empty state without measurements, chart tabs.

---

## Phase 4: User Story 2 – Vaccine schedule and doses (P1)

**Goal**: basic doses by age with states, given dose details, additional vaccines marked, source and review date.

**Independent Test**: seeded schedule and doses give the expected state for every dose.

- [ ] T018 [P] [US2] Tests first: `test/features/child_profile/dose_state_test.dart`, a table over research R3 including the day before and after each boundary (due date, due + `lateAfterDays`, `lastAge`), given early, and additional vaccines without state (SC-002).
- [ ] T019 [US2] Create `lib/features/child_profile/domain/dose_state.dart` to pass T018.
- [ ] T020 [US2] Create `lib/features/child_profile/presentation/vaccines_screen.dart` (`/children/:id/vaccines`): source and "آخر مراجعة", basic doses grouped by `ageLabel` with due date and state pill (date and lot for given), the "إضافي" section with suggested age, doses, interval, note, price only when `showPrice`, and a line that the choice is the family's.
- [ ] T021 [US2] Widget test `test/features/child_profile/vaccines_screen_test.dart`: states shown, lot shown only when recorded, additional marker, hidden price, placeholder names in brackets.

---

## Phase 5: User Story 3 – Visit history and prescriptions (P2)

**Goal**: visits newest first with what was recorded; prescription pages full screen; others refused.

**Independent Test**: open a seeded visit's two-page prescription; another family cannot read it.

- [ ] T022 [P] [US3] Tests first: `test/features/child_profile/prescription_store_test.dart` (bytes cached after the first read, served from cache when the read fails, cache cleared on request).
- [ ] T023 [US3] Create `lib/features/child_profile/data/prescription_store.dart`: `getData` with the SDK (never download URLs), cache in the app support folder under `prescriptions/` (research R4), and a `clear()` called from `AuthRepository.signOut` (with the Firestore cache).
- [ ] T024 [US3] Create `presentation/visits_screen.dart` (`/children/:id/visits`: date, visit type, measurements and doses of the visit, "الروشتة" entry when pages exist) and `presentation/prescription_screen.dart` (pages in order, `InteractiveViewer` zoom, offline message for a page never opened).
- [ ] T025 [US3] Widget tests `test/features/child_profile/visits_screen_test.dart` and `prescription_screen_test.dart` (order, no entry without pages, error state).

---

## Phase 6: User Story 4 – Age follow-up and when to call (P2)

**Goal**: current age band items and danger signs with clinic and 123 buttons; hidden from age 4.

**Independent Test**: a 9-month-old shows its band; the 4-year-old shows only danger signs; buttons open the dialer.

- [ ] T026 [P] [US4] Tests first: `test/features/child_profile/age_band_test.dart` (band boundaries, no band from `maxAgeMonths`).
- [ ] T027 [US4] Create `domain/age_band.dart` and `presentation/follow_up_screen.dart` (`/children/:id/follow-up`) per `FollowUp.dc.html`: band title, items, "أمثلة مؤقتة · يعتمدها الدكتور" while placeholder, danger card "متى تتصلين بالدكتور" with "اتصلي بالعيادة" (`tel:` clinic phone, hidden when unset) and "الإسعاف ١٢٣" (`tel:123`), the "لا تشخّص" note, and the over-4 note.
- [ ] T028 [US4] Widget test `test/features/child_profile/follow_up_screen_test.dart` with a fake `ExternalLinks` checking both `tel:` links and the hidden clinic button.

---

## Phase 7: User Story 5 – Package status (P3)

- [ ] T029 [P] [US5] Tests first: `test/features/child_profile/package_state_test.dart` (active, ended, months left, none).
- [ ] T030 [US5] Create `domain/package_state.dart` and the package card on `my_child_screen.dart` (reuse 002's packages repository); widget cases in `my_child_screen_test.dart`.

---

## Phase 8: User Story 6 – Read offline (P2)

- [ ] T031 [US6] Show "إنتي أوفلاين · دي آخر بيانات اتحملت" on profile screens when snapshots come from the cache (research R7), and a first-time-needs-connection message when nothing was ever loaded; widget cases in `my_child_screen_test.dart`.
- [ ] T032 [US6] Integration test `integration_test/child_profile_test.dart`: sign up the seeded clinic number, link the children, check measurements, chart, vaccines states, visits and the prescription photo, follow-up and call buttons; then disable the Firestore network and restart the app tree and check the sections and the opened photo still show.

---

## Phase 9: Polish & Cross-Cutting Concerns

- [ ] T033 [P] Add a no-judgment test `test/features/child_profile/no_judgment_test.dart` that renders every 003 screen with seed-like data and fails on forbidden words (طبيعي، في المعدل، ممتاز، متأخر في النمو، percentile, normal, on track) and checks no ARB string contains them (SC-003).
- [ ] T034 [P] Add the 003 screens to `test/app/layout_test.dart` (light/dark, text ×2) and `test/app/rtl_navigation_test.dart` (back › on nested screens, forward ‹ on entries).
- [ ] T035 [P] Check no hard-coded user-facing strings in `lib/features/child_profile/` (as 001 T086).
- [ ] T036 Add the scenario coverage table to `specs/003-child-profile/quickstart.md` and run `npm test`, `flutter test` and every integration file; all must pass. Note Storage deployment as **blocked: Blaze**.

---

## Dependencies & Execution Order

```text
Setup → Foundational → US1 → { US2, US3, US4, US5 } → US6 → Polish
```

- US2–US5 each add a screen or card on top of the Foundational screen and can run in parallel.
- US6 needs the screens of US1–US4 to test offline reading.

### Parallel opportunities

- Foundational: T005/T007 (rules tests) with T009–T010 (app).
- Each story's domain test with another story's domain test.

## Implementation Strategy

MVP = Setup + Foundational + US1 (measurements and chart). Then vaccines (US2), visits and prescriptions
(US3), follow-up (US4), package (US5), offline (US6), polish.
