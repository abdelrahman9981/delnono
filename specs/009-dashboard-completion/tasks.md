# Tasks: Dashboard Completion (desk registration and duplicate files)

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/callables.md](contracts/callables.md)
**Tests**: required (constitution V): Functions tests per callable before the code, widget and layout tests for the screens.

## Phase 1: Setup

- [X] T001 Move `phoneE164` from functions/src/callables/staff/childFile.ts to functions/src/lib/phone.ts and import it in childFile.ts (no behaviour change)
- [X] T002 [P] Add Arabic strings for registration, duplicates, merge and staff link to l10n/app_ar.arb and run `flutter gen-l10n`

## Phase 2: Foundational

- [X] T003 Add `registerFamily`, `mergeChildren`, `staffLinkChildren` to the dashboard error reasons in lib/dashboard/widgets/dash_page.dart (`duplicate`, `same_file`, `other_number`, `closed`, `booked_together`, `too_large`, `no_account`, `already_linked`)

## Phase 3: User Story 1 + 2 — Desk registration with the duplicate check (P1)

**Goal**: Staff register a number and children; duplicates create nothing and point to the existing file (FR-001–FR-004, FR-009).
**Independent test**: functions/test/functions/staff/family.test.ts "registerFamily" block; test/dashboard/family_test.dart registration tests.

- [X] T004 [US1] Write tests first in functions/test/functions/staff/family.test.ts: stores `clinicGuardians/{phone}` with name and relation; registers 2 children unlinked with `registeredBy: "staff"`, `registeredAt` and audit `family.registered`; phone formats; validation errors carry `{field, index}`; secretary of clinic 1 cannot register at clinic 2; the app's linking (`linkClinicChildren`) then links them; duplicates (existing file with other spelling, twice in one request) create nothing and return `duplicates`; same name on another number is not a duplicate
- [X] T005 [US1] Implement `registerFamily` in functions/src/callables/staff/family.ts (one transaction: duplicate query per child as `createChild`, then create) and export it in functions/src/index.ts
- [X] T006 [US1] Add `RegisterFamilyDialog` in lib/dashboard/screens/register_family_dialog.dart: number, guardian name and relation, child rows (name, birth date from a date picker, sex, optional birth weight and allergies), add/remove child, save; on `duplicate` show each duplicate with "افتحي الملف" (go to /children/{id}) and keep the form
- [X] T007 [US1] Open it from "+ تسجيل أسرة" in lib/dashboard/screens/children_search_screen.dart and from a walk-in row in lib/dashboard/screens/today_screen.dart (prefilled number and names)
- [X] T008 [US1] Widget tests in test/dashboard/family_test.dart: sends the request shape; walk-in prefill; duplicate warning lists the child and links to its file

## Phase 4: User Story 3 — The doctor merges two files (P2)

**Goal**: FR-005–FR-007, FR-009.
**Independent test**: "mergeChildren" block in family.test.ts; merge widget tests.

- [X] T009 [US3] Tests first in functions/test/functions/staff/family.test.ts: doctor merges, records (with `changes` and `staff/notes`) move unchanged, closed file has `merged` and no number, link or name key; search and the guardian's query no longer return it; upcoming confirmed booking repointed, past one untouched; `booked_together`, `same_file`, `other_number`, `closed`, `doctor_only` refusals; audit `children.merged`; `openChildFile` on a closed file returns `merged`
- [X] T010 [US3] Implement `mergeChildren` in functions/src/callables/staff/family.ts and the closed-file response in `openChildFile` (functions/src/callables/staff/childFile.ts)
- [X] T011 [US3] Add `MergeDialog` in lib/dashboard/screens/merge_dialog.dart (other open files on the same number via `searchChildren`, side-by-side basic data and record counts, confirm) and the doctor-only "دمج ملف مكرر" action plus the merged-file notice in lib/dashboard/screens/child_file_screen.dart
- [X] T012 [US3] Widget tests in test/dashboard/family_test.dart: no merge action for a secretary; the doctor's merge sends `{keepId, closeId}`; a closed file shows the notice with a link to the kept file

## Phase 5: User Story 4 — Staff link after a locked link (P3)

**Goal**: FR-008, FR-009.

- [X] T013 [US4] Tests first in functions/test/functions/staff/family.test.ts: links all unlinked children on the number to the guardian account, clears `linkAttempts` and `clinicChildrenPending`, audit `children.linked_by_staff`; `no_account`, `already_linked`
- [X] T014 [US4] Implement `staffLinkChildren` and `unlockReverify` in functions/src/callables/staff/family.ts (tests first: clears `reverifyAttempts/{uid}`, `not_locked`, audit); `openChildFile` returns `accountOnNumber`, `reverifyLocked` and `clinicGuardian`
- [X] T015 [US4] "ربط بحساب ولي الأمر" for an unlinked child with an account on the number and "فك قفل التحقق" for a locked guardian, each with a confirmation, in the child file header, in lib/dashboard/screens/child_file_screen.dart; widget test in test/dashboard/family_test.dart

## Phase 6: Polish

- [X] T016 Add the new dialogs and states to test/dashboard/layout_test.dart (desktop and tablet, light and dark, normal and large text)
- [X] T017 Rules tests: staff still cannot write `children` directly; a closed file is not readable by its former guardian (functions/test/rules/staff.test.ts)
- [X] T018 Mark tasks done, update specs/009-dashboard-completion/quickstart.md if anything changed; run analyze, flutter test, functions and rules tests; e2e at merge

## Dependencies

Setup → Foundational → US1/2 → US3 and US4 (independent of each other) → Polish.
