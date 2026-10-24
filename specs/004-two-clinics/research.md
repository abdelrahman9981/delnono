# Research: Two Clinics (004)

Stack and testing as 001–003. This file records the decisions new to two clinics.

## R1. One document per clinic (FR-001 to FR-005)

**Decision**: `clinics/{clinicId}` holds the clinic's details, schedule and prices in one document:
name, area, address, phone, WhatsApp, active, order; capacity per hour, working hours, holidays,
vaccine weekdays, cancel window; visit price, package price and `vaccinePrices` (per vaccine:
offered, price, shown). Readable by anyone (Home is public, D-09); written only by staff in 005.
`settings/booking` keeps only the family-wide values: booking horizon and the upcoming maximum (D-49).

**Rationale**: every booking transaction reads exactly one clinic document, as 002 read one settings
document; one clinic stays below a few KB. Adding a third clinic is one more document.

**Alternatives considered**: a subcollection per clinic for prices (more reads per booking); prices on
the vaccine documents keyed by clinic (mixes the doctor's medical list with clinic prices).

## R2. Slots per clinic (FR-008)

**Decision**: slot id `{clinicId}_{date}_{HH}` with fields `clinicId`, `date`, `hour`, `taken`. The
transaction reads the clinic document and the slot, as 002 read the settings and the slot.

**Rationale**: capacity is per clinic and hour; the first confirmation still wins per document.

## R3. Family limits across clinics (FR-011, D-49)

**Decision**: unchanged mechanism: `familyQuota/{uid}` lists the family's active bookings whatever the
clinic; entries add `clinicId` for display only. Horizon and maximum come from `settings/booking`.

## R4. Vaccines and prices (FR-002, FR-007)

**Decision**: `vaccines/{id}` keeps the doctor's catalogue (name, kind, schedule fields, `active`).
A vaccine is bookable at a clinic when it is active and `clinics/{c}.vaccinePrices[id].offered` is
true; the price and "shown" come from the clinic. The 002 `price` and `showPrice` fields on
`vaccines` are removed in the seed; if found (old data) they are ignored.

## R5. Records carry their clinic (FR-016, FR-018)

**Decision**: bookings, visits, measurements, doses and packages (as `soldAtClinicId`) store
`clinicId`. Readers treat a missing `clinicId` as the main clinic: the active clinic with the lowest
`order` (`mainClinicId`), in the app and in Functions. The seed is regenerated with clinic ids
everywhere.

**Rationale**: the emulator seed is the only data so far; the fallback keeps any old record readable
without a migration job (which would need a deployed function, Blaze).

## R6. Choosing the clinic in the app (FR-006, FR-013)

**Decision**: the booking form holds `clinicId`; the first step lists active clinics (skipped with one).
Home's "احجزي هنا" opens `/booking?clinic=<id>`; the query parameter survives the sign-in flow through
001's `from` parameter. Changing a booking keeps its clinic.

## R7. Contact numbers

**Decision**: "كلمي العيادة" in My bookings uses the booking's clinic WhatsApp; Account's support
WhatsApp uses the main clinic's; the follow-up emergency card shows one call button per active clinic
with a phone. `settings/clinic` keeps no numbers any more (removed from the seed; the app no longer
reads them).
