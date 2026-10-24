# Implementation Plan: Child Profile and Vaccines

**Branch**: `003-child-profile` | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/003-child-profile/spec.md`

**Design**: `docs/design/figma/child-profile.jpg` and `docs/design/screens/FollowUp.dc.html` (see
[routes](contracts/routes.md)). Colours and components from `docs/design/tokens.css`. The app's RTL rule
applies (forward ‹, back ›), checked by the existing RTL and layout tests.

## Summary

Guardians read their children's medical record: latest measurements and a growth chart of the child's own
values, the vaccine schedule with dose states, visit history with prescription photos, age follow-up with
"متى تتصلين بالدكتور" and call buttons, and the family package. Records are subcollections of the child, so
001's `linkedGuardian` rule protects them ([research R1](research.md#r1-where-medical-records-live-fr-013-fr-021)).
Dose states are computed in the app from a doctor-owned schedule ([R3](research.md#r3-dose-states-fr-008-sc-002)).
Prescription photos are in Cloud Storage behind rules that mirror the Firestore checks, read with the SDK
and cached for offline ([R4](research.md#r4-prescription-photos-fr-014-fr-015-fr-022)). No new Cloud
Functions: guardians only read; staff writes come in 004.

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47 (app); TypeScript on Node.js 22 (seed and tests) — as 001

**Primary Dependencies**: as 002, plus `firebase_storage` (prescription photos, D-30) and `path_provider`
(app cache folder for offline photos); reasons in [research R4](research.md#r4-prescription-photos-fr-014-fr-015-fr-022)

**Storage**: Cloud Firestore and Cloud Storage; model in [data-model.md](data-model.md)

**Testing**: as 001 (flutter_test, integration_test on the simulator, Mocha + rules-unit-testing), plus
Storage rules tests on the Storage emulator and table tests for dose states at every boundary

**Target Platform**: Android 8+, iOS 15+

**Project Type**: mobile app plus Firebase backend

**Performance Goals**: profile screens open within 3 s on 4G (D-22, SC-006)

**Constraints**: read-only for guardians; no medical judgments (D-37); doctor-owned text as placeholders
(D-36); offline reading (D-21); Storage deployment blocked: Blaze (D-38)

**Scale/Scope**: one clinic, ~1000 families; per child tens of measurements and doses; 5 screens

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Child Data Protection | Records under the child, readable only by the linked active guardian with current consent; prescriptions also by the doctor, never the secretary; no guardian writes; rules tested for Firestore and Storage; guardian reads not audited (1.1.2); photo cache cleared on sign-out | Pass |
| II. Doctor-Owned Medical Content | Schedule, additional vaccines, follow-up and danger signs are doctor data, seeded as bracketed placeholders; no judgments: values and the child's own chart only, a forbidden-words test | Pass |
| III. Configurable, Not Hardcoded | Late threshold, follow-up age limit, schedule source and review date, clinic phone are settings; schedule in Firestore | Pass |
| IV. Arabic First | Arabic RTL screens, light and dark, RTL chevron rule tested | Pass |
| V. Phase Discipline | Read-only guardian view; reminders (007), content (005), staff entry (004) excluded | Pass |
| VI. Simple and Testable | Two dependencies with stated reasons; chart drawn without a library; every FR mapped to tests ([quickstart](quickstart.md)) | Pass |
| VII. Cost and Reliability | Cloud Storage needs Blaze before the closed test: developed on the emulator, deployment marked "blocked: Blaze"; offline reading from caches | Pass |

**Post-design re-check**: Pass.

## Project Structure

### Documentation (this feature)

```text
specs/003-child-profile/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── firestore-access.md
│   ├── storage-access.md
│   └── routes.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
lib/features/child_profile/
├── data/               # measurements, doses, visits, schedule, follow-up repositories; prescription photo store
├── domain/             # dose states, due dates, age bands, latest values, chart scale, package state (pure Dart)
├── application/        # selected child
└── presentation/       # my_child_screen, growth_chart, vaccines_screen, visits_screen,
                        # prescription_screen, follow_up_screen, widgets

storage.rules           # prescriptions read rules
firebase.json           # + storage emulator (9199) and rules
functions/scripts/      # seed: schedule, follow-up, sample records, a sample prescription image
functions/test/rules/   # 003 Firestore rules + Storage rules
integration_test/       # child profile end-to-end
emulator-seed/          # + storage_export
```

**Structure Decision**: a new `child_profile` feature folder; the existing `children` folder (001) keeps
adding and editing children. `/children` now opens the profile instead of the list (clarification Q3).

## Complexity Tracking

No constitution violations to justify.
