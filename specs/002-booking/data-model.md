# Data Model: Booking (002)

Firestore. Dates and hours are Cairo time. "Server only" = written only by Cloud Functions.

## settings/booking

Readable by signed-in guardians; written by the doctor in 004. Seeded with `placeholder: true`.

| Field | Type | Default (placeholder) |
|-------|------|-----------------------|
| capacityPerHour | number | 6 |
| workingHours | map weekday → list of `{from, to}` hours (0–24) | Sat–Thu 17–21, Fri closed |
| holidays | list of `YYYY-MM-DD` | [] |
| vaccineWeekdays | list of weekday numbers (1 = Monday … 7 = Sunday) | [1, 3] |
| visitPrice | number (EGP) | 300 |
| cancelWindowHours | number | 3 |
| bookingHorizonDays | number | 14 |
| maxUpcomingPerFamily | number | 2 |
| placeholder | boolean | true |

## vaccines/{vaccineId}

Readable by signed-in guardians; written by the doctor in 004 (schedule logic in 003).

| Field | Type | Rules |
|-------|------|-------|
| name | string | placeholder names in brackets until the doctor's list arrives |
| price | number (EGP) | ≥ 0 |
| showPrice | boolean | false → shown as "بالسعر في العيادة" |
| kind | `basic` \| `additional` | |
| active | boolean | inactive vaccines are not offered |
| placeholder | boolean | |

## slots/{YYYY-MM-DD}_{HH}

Server only for writes; readable by signed-in guardians (counts only).

| Field | Type | Rules |
|-------|------|-------|
| date | string | `YYYY-MM-DD` |
| hour | number | 0–23 |
| taken | number | 0 ≤ taken; never above capacity at booking time (walk-ins in 004 follow the same counter) |

## bookings/{bookingId}

Server only for writes; readable by the owning guardian with current consent and recent activity (001).

| Field | Type | Rules |
|-------|------|-------|
| number | number | from `counters/bookings`, unique |
| guardianUid | string | owner |
| guardianPhone | string | for the clinic desk (004) |
| visitType | `visit` \| `vaccine_only` | |
| children | list `{childId, name, vaccines: [vaccineId]}` | ≥ 1 child, all linked to the guardian; `vaccine_only` needs ≥ 1 vaccine overall |
| date | string | `YYYY-MM-DD` |
| hour | number | 0–23 |
| startsAt | timestamp | hour start, Cairo |
| status | `confirmed` \| `arrived` \| `done` \| `cancelled` \| `no_show` | guardians can only cancel |
| price | map | see below |
| createdAt, updatedAt | timestamp | |
| cancelledAt, cancelledBy | timestamp?, string? | |

`price`:

| Field | Type |
|-------|------|
| visit | `{amount: number, covered: boolean}` or null for `vaccine_only` |
| vaccines | list `{childId, vaccineId, name, amount: number \| null}` (null = hidden price) |
| total | number (sum of known amounts) |
| hasHiddenPrices | boolean |
| packageId | string? |

### bookings/{bookingId}/events/{eventId}

Server only; readable with the booking. `type` (`created`, `changed`, `cancelled`), `by` (uid), `at`,
`from?` and `to?` (`{date, hour}` for changes).

## counters/bookings

Server only. `next` (number).

## packages/{packageId} (owned by 006)

Read here only. `guardianUid`, `startsOn`, `endsOn` (`YYYY-MM-DD`), `active`. The owning guardian may read.

## State transitions

```text
(new) --createBooking--> confirmed --cancelBooking (before window)--> cancelled
confirmed --changeBooking (before window)--> confirmed (new date/hour, same number)
confirmed --staff (004)--> arrived --staff--> done
confirmed --staff (004) after the hour--> no_show
```

Places: `confirmed` and `arrived` hold one place in their slot; `cancelled` frees it at once; `done` and
`no_show` keep the historical count (the hour is over).
