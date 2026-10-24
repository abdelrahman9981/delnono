<!--
Sync Impact Report
- Version change: 1.1.2 → 1.2.0 (MINOR: Phase 1 scope narrowed; Cloud Storage moved to Phase 2)
- Source: docs/BRD.md D-39 (24 October 2026), which modifies D-30 and D-38; requested by the owner
- Modified principles:
  - VII. Cost and Reliability: Cloud Storage (prescription photos) is Phase 2; Blaze before the
    closed test is required for SMS OTP and Cloud Functions only
- Modified sections:
  - Additional Constraints > Stack: Cloud Storage marked Phase 2
  - Additional Constraints > Roles: prescription photo upload marked Phase 2
- Follow-up: specs/003-child-profile updated (visit history without prescription photos)

- Version change: 1.0.0 → 1.1.0 (MINOR: materially expanded guidance; no principle removed or redefined)
- Source: docs/BRD.md section 17 (D-27..D-38), which overrides conflicting text in sections 1–16
- Modified principles:
  - II. Doctor-Owned Medical Content: added ban on automatic medical judgments (D-37)
  - V. Phase Discipline: Phase 1 reserves layout space for the Phase 2 "Ask" tab (requirements.md)
  - VII. Cost and Reliability: added Cloud Storage and Cloud Functions; Blaze required before the
    closed test for SMS OTP, Storage and Functions; Firebase test phone numbers in development (D-38)
- Modified sections:
  - Additional Constraints > Stack: added Cloud Storage and Cloud Functions (D-38)
  - Additional Constraints > Roles: Secretary records measurements and vaccine doses; Doctor-only
    corrections with change log, prescriptions (photo upload) and medical notes (D-29, D-30)
  - Additional Constraints > Booking: new bullet, app-only hour slots with capacity (D-27, D-28)
  - Additional Constraints > Target: closed test scope (D-35)
- Added sections: none
- Removed sections: none
- Follow-up TODOs: none

- Version change: 1.1.0 → 1.1.1 (PATCH: feature order only)
- Modified sections:
  - Development Workflow: feature specs reordered to put the closed test scope first (D-35):
    001 account and registration, 002 booking (including visit and vaccine prices),
    003 child profile and vaccines, 004 clinic dashboard, 005 content library, 006 packages,
    007 notifications. Was: 004 content library, 005 packages and pricing, 006 clinic dashboard.

- Version change: 1.1.1 → 1.1.2 (PATCH: clarification, matches BRD D-13)
- Modified principles:
  - I. Child Data Protection: audit of access to child records scoped to staff access; guardian
    reads of their own children are not logged. Change audit unchanged. Raised by /speckit-analyze
    on 001 (finding C1), approved by the owner.
-->

# Dr. El Nono Constitution

## Core Principles

### I. Child Data Protection (NON-NEGOTIABLE)
Child health data is sensitive. Access MUST follow least privilege per role (doctor, secretary, guardian). Firestore Security Rules MUST be written and tested with the Firebase emulator before any feature that reads or writes data ships. Staff (doctor, secretary) access to child records and any change to prices, roles or medical data MUST be written to an audit log; a guardian reading their own children's records is not logged. A guardian's consent MUST be recorded before any child data is stored. Compliance with Egypt Law 151/2020 MUST be reviewed by a lawyer before launch.

### II. Doctor-Owned Medical Content
Medical content is never invented by the app or the developers. Danger signs, vaccine schedules, growth guidance and all clinical text MUST come from data the doctor approves and can edit from the dashboard. Any sample medical text in code or mockups MUST be clearly marked as placeholder. The app MUST NOT show automatic medical judgments (e.g. "normal", "on track"); show values and charts only.

### III. Configurable, Not Hardcoded
Anything that can change MUST be a setting editable from the dashboard, not a constant in code: visit price, packages, vaccine days and prices, cancellation window, slot capacity per hour, danger-sign list, notification texts. A price change MUST NOT affect bookings already confirmed.

### IV. Arabic First
All user-facing text is Arabic with full RTL layout, Arabic error messages, the Readex Pro or Cairo font, and light and dark mode. Code, specs and commit messages are in English.

### V. Phase Discipline
Phase 1 covers clinic visits, cash payment, registration, booking, child profile and vaccines, content library, packages and pricing, notifications, and the web dashboard. Online consultation ("Ask the Doctor"), video visits and electronic payment are Phase 2 and MUST NOT be built or designed in Phase 1. The one exception: Phase 1 layout reserves space for the Phase 2 "Ask" tab in the bottom navigation, with no screens or logic behind it.

### VI. Simple and Testable
Every feature has written acceptance criteria and automated tests. Prefer the platform and Firebase features over extra libraries. A new dependency requires a stated reason in the plan.

### VII. Cost and Reliability
The backend is Firebase (Auth, Firestore, Cloud Messaging, Cloud Functions, Hosting; Cloud Storage in Phase 2). Development runs on the Spark plan using Firebase test phone numbers. The project MUST upgrade to Blaze before the closed test, because SMS OTP and Cloud Functions (scheduled reminders) require it (Cloud Storage for prescription photos follows in Phase 2, D-39); budget alerts are enabled from day one. SMS OTP sends MUST be minimized (persistent sessions). Booking requires connectivity; child profile and loaded content are readable offline.

## Additional Constraints

- **Stack:** Flutter for Android and iOS; Firebase Authentication (phone OTP); Cloud Firestore; Firebase Cloud Messaging; Cloud Storage for prescription photos; Cloud Functions for scheduled reminders; web dashboard on Firebase Hosting; Cloud Storage for prescription photos in Phase 2 (D-39).
- **Roles:** Doctor: everything; the only role that corrects measurements and vaccine doses after they are saved (every correction recorded in a change log), uploads prescriptions (a photo of the paper prescription, from the dashboard; Phase 2, D-39) and writes medical notes. Secretary: appointments, queue, payments, prices, packages, vaccine days, basic child data (name, age, guardian phone), and recording measurements (weight, length, head circumference) and vaccine doses (date, lot number); no edits after saving, no medical notes or prescriptions. Guardian: own children only, read-only medical record.
- **Booking:** app-only; phone and WhatsApp are for contact and support, not booking. Guardians book an hour slot with a configurable capacity; entry within the hour is by arrival order. Walk-ins added by the secretary continue.
- **Source of requirements:** `docs/BRD.md` (requirements FR-xx, decisions D-xx). If a spec conflicts with the BRD, the BRD wins until it is formally amended.
- **Secrets:** no keys, tokens or service accounts in the repository.
- **Target:** closed test build on 1 November 2026 (registration, booking, child profile, dashboard); public release afterwards.

## Development Workflow

- One spec per feature, in this order, closed test scope first (D-35): 001 account and registration, 002 booking (including visit and vaccine prices), 003 child profile and vaccines, 004 clinic dashboard, 005 content library, 006 packages, 007 notifications.
- Each feature follows: specify, clarify, plan, tasks, analyze, implement.
- Security Rules tests pass before a feature is considered done.
- Every plan includes a Constitution Check against the principles above.

## Governance

This constitution overrides other practices for this project. Amendments are agreed by the clinic owner (the doctor) and the lead developer, documented with a version bump (semantic versioning), and any dependent specs and plans are updated.

**Version**: 1.2.0 | **Ratified**: 2026-10-19 | **Last Amended**: 2026-10-24
