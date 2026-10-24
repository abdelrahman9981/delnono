# Data Model: Child Profile and Vaccines (003)

Firestore and Cloud Storage. Dates are `YYYY-MM-DD` in Cairo time. Guardians only read; every write
below is made by staff in feature 004 (or by the seed script in development). Existing documents from
001 (`children/{id}`) and 002 (`vaccines/{id}`, `packages/{id}`, `settings/clinic`) are extended, not
replaced.

## children/{childId}/measurements/{measurementId}

| Field | Type | Rules |
|-------|------|-------|
| measuredOn | string date | not after today, not before birth date |
| weightKg | number? | 0.3–50, one decimal shown |
| lengthCm | number? | 20–150 |
| headCm | number? | 20–70 |
| visitId | string? | the visit it was taken at |
| recordedBy | string | staff uid |
| recordedAt | timestamp | |

At least one of the three values is present. Corrections (doctor only, 004) overwrite the values and add
a staff-only entry under `measurements/{id}/changes/{c}`; the guardian sees only current values.
"Latest" for each value = the measurement with the latest `measuredOn` that has that value.

## children/{childId}/doses/{doseId}

| Field | Type | Rules |
|-------|------|-------|
| scheduleId | string? | `vaccineSchedule` entry, for basic doses |
| vaccineId | string | `vaccines/{id}` |
| dose | number | 1-based dose number (additional vaccines) |
| givenOn | string date | |
| lot | string? | lot number if recorded |
| visitId | string? | |
| recordedBy, recordedAt | string, timestamp | |

## children/{childId}/visits/{visitId}

| Field | Type | Rules |
|-------|------|-------|
| date | string date | |
| type | `clinic` \| `vaccine` \| `walkIn` | |
| bookingId | string? | 002 booking, if any |
| prescriptions | list of `{path, page}` | Storage paths, pages in order; may be empty |
| createdAt | timestamp | |

The doctor's notes are in `visits/{visitId}/staff/notes` (004), denied to guardians.
Measurements and doses of a visit are found by their `visitId`.

## vaccineSchedule/{entryId} (basic schedule)

| Field | Type | Rules |
|-------|------|-------|
| vaccineId | string | `vaccines/{id}` with `kind: basic` |
| dose | number | |
| dueAge | `{months, days}` | due date = birth date + months (calendar, clamped) + days |
| lastAge | `{months, days}`? | after this age a dose not given is "missed" |
| ageLabel | string | heading such as "عند الولادة", "الشهر الثاني" |
| order | number | |
| placeholder | boolean | true until the doctor approves (D-36) |

## vaccines/{vaccineId} (002, extended)

The spec's "extra" vaccines ("إضافي") are `kind: additional`, the 002 term. Adds for `kind: additional`: `suggestedAge {months, days}`, `doses` (number), `intervalWeeks` (number),
`note` (string). Basic vaccines may also have a `note`. `price`/`showPrice` as in 002 (FR-043: price shown
only when `showPrice`).

## settings/vaccines

| Field | Type | Default (placeholder) |
|-------|------|-----------------------|
| source | string | "[جدول وزارة الصحة المصرية · يراجعه الدكتور]" |
| reviewedOn | string date | seed date |
| lateAfterDays | number | 7 |
| placeholder | boolean | true |

## followUp/{bandId}

| Field | Type | Rules |
|-------|------|-------|
| fromMonths, toMonths | number | band covers fromMonths ≤ age < toMonths |
| title | string | e.g. "متابعة الشهر التاسع" |
| items | list of string | placeholder items in brackets |
| order | number | |
| placeholder | boolean | |

## settings/followUp

| Field | Type | Default |
|-------|------|---------|
| maxAgeMonths | number | 48 |
| dangerSigns | list of string | placeholders in brackets |
| placeholder | boolean | true |

## settings/clinic (001, extended)

Adds `phoneNumber` (E.164, placeholder) for the "اتصلي بالعيادة" button. The 123 number is fixed.

## Cloud Storage: prescriptions/{childId}/{visitId}/{fileName}

JPEG or PNG, up to 10 MB, uploaded by the doctor in 004. Read rules in
[contracts/storage-access.md](contracts/storage-access.md).

## App-side derived values (not stored)

- **Dose state**: given / scheduled / due / late / missed ([research R3](research.md#r3-dose-states-fr-008-sc-002)).
- **Age band**: months since birth date; follow-up shown when age < `maxAgeMonths`.
- **Package state**: active when `active` and today within `startsOn`..`endsOn`; months left rounded down.
