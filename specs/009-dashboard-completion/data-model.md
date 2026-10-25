# Data Model: Dashboard Completion

## children/{childId} (existing; new fields)

| Field | Type | Notes |
|---|---|---|
| registeredBy | `guardian` \| `staff` | `staff` for desk registrations (existing field, new value) |
| registeredAt | string? | clinic id of the desk registration |
| registeredByUid | string? | staff uid |
| merged | map? | set when closed: `{into, at, by, guardianPhone, guardianUid, name, birthDate}`; on close `guardianPhone`, `guardianUid` and `nameKey` become null |

Validation as `validateChild` (001 FR-018): name 2–60, birth date not in the future and within the app's age limit, sex `male`/`female`, birth weight 0.3–7.0 kg, allergies ≤ 500.

## Moved on merge

`children/{closed}/{measurements|doses|visits}/{id}` and their `changes/*` and `staff/notes` → same paths under `children/{kept}`.

## bookings/{id} (existing)

Upcoming `confirmed` bookings: `children[].childId` and `price.vaccines[].childId` repointed from closed to kept.

## auditLog (existing)

New actions: `family.registered` (childIds, subjectPhone, clinicId), `children.merged` (kept, closed, closed name and birth date, counts), `children.linked_by_staff` (childIds, subjectPhone).
