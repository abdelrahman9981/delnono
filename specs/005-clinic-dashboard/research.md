# Research: Clinic Dashboard (005)

Stack and testing as 001–004. Decisions new to the dashboard:

## R1. A second Flutter entry point for the web

**Decision**: the dashboard is `lib/dashboard/main.dart` in this project, built with
`flutter build web -t lib/dashboard/main.dart` (web platform added to the project). It shares the
theme (`lib/app/theme.dart`), Arabic strings (`l10n/app_ar.arb`) and data models with the guardian app.
Deploying to Firebase Hosting is a later step (docs/demo-plan.md).

**Rationale**: one codebase, one design system, one set of tests (constitution Principle VI); no new
framework. **Alternatives**: a separate web project (duplicated models and strings), React (a second
stack).

## R2. Staff accounts and claims (FR-001 to FR-004)

**Decision**: email-and-password Firebase accounts. Custom claims `{role: "doctor" | "secretary",
clinicId}` set only by the `manageStaff` callable (doctor only), with a `staff/{uid}` document
(name, email, role, clinicId, active, mustChangePassword). Disabling sets `active: false`, disables the
Auth user and revokes refresh tokens; rules and callables also check `staff/{uid}.active`, so access
ends at once. New staff get a temporary password and must change it at first sign-in. The first
doctor is created by the seed (emulator) or a setup script (real project).

## R3. Every staff write is a callable (FR-027)

**Decision**: staff never write Firestore directly. Callables check the caller's active staff record,
role and clinic, write the change and the audit entry in one transaction. Rules give staff read
access to their clinic's bookings, walk-ins, day status, package sales and content; child records
are read only through `openChildFile`, which writes the "child file opened" audit entry (D-13), so the
log cannot be skipped.

## R4. Queue, walk-ins and visits (FR-005 to FR-010)

**Decision**: booking statuses move forward (`confirmed → arrived → done`, `confirmed → no_show`)
with `arrivedAt`, `doneAt`, `statusBy`; the doctor can undo the last step the same day. Walk-ins are
`walkIns/{id}` documents in the clinic's hour slot (`slots/{clinic}_{date}_{HH}.taken` +1, refused when
full or when `days/{clinic}_{date}.walkInsStopped`). The queue is bookings and walk-ins with
`arrivedAt`, ordered by it. "Done" writes `children/{c}/visits/{bookingId or walkInId}` for each
registered child with the clinic (D-48).

## R5. Payments and packages (FR-011, FR-012)

**Decision**: payment is stored on the booking or walk-in: `payment {cash, covered, packageId,
recordedBy, recordedAt}`, default from the fixed price snapshot. `sellPackage` creates
`packages/{id}` with `soldAtClinicId`, `price` (the clinic's `packagePrice`), `startsOn` today,
`endsOn` after the clinic's `packageMonths` (12), `soldBy`.

## R6. Medical records and corrections (FR-013 to FR-017)

**Decision**: `saveMeasurement` and `saveDose` create records for any active staff member at their
clinic; updating an existing record is doctor-only and appends `changes/{id}` with old and new
values, who and when, plus an audit entry. `saveVisitNote` writes `visits/{v}/staff/notes` (doctor).
`updateChildBasics` edits name, allergies, birth date and sex; 001's `onChildUpdated` trigger keeps the
history.

## R7. Drafts and publishing (FR-021)

**Decision**: `content/{id}` with `status: draft | published | archived`; guardians read published
only (006 shows them). Follow-up lists and danger signs are edited as drafts in `followUpDrafts/{band}`
and `settings/followUpDraft`; `publishFollowUp` (doctor) copies drafts to the live `followUp` and
`settings/followUp` documents read by the app (003).

## R8. Reports (FR-022, FR-023)

**Decision**: a `report` callable counts per day or month in a range: bookings (created for that day,
not cancelled), arrivals, no-shows, walk-ins, cash (payments recorded), packages sold, per clinic or
all clinics (doctor). The dashboard renders the table and builds the CSV in the browser from the
numbers only. Computing on the server keeps the clinic check in one place.

## R9. Layout

**Decision**: a side navigation rail (desktop) that becomes a drawer below 900 px; content max width
1200 px; tables become cards on narrow screens. Same tokens and light/dark as the app.
