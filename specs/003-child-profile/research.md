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

## R4. Prescription photos (FR-014, FR-015, FR-022)

**Decision**: Cloud Storage at `prescriptions/{childId}/{visitId}/{fileName}`, listed on the visit as
`prescriptions: [{path, page}]`. `storage.rules` allow read when the caller is the child's linked active
guardian (cross-service `firestore.get` of the child and guardian documents, same checks as
`linkedGuardian`) or has the custom claim `role == 'doctor'` (staff claims arrive in 004); never the
secretary; writes are denied until 004. The app downloads bytes with the SDK (`getData`), which applies
the rules, and keeps them in an app cache folder so opened photos stay readable offline. The cache is
deleted on sign-out together with the Firestore cache. Local development uses the Storage emulator
(port 9199). Deploying Storage is **blocked: Blaze** (D-38).

**Rationale**: download URLs carry a bearer token that bypasses the rules and could be forwarded; SDK
reads are checked every time. Bytes in the app's own cache folder meet the offline requirement without a
caching library.

**Alternatives considered**: download URLs plus an image-cache package (URL works for anyone who has it);
storing photos in Firestore (1 MB limit, cost).

**New dependencies** (constitution Principle VI): `firebase_storage` (the Storage SDK, required by D-30)
and `path_provider` (Flutter team package to find the app's cache folder). Versions resolved with the
current FlutterFire set: firebase_storage 14.0.1, path_provider 2.1.6.

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
`metadata.isFromCache` is true and the device has no connection. Photos come from the app cache (R4).

## R8. Selected child

**Decision**: the last selected child id is kept on the device (a small value in the app's preferences
folder through a JSON file next to the photo cache, read at start); if that child is no longer linked,
the first child is used.

**Rationale**: avoids another dependency (shared_preferences) for one value.
