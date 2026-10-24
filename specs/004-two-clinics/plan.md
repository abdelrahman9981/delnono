# Implementation Plan: Two Clinics

**Branch**: `004-two-clinics` | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/004-two-clinics/spec.md`

**Design**: Home from `docs/design/figma/home.jpg` (doctor card, then clinic cards); booking, success and
my bookings as 002 with a clinic step and the clinic's name and address. RTL rule as before.

## Summary

Each clinic becomes one Firestore document with its details, schedule and prices
([research R1](research.md#r1-one-document-per-clinic-fr-001-to-fr-005)); `settings/booking` keeps only
the family-wide horizon and upcoming maximum. Slots are per clinic
([R2](research.md#r2-slots-per-clinic-fr-008)); family limits stay one quota document across clinics
([R3](research.md#r3-family-limits-across-clinics-fr-011-d-49)). The booking callables take a clinic id,
the app adds a clinic step and Home clinic cards, and every booking, visit, measurement, dose and
package records its clinic ([R5](research.md#r5-records-carry-their-clinic-fr-016-fr-018)).

## Technical Context

**Language/Version**: as 001–003 (Dart 3.13 / Flutter 3.47; TypeScript on Node.js 22)

**Primary Dependencies**: as 003; no new packages

**Storage**: Cloud Firestore; model in [data-model.md](data-model.md)

**Testing**: as 001–003; booking and rules tests updated for clinics; new cases for two clinics,
cross-clinic limits and package coverage at either clinic. Simulator tests once at the end.

**Target Platform**: Android 8+, iOS 15+

**Project Type**: mobile app plus Firebase backend

**Performance Goals**: as 002 (booking screens within 3 s on 4G)

**Constraints**: settings per clinic (Principle III, constitution 1.3.0); data until 005 is placeholder
(D-36); Functions on the emulators until Blaze (D-40)

**Scale/Scope**: 2 clinics (more possible); 3 screens changed, Home added

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Child Data Protection | Clinic documents hold no personal data (public read); child records keep 003's rules; secretaries' clinic scope is enforced in 005 on the `clinicId` stored here | Pass |
| II. Doctor-Owned Medical Content | Vaccine names and schedule stay the doctor's shared data; only prices and offers per clinic | Pass |
| III. Configurable, Not Hardcoded | Every clinic value in `clinics/{id}`; family-wide values in `settings/booking` | Pass |
| IV. Arabic First | New screens Arabic RTL, light and dark | Pass |
| V. Phase Discipline | No dashboard screens here (005) | Pass |
| VI. Simple and Testable | No new dependency; one document per clinic | Pass |
| VII. Cost and Reliability | Runs on the emulators; no scheduled jobs; old records read with a fallback instead of a migration function | Pass |

**Post-design re-check**: Pass.

## Project Structure

```text
specs/004-two-clinics/  plan, research, data-model, quickstart, contracts/, checklists/, tasks

lib/features/clinics/            # clinic model, clinics repository (+ main clinic)
lib/features/home/               # Home screen with doctor card and clinic cards
lib/features/booking/            # clinic step, per-clinic schedule, slots, prices; clinic on cards
lib/features/child_profile/      # clinic on visits; per-clinic call buttons; per-clinic prices of additional vaccines
functions/src/lib/booking/       # clinic settings and prices, slot ids per clinic
functions/src/callables/         # create/change/cancel/deleteAccount with clinics
functions/scripts/seed.ts        # two clinics, clinic ids on every record
```

**Structure Decision**: a small `clinics` feature folder shared by Home, booking and the child profile.

## Complexity Tracking

No constitution violations to justify.
