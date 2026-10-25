# Research: Dashboard Completion

## R1. How a closed (merged) file disappears everywhere

- **Decision**: Closing a file clears `guardianPhone`, `guardianUid` and `nameKey`, and stores them with the target in `merged: {into, at, by, guardianPhone, guardianUid, name, birthDate}`.
- **Rationale**: Staff search (by number or `nameKey`), the duplicate checks (app and desk), the guardian's children query (`guardianUid ==`), linking (`guardianPhone ==` and `guardianUid == null`) and rules (`linkedGuardian`) all key on those fields, so the closed file drops out of every one without changing them.
- **Alternatives**: A `status: merged` flag would need a filter in every query and rule; deleting the file would lose the audit trail.

## R2. Moving records

- **Decision**: One Firestore transaction reads every measurement, dose and visit of the closed file with their `changes` and `staff/notes` subdocuments, writes them under the kept file with the same ids (a new id only on a clash), deletes the originals, and closes the file. Records keep `clinicId`, `recordedBy`, corrections and notes unchanged.
- **Rationale**: All or nothing (FR-006); a child file is far below the 500-write transaction limit. A merge with more than 400 writes is refused with `too_large` rather than half done.

## R3. Bookings

- **Decision**: Upcoming confirmed bookings of the closed child's guardian are read in the transaction; the closed `childId` is replaced by the kept one in `children[]` and `price.vaccines[]`. If a booking already lists the kept child, the merge is refused (`booked_together`).
- **Rationale**: A booking with the same child twice would need repricing; the desk can change or cancel it first. Past, done and cancelled bookings keep their history.

## R4. Duplicate check at the desk

- **Decision**: `registerFamily` runs the same query as `createChild` (`guardianPhone`, `nameKey`, `birthDate`) for every child inside one transaction, plus a check within the request itself; any hit creates nothing and returns `duplicates: [{index, childId, name}]`.
- **Rationale**: Same normalisation as the app (FR-022), so desk and app agree.

## R5. Staff link

- **Decision**: `staffLinkChildren({phone})` finds the guardian account on the number (`guardians` where `phone ==`), links every unlinked child on it, deletes `linkAttempts/{phone}`, clears `clinicChildrenPending`, and audits `children.linked_by_staff`.
- **Rationale**: Mirrors `linkClinicChildren`'s success path; identity is checked in person (FR-021a).
