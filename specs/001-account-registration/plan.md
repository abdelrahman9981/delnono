# Implementation Plan: Account and Registration

**Branch**: `001-account-registration` | **Date**: 2026-10-22 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-account-registration/spec.md`

**Design**: [docs/design/README.md](../../docs/design/README.md) is the visual source of truth.
This feature builds screens 1–7 and 11:

| # | Screen | Mockup | Route ([routes](contracts/routes.md)) |
|---|--------|--------|--------|
| 1 | Welcome (browse without login) | `docs/design/screens/Main.dc.html` | `/welcome` |
| 2 | Mobile number | `docs/design/screens/Phone.dc.html` | `/sign-in` |
| 3 | OTP code | `docs/design/screens/Otp.dc.html` | `/sign-in/code` |
| 4 | Guardian details | `docs/design/screens/Guardian.dc.html` | `/register/guardian` |
| 5 | Privacy consent | `docs/design/screens/Consent.dc.html` | `/register/consent` |
| 6 | Add child | `docs/design/screens/AddChild.dc.html` | `/register/child`, `/children/add` |
| 7 | Link clinic-registered children | `docs/design/screens/LinkChildren.dc.html` | `/register/link` |
| 11 | Account | `docs/design/screens/Account.dc.html` | `/account` |

Colours, radii and components come from `docs/design/tokens.css` (light and dark). Text sizes
follow the BRD scale in the design README, not the Figma prototype's 7–9 px labels. Home, booking
and child profile (Figma) belong to 002 and 003; 001 shows placeholders for them.

## Summary

Guardians sign in with an Egyptian mobile number and SMS code, register with explicit consent,
add children or link children the clinic already registered (after a birth-date check), edit
child name and allergies, change number and delete their account. The mobile app is Flutter with
Riverpod and go_router; Firebase Auth handles phone sign-in, Firestore stores data behind tested
Security Rules, and Cloud Functions do everything the client must not do itself (linking, duplicate
check, registration with consent, deletion, audit log). Firebase cannot enforce the exact code
rules (FR-006 to FR-008) on the server; the app enforces them, and the daily cap (FR-009) is
enforced by a `beforeSmsSent` blocking function after the Blaze and Identity Platform upgrade
([research R1](research.md#r1-what-firebase-phone-auth-lets-us-control-fr-006-to-fr-009)).

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47 stable (app); TypeScript 5 on Node.js 22 (Cloud
Functions and tests)

**Primary Dependencies**: flutter_localizations, intl, flutter_riverpod, go_router, firebase_core,
firebase_auth, cloud_firestore, cloud_functions, url_launcher; firebase-functions (2nd gen), firebase-admin.
Reasons in [research R5](research.md#r5-flutter-stack-and-dependencies).

**Storage**: Cloud Firestore with offline persistence; model in [data-model.md](data-model.md)

**Testing**: flutter_test + mocktail (unit, widget), integration_test against the emulators;
Mocha with @firebase/rules-unit-testing and direct calls to the Functions emulator ([research R6](research.md#r6-testing-approach))

**Target Platform**: Android 8+ and iOS 15+ (D-22)

**Project Type**: mobile app plus serverless backend (Firebase)

**Performance Goals**: core screens open within 3 s on 4G (D-22); registration end to end under
3 minutes (SC-001); callables answer within 2 s p95

**Constraints**: Arabic only, RTL; development on Spark with emulator and test phone numbers; real
SMS, deployed functions and blocking functions need Blaze (+ Identity Platform for blocking);
nothing stored before consent; no secrets in the repository

**Scale/Scope**: 1,000 active guardians, 100 concurrent users at launch (D-22); about 15 screens

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Check | Status |
|-----------|-------|--------|
| I. Child Data Protection | Least privilege per role in rules ([firestore-access](contracts/firestore-access.md)); rules tested in the emulator before done; audit log for linking, phone change, deletion ([R7](research.md#r7-audit-log-scope)); consent recorded before any child data (FR-015); lawyer review still required before launch and for data location ([R8](research.md#r8-data-location)) | Pass (lawyer review is a launch gate, not a plan gate) |
| II. Doctor-Owned Medical Content | No medical content in 001; policy and terms text are clinic-supplied, placeholder until then | Pass |
| III. Configurable, Not Hardcoded | Code validity, attempts, resend wait, daily cap, link attempts and policy version in `settings/auth` and `settings/policy` | Pass |
| IV. Arabic First | Arabic-only localisation, RTL, bundled Readex Pro, light and dark themes from requirements.md colours | Pass |
| V. Phase Discipline | Only Phase 1 scope; "Ask" tab is an empty reserved slot with no route ([routes](contracts/routes.md)) | Pass |
| VI. Simple and Testable | Every dependency has a stated reason; one Node project for functions and rules tests; acceptance scenarios map to tests ([quickstart](quickstart.md)) | Pass |
| VII. Cost and Reliability | Spark + emulator + test numbers in development; persistent sessions; resend timer; daily cap and Egypt-only SMS region at the Blaze upgrade; offline persistence on | Pass, with one owner decision: Identity Platform upgrade ([R1](research.md#r1-what-firebase-phone-auth-lets-us-control-fr-006-to-fr-009)) |

**Post-design re-check**: Pass. Design adds no new services beyond the constitution's stack;
Identity Platform is an upgrade of Firebase Authentication, not a new provider.

## Project Structure

### Documentation (this feature)

```text
specs/001-account-registration/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   ├── callables.md
│   ├── firestore-access.md
│   └── routes.md
├── checklists/requirements.md
└── tasks.md             # created by /speckit-tasks
```

### Source Code (repository root)

```text
lib/
├── main.dart
├── app/                     # MaterialApp, theme (light/dark), Arabic l10n, router + guard
├── core/                    # Firebase init (emulator switch), settings providers, phone validation
└── features/
    ├── auth/                # phone entry, code entry, countdown, attempt counting
    ├── registration/        # guardian details, consent, link check, first child
    ├── children/            # list, add, profile edit
    ├── account/             # phone change, sign out, delete
    └── shell/               # bottom navigation with reserved "Ask" slot, placeholders
assets/fonts/                # Readex Pro
l10n/                        # app_ar.arb

test/                        # unit and widget tests mirroring lib/
integration_test/            # end-to-end flows against the emulators

functions/
├── src/
│   ├── callables/           # completeRegistration, acceptPolicy, linkClinicChildren,
│   │                        # createChild, syncPhoneNumber, deleteAccount
│   ├── triggers/            # onChildUpdated, beforeSmsSent
│   └── lib/                 # audit, settings, validation, nameKey
└── test/
    ├── rules/               # Security Rules tests
    └── functions/           # callable and trigger tests

firestore.rules
firestore.indexes.json
firebase.json                # emulator config
emulator-seed/               # settings and clinic test data
```

**Structure Decision**: the existing Flutter project at the repository root holds the app, with
feature folders under `lib/features/`. One `functions/` Node project holds the Cloud Functions and
both test suites. The dashboard (004) is not part of this plan.

## Complexity Tracking

No constitution violations to justify.
