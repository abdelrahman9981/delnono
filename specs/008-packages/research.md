# Research: Packages

## R1. Renewal dates
- **Decision**: `startsOn = endsOn(current) + 1 day`, `endsOn = addMonths(startsOn, months)`; allowed when `endsOn(current) - today ≤ 14 days` and no active package starts after today. Night-run assumption (spec Clarifications).
- **Rationale**: No paid days lost; coverage lookups are by date, so the renewal covers bookings after the current end with no other change.

## R2. Family view
- **Decision**: A pure function returns `current` (covers today), `next` (starts after today), `lastEnded`; «حسابي», the page and the reminder all use it.

## R3. Expiry reminder
- **Decision**: 007's planner gets the family's packages; key `package:{id}:14d`, 09:00 Cairo 14 days before `endsOn`, skipped when `next` exists; scheduled under the booking switch; route `/package`.

## R4. Prices on the page
- **Decision**: `Clinic` gains `packagePrice` and `packageMonths` from the public clinic document (already written by `updateClinic`).
