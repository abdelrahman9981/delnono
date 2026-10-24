# Contract: Cloud Functions (002)

Same conventions as [001](../../001-account-registration/contracts/callables.md): 2nd gen, region
from `functions/src/lib/region.ts`, caller signed in with a verified phone, guardian with current
consent (`requireGuardianWithCurrentConsent`). Errors are `HttpsError`; the app maps each to Arabic.

Selection used by create and change:

```text
selection: {
  visitType: "visit" | "vaccine_only",
  date: "YYYY-MM-DD", hour: 0..23,
  children: [{ childId, vaccines: [vaccineId] }]   // ≥ 1 child
}
```

## createBooking

```text
in:  selection + { expectedTotal }   // the total the app showed
out: { bookingId, number, price }
```

One transaction: settings, slot, counter, `familyQuota/{uid}`, package, vaccine prices. Writes the
booking, increments `slots/{date}_{hour}.taken`, the counter, the family quota and an event.

| Error | When |
|-------|------|
| `invalid-argument` | malformed selection; child not linked to the caller; unknown or inactive vaccine; vaccine-only without vaccines; `details.field` |
| `failed-precondition` | day closed, outside working hours, beyond the horizon, or the hour has started (`details.reason`: `closed`, `outside_hours`, `beyond_horizon`, `started`); vaccines on a non-vaccine day (`not_vaccine_day`) |
| `resource-exhausted` | the hour is full — "الميعاد اتحجز" (`details.reason: full`) |
| `already-exists` | the family already has an active booking that day (`details.bookingId`) |
| `out-of-range` | the family already holds `maxUpcomingPerFamily` upcoming bookings |
| `failed-precondition` (`reason: price_changed`) | the server total differs from `expectedTotal`; `details.price` is the new snapshot and nothing was written |

## cancelBooking

```text
in:  { bookingId }
out: {}
```

Owner only, `status == confirmed`, before the cancel window. Sets `cancelled`, decrements the slot,
removes the booking from `familyQuota/{uid}`, adds an event. Errors: `not-found` (not the caller's), `failed-precondition` (`details.reason`:
`not_confirmed`, `inside_window`).

## changeBooking

```text
in:  { bookingId, selection, expectedTotal }
out: { bookingId, number, price }
```

Owner only, `status == confirmed`, before the cancel window of the **current** time. Same checks as
create for the new selection (the booking's own day does not count against "one per day" or the
upcoming limit). Frees the old slot and takes the new one in one transaction; same slot → no count
change. Prices: kept lines keep amounts, new lines use current prices (research R4). Errors: those of
`cancelBooking` and `createBooking`.

## deleteAccount (001, extended)

Additionally cancels the guardian's upcoming confirmed bookings and frees their places in the same
transaction (research R9).
