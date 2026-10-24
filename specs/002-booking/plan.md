# Implementation Plan: Booking

**Branch**: `002-booking` | **Date**: 2026-10-23 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/002-booking/spec.md`

**Design**: `docs/design/figma/booking.jpg`, `booking-success.jpg`, `my-bookings.jpg` (see
[routes](contracts/routes.md)). Colours and components from `docs/design/tokens.css`. The Figma chevrons
point the wrong way for RTL; the app's rule applies (forward ‹, back ›), checked by the existing RTL and
layout tests.

## Summary

Guardians book an hour slot (capacity 6 by default) for one or more children, as a clinic visit or
vaccine only, with prices fixed at booking time, and can cancel or change until 3 hours before. Booking,
cancel and change run as Cloud Functions in Firestore transactions over a per-hour counter, so the first
confirmation wins and an hour never exceeds capacity ([research R1](research.md#r1-atomic-capacity-first-confirm-wins-fr-009-sc-002)).
Settings and the vaccine list live in Firestore with placeholder values until feature 004.

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47 (app); TypeScript on Node.js 22 (functions) — as 001

**Primary Dependencies**: as 001; no new packages

**Storage**: Cloud Firestore; model in [data-model.md](data-model.md)

**Testing**: as 001 (flutter_test, integration_test on the simulator, Mocha + rules-unit-testing +
Functions emulator), plus a concurrency test that fires simultaneous `createBooking` calls on the last
place

**Target Platform**: Android 8+, iOS 15+

**Project Type**: mobile app plus Firebase backend

**Performance Goals**: booking screens open within 3 s on 4G (D-22); a guardian books in under 1 minute
(SC-001); a freed place is visible to others within 2 s (SC-003)

**Constraints**: app-only booking (D-27); cash at the clinic; Arabic RTL; settings not constants
(Principle III); placeholder vaccine names until the doctor's list (Principle II)

**Scale/Scope**: one clinic, ~6 places per hour, 100 concurrent users (D-22); 4 screens

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Child Data Protection | Bookings (child names) readable only by the owning active guardian with current consent; all writes in functions; rules tested ([firestore-access](contracts/firestore-access.md)) | Pass |
| II. Doctor-Owned Medical Content | Vaccine names and prices are clinic data, seeded as marked placeholders; no medical advice in booking | Pass |
| III. Configurable, Not Hardcoded | Capacity, hours, holidays, vaccine days, prices, cancel window, horizon, upcoming limit in `settings/booking` and `vaccines`; price changes do not touch confirmed bookings | Pass |
| IV. Arabic First | Arabic RTL screens from Figma; RTL chevron rule enforced by tests | Pass |
| V. Phase Discipline | Clinic visits and cash only; online visits and payment excluded; package only read | Pass |
| VI. Simple and Testable | No new dependencies; every FR maps to tests ([quickstart](quickstart.md)) | Pass |
| VII. Cost and Reliability | Booking requires connectivity (as stated); live slot reads are small (one doc per hour) | Pass |

**Post-design re-check**: Pass.

## Project Structure

### Documentation (this feature)

```text
specs/002-booking/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── callables.md
│   ├── firestore-access.md
│   └── routes.md
├── checklists/requirements.md
└── tasks.md             # /speckit-tasks
```

### Source Code (repository root)

```text
lib/features/booking/
├── data/               # settings, vaccines, slots, bookings, packages repositories; booking API (callables)
├── domain/             # hours of a day, availability, price preview, cancel-window rules (pure Dart)
├── application/        # booking form controller (selection, validation, submit/change)
└── presentation/       # booking_screen, booking_success_screen, my_bookings_screen, widgets

functions/src/
├── callables/          # createBooking, cancelBooking, changeBooking (+ deleteAccount extended)
└── lib/booking/        # time (Cairo), schedule rules, pricing, slot ids

functions/test/
├── functions/          # booking callables, race test
└── rules/              # booking rules

integration_test/       # booking end-to-end files
emulator-seed/          # + settings/booking, placeholder vaccines
```

**Structure Decision**: a `booking` feature folder in the existing app; booking rules shared between
server (authoritative) and app (display) are implemented on both sides with the same tests' cases.

## Complexity Tracking

No constitution violations to justify.
