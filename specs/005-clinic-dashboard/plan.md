# Implementation Plan: Clinic Dashboard

**Branch**: `005-clinic-dashboard` | **Date**: 2026-10-24 | **Spec**: [spec.md](spec.md)

## Summary

A Flutter Web dashboard as a second entry point of this project ([research R1](research.md#r1-a-second-flutter-entry-point-for-the-web)),
for staff with email accounts and role and clinic claims ([R2](research.md#r2-staff-accounts-and-claims-fr-001-to-fr-004)).
Every staff change goes through a callable that checks role and clinic and writes the audit log
([R3](research.md#r3-every-staff-write-is-a-callable-fr-027)); child files are opened through a callable
that logs the opening. Screens: Today (calendar, queue, walk-ins, payment, packages), child file,
clinic settings, vaccines, content and follow-up drafts, reports, settings, staff, audit log.

## Technical Context

**Language/Version**: as 001–004; Flutter Web for the dashboard

**Primary Dependencies**: as 004; no new packages (CSV built by hand, downloads through a data URL)

**Storage**: Cloud Firestore; model in [data-model.md](data-model.md)

**Testing**: Functions tests per callable, rules tests per row of contracts/firestore-access.md,
dashboard widget tests with a fake API; the guardian app's simulator tests once at the end. No browser
end-to-end runner is added (Principle VI); the dashboard is checked by widget tests and a manual pass
per quickstart.md.

**Target Platform**: desktop browsers (Chrome, Edge, Safari), tablets

**Project Type**: web dashboard plus Firebase backend in the same repository

**Constraints**: roles and clinic scope enforced on the server (Principle I); Arabic RTL, tokens;
callables need Blaze when deployed (D-40)

**Scale/Scope**: 3–5 staff; 2 clinics; 12 screens; ~17 callables

## Constitution Check

| Principle | Check | Status |
|-----------|-------|--------|
| I. Child Data Protection | Roles and clinic scope checked in callables and rules; child files opened only through a logging callable; notes doctor-only; audit of openings, medical, price and permission changes | Pass |
| II. Doctor-Owned Medical Content | Vaccine list, schedule, follow-up lists, danger signs and content published only by the doctor | Pass |
| III. Configurable, Not Hardcoded | Every clinic value and app setting editable here | Pass |
| IV. Arabic First | Arabic RTL, light and dark, same tokens | Pass |
| V. Phase Discipline | No online consultations or payments; push notifications are 007 | Pass |
| VI. Simple and Testable | Same project and stack; no new packages; tests per callable and rule | Pass |
| VII. Cost and Reliability | Runs on the emulators; Hosting later; no scheduled jobs | Pass |

**Post-design re-check**: Pass.

## Project Structure

```text
lib/dashboard/            # main.dart, app.dart, router, shell (nav), auth, api, screens/
lib/app/ (shared)         # theme, l10n
web/                      # web platform files
functions/src/callables/staff/   # the 005 callables
functions/src/lib/staff.ts       # staff guard (role, clinic, active)
functions/scripts/seed.ts        # staff accounts, sample bookings for today
test/dashboard/                  # dashboard widget tests
functions/test/functions/staff/  # callable tests
functions/test/rules/staff.test.ts
```

## Complexity Tracking

No constitution violations to justify.
