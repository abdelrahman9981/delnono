# Research: Child Profile and Vaccines (003)

The stack, testing approach and Functions setup are those of 001 and 002 ([001 research](../001-account-registration/research.md),
[002 research](../002-booking/research.md)). This file records only the decisions new to 003.

## R1. Where medical records live (FR-013, FR-021)

**Decision**: subcollections of the child document: `children/{id}/measurements`, `children/{id}/doses`,
`children/{id}/visits`. The doctor's notes for a visit live in a separate staff-only document
(`children/{id}/visits/{v}/staff/notes`, created in 004), never in the visit document the guardian reads.

**Rationale**: the rules check one parent document (`linkedGuardian(child)`, 001) for every record, so a
child's records follow the child when it is linked or unlinked, with no copying. Firestore rules cannot
hide single fields, so notes must be a separate document (clarification Q1).

**Alternatives considered**: top-level collections with `childId` and `guardianUid` copies (must be
rewritten on every link, unlink or number change); notes as a field (would be readable by the guardian).

## R2. Vaccine schedule data (FR-006 to FR-012)

**Decision**: the 002 `vaccines/{id}` list stays the catalogue (name, price, `kind: basic | additional`).
Basic doses are `vaccineSchedule/{entryId}` documents: `vaccineId`, `dose`, `dueAge {months, days}`,
optional `lastAge {months, days}`, `order`, `ageLabel`. Additional vaccines carry their own fields on
`vaccines/{id}` (`suggestedAge`, `doses`, `intervalWeeks`, `note`). `settings/vaccines` holds `source`,
`reviewedOn` and `lateAfterDays` (7). All seeded with `placeholder: true` and names in brackets.

**Rationale**: one catalogue is shared by booking (002) and the schedule; due dates come from the birth
date, so the schedule is the same for every child and never copied per child (constitution Principle III:
the doctor edits it once in 004).

**Alternatives considered**: a per-child dose plan written at registration (stale when the doctor edits
the schedule; needs a function); hardcoded MOH schedule (Principle II).

## R3. Dose states (FR-008, SC-002)

**Decision**: computed in the app (pure Dart, `domain/dose_state.dart`) from the schedule entry, the
child's birth date, the dose records and today in Cairo time:

1. A dose record exists for the entry → **given**.
2. Else today < due date → **scheduled**.
3. Else if `lastAge` is set and today > birth date + `lastAge` → **missed**.
4. Else today > due date + `lateAfterDays` → **late**.
5. Else → **due**.

Due date = birth date + `dueAge.months` calendar months (clamped to the month's last day) + `dueAge.days`.
Additional vaccines are **given** or have no state (clarified in spec FR-010).

**Rationale**: states change with the date alone, so storing them would need a daily job (Blaze).
Display-only; nothing on the server depends on them. Reminders (007) use the same rules on the server.

## R4. Prescription photos (moved to Phase 2)

**Decision (2026-10-24)**: prescription photos and Cloud Storage move to Phase 2 (BRD D-39, constitution
1.2.0). 003 shows the visit history without photos; the `visits` documents carry no `prescriptions` field
yet, and no Storage rules, emulator or SDK are part of the app.

**Kept for Phase 2** (designed and tested before the scope change, then removed): photos at
`prescriptions/{childId}/{visitId}/{file}`; Storage rules mirroring `linkedGuardian` with cross-service
`firestore.get`, plus the doctor's `role` claim and never the secretary; reads through the SDK (`getData`),
never download URLs, cached among the app's private files for offline reading and deleted on sign-out.

## R5. Growth chart (FR-004)

**Decision**: a small `CustomPainter` line chart: x = age (months), y = value with nice round ticks,
points for each measurement, area fill as in the design; tabs switch weight, length and head. No
reference curves, ranges, colors meaning good or bad, or percentile text (D-37).

**Rationale**: one simple chart does not justify a charting dependency (Principle VI) and keeps full
control over what is drawn, so nothing can imply a judgment.

**Alternatives considered**: fl_chart (new dependency, features not needed).

## R6. Follow-up and danger signs (FR-016 to FR-019)

**Decision**: `followUp/{bandId}` documents (`fromMonths`, `toMonths`, `title`, `items[]`, `order`) and
`settings/followUp` (`dangerSigns[]`, `maxAgeMonths: 48`, `note`). The clinic number for the call button is
`settings/clinic.phoneNumber` (new field, placeholder). Buttons open `tel:` links with url_launcher.

**Rationale**: all text is doctor-owned and editable in 004 (Principle II); the age limit is a setting.

## R7. Offline (FR-022, US6)

**Decision**: Firestore offline persistence (already on since 001) serves every screen from the cache;
streams use the cached snapshot first and show "إنتي أوفلاين · دي آخر بيانات اتحملت" when
`metadata.isFromCache` is true and the device has no connection.

## R8. Selected child

**Decision**: the last selected child id is kept on the device in a one-line file among the app's private
files (the app support folder, found with `path_provider`, deleted on sign-out); if that child is no longer
linked, the first child is used.

**Rationale**: `path_provider` (Flutter team) is the one new dependency (constitution Principle VI); it
avoids shared_preferences for one value and gives a folder the OS does not purge. Version 2.1.6.
