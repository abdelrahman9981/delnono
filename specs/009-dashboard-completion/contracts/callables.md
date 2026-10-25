# Callables: Dashboard Completion

All require an active staff account (`requireStaff`); errors use `HttpsError` with `details.reason` as in 005.

## registerFamily

Request: `{ clinicId, phone, children: [{ name, birthDate, sex, birthWeightKg?, allergies? }] }` (1–6 children).
- `clinicId` must be the caller's clinic (secretary) or any clinic (doctor) — `requireClinic`.
- `phone`: 01xxxxxxxxx, +201xxxxxxxxx or 201xxxxxxxxx; else `invalid-argument` `{field: "phone"}`.
- Each child validated (`invalid-argument` `{field, index}`).
- Duplicate (existing open file, or twice in the request): `already-exists` `{reason: "duplicate", duplicates: [{index, childId, name}]}`; nothing created.

Response: `{ childIds: string[] }`. Audit `family.registered`.

## mergeChildren

Request: `{ keepId, closeId }`. Doctor only (`permission-denied` `{reason: "doctor_only"}`).
- Both open, different, same `guardianPhone`; else `failed-precondition` `{reason: "same_file" | "other_number" | "closed"}`.
- An upcoming booking lists both: `failed-precondition` `{reason: "booked_together"}`.
- More than 400 writes: `failed-precondition` `{reason: "too_large"}`.

Response: `{ moved: {measurements, doses, visits, bookings} }`. Audit `children.merged`.

## staffLinkChildren

Request: `{ childId }` (any unlinked open child on the number).
- No guardian account on the number: `failed-precondition` `{reason: "no_account"}`.
- Child already linked: `failed-precondition` `{reason: "already_linked"}`.

Response: `{ linked: [{childId, name}] }`. Clears `linkAttempts/{phone}` and `clinicChildrenPending`. Audit `children.linked_by_staff`.

## openChildFile (changed)

A closed file returns `{ merged: { into, name } }` and nothing else. An open, unlinked child also gets `accountOnNumber: boolean` (a guardian account exists on its number), so the dashboard offers the staff link only when it can work.

## searchChildren (unchanged)

Closed files have no number or name key, so they are never returned.
