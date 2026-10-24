# Data Model: Clinic Dashboard (005)

Builds on 001–004. Written only by callables; staff read as in contracts/firestore-access.md.

## staff/{uid}

| Field | Type | Rules |
|-------|------|-------|
| name, email | string | |
| role | `doctor` \| `secretary` | also a custom claim |
| clinicId | string? | required for a secretary; also a claim |
| active | boolean | false = no access |
| mustChangePassword | boolean | set on create; cleared after the first password change |
| createdAt, updatedAt, updatedBy | | |

## bookings/{id} (002, extended)

`status` adds the staff steps; `arrivedAt`, `doneAt`, `statusBy`; `payment {cash, covered, packageId,
recordedBy, recordedAt}`.

## walkIns/{id}

`clinicId`, `date`, `hour`, `familyName`, `phone`, `children [{childId?, name}]`, `visitType`,
`status: arrived | done`, `arrivedAt`, `doneAt`, `payment`, `createdBy`.

## days/{clinicId}_{date}

`walkInsStopped: bool`, `by`, `at`.

## packages/{id} (004, completed)

`guardianUid`, `soldAtClinicId`, `price`, `startsOn`, `endsOn`, `active`, `soldBy`, `soldAt`.

## clinics/{id} (004, extended)

Adds `packageMonths` (12).

## children/{c}/visits/{v} (003)

Id = booking or walk-in id; `clinicId`, `date`, `type`, `bookingId`/`walkInId`. Doctor note in
`staff/notes {text, by, at}`.

## children/{c}/measurements|doses/{id}/changes/{x}

`from`, `to` (changed fields), `by`, `at`.

## content/{id}

`title`, `category` (fever, feeding, sleep, allergy), `ageFromMonths`, `ageToMonths`, `url`, `status`,
`createdBy`, `publishedBy`, `updatedAt`.

## followUpDrafts/{bandId}, settings/followUpDraft

Same shape as `followUp/{bandId}` and `settings/followUp`; published by the doctor.

## auditLog/{id} (001)

New actions: `staff.created`, `staff.updated`, `child.opened`, `medical.corrected`, `note.saved`,
`clinic.updated` (prices and schedule), `catalogue.updated`, `settings.updated`, `content.published`,
`status.undone`.
