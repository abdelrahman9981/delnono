# Contract: Cloud Functions (004 changes)

Builds on [002](../../002-booking/contracts/callables.md). Only the differences are listed.

## createBooking

```text
in:  selection + { clinicId, expectedTotal }
out: { bookingId, number, price }
```

Reads `clinics/{clinicId}` instead of the clinic fields of `settings/booking`, and `settings/booking`
for the horizon and the upcoming maximum. Slot `slots/{clinicId}_{date}_{HH}`. Vaccines must be active
and offered at the clinic; prices from the clinic. Writes `clinicId` on the booking, the slot and the
quota entry.

| Error | When |
|-------|------|
| `invalid-argument` (`field: clinicId`) | missing clinic id |
| `failed-precondition` (`reason: clinic_inactive`) | unknown or inactive clinic |
| `invalid-argument` (`field: vaccines`) | vaccine not offered at this clinic |
| others | as 002 |

## changeBooking

Selection without `clinicId`: the booking keeps its clinic (FR-010). Cancel window and schedule of
the booking's clinic.

## cancelBooking

The cancel window of the booking's clinic.

## deleteAccount

Frees each cancelled booking's slot at its own clinic.
