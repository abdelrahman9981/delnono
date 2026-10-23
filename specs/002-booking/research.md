# Research: Booking (002)

The stack, testing approach and Functions setup are those of 001 ([001 research](../001-account-registration/research.md),
R2, R5, R6, R8). This file records only the decisions new to booking.

## R1. Atomic capacity ("first confirm wins", FR-009, SC-002)

**Decision**: one Firestore document per hour, `slots/{YYYY-MM-DD}_{HH}`, holding `taken` (places in use).
`createBooking`, `cancelBooking` and `changeBooking` run in a Firestore transaction that reads the slot,
checks `taken < capacity`, and increments or decrements it together with the booking write. Walk-ins in
004 change the same counter.

**Rationale**: Firestore serialises transactions that touch the same document and retries the loser,
which then sees the hour full and returns "الميعاد اتحجز". The count is exact without locks. At clinic
scale (one doctor, ~6 places per hour) contention on one document is negligible.

**Alternatives considered**: counting bookings with a query on every attempt (not safe for
concurrency); one document per place (more writes, harder capacity changes); a client-side check
(unsafe, Principle I).

## R2. One booking per family per day, upcoming limit (FR-011, FR-011a)

**Decision**: a per-family lock document `familyQuota/{uid}` holding `active: [{bookingId, date,
startsAt}]` for the family's confirmed bookings that have not started. Every `createBooking`,
`changeBooking` and `cancelBooking` reads and rewrites it in its transaction: a new booking needs no
entry for its `date` and fewer than `maxUpcomingPerFamily` entries that have not started (past entries
are dropped as they are read). "Family" is the guardian account (001, D-10).

**Rationale**: two bookings by the same guardian for different hours touch no common slot document, and
Firestore does not lock query ranges, so query checks alone could let both pass (analyze H1). Writing
the same per-family document makes concurrent requests conflict, and the transaction retry sees the
first booking.

**Alternatives considered**: queries inside the transaction (not safe for different hours); a
deterministic booking id per family and day (covers FR-011 but not the upcoming limit).

## R3. Booking number (FR-010)

**Decision**: a counter document `counters/bookings` incremented in the booking transaction; the number
is stored as `number` and shown as "نونو ٢٤٨" (Arabic-Indic digits).

**Rationale**: short, readable at the desk, unique. The extra write per booking is fine at this scale.

## R4. Price snapshot and changes (FR-013 to FR-016, FR-023)

**Decision**: the booking stores a `price` snapshot: visit `{amount, covered}`, one line per chosen
vaccine `{childId, vaccineId, name, amount | null when hidden}`, and `total` (with `hasHiddenPrices`).
The server computes it from `settings/booking`, `vaccines/*` and the family's package in the transaction.
On change, lines for children and vaccines that stay keep their stored amounts; new lines use current
prices; the visit line keeps its amount unless the booking had no visit before (FR-023, clarification).

**Rationale**: the guardian always sees what they will pay, independent of later price edits (FR-47).

**Price shown = price charged (analyze H2)**: the app sends `expectedTotal`, the total its summary
showed. If the server's total differs (a price changed while she was choosing), the transaction writes
nothing and returns `failed-precondition` with `reason: price_changed` and the new price; the app shows
the new total and asks her to confirm again.

## R5. Time and the cancel window (FR-001, FR-020)

**Decision**: every hour has `date` (`YYYY-MM-DD`, Cairo), `hour` (0–23, Cairo) and `startsAt`
(timestamp of the hour start in Africa/Cairo, computed on the server with the IANA zone so Egypt's
summer time is right). Cancel and change are allowed while `now < startsAt − cancelWindowHours`.
The app uses the same rule only to decide what to show; the server decides.

## R6. Showing availability (FR-003)

**Decision**: the app listens to the slot documents of the chosen day (only `taken`; no personal data)
and combines them with `settings/booking` for capacity and hours. Full hours update live.

**Rationale**: guardians see places disappear without refreshing; the transaction still decides.

## R7. Settings and placeholder data (FR-024, D-36)

**Decision**: `settings/booking` (capacity 6, working hours per weekday, holidays, vaccine weekdays,
visit price 300, cancel window 3 h, horizon 14 days, max upcoming 2, `placeholder: true`) and a
`vaccines` collection (name, price, `showPrice`, `kind` basic/additional, `active`, `placeholder: true`).
Seeded vaccine names are marked placeholder in brackets ("[تطعيم مؤقت ١]") because vaccine content must
come from the doctor (Principle II). Feature 004 adds the editing screens; feature 003 adds the schedule.

## R8. Packages (FR-016)

**Decision**: read `packages` where `guardianUid == uid`, `startsOn <= date <= endsOn`, `active`. Feature
006 creates them; until then the collection is empty and the visit is always charged. The app reads the
same record to show "باقة نشطة" in the summary; the server decides the price.

## R9. Account deletion frees bookings (001 edge case)

**Decision**: extend 001's `deleteAccount` so the same transaction cancels the guardian's upcoming
confirmed bookings and frees their places. Audit as part of `account.deleted` (`details.cancelledBookings`).

## R10. Booking history (FR-026)

**Decision**: each booking has an `events` subcollection written by the functions:
`{type: created | changed | cancelled, by, at, from?, to?}`. Not the audit log: bookings are not medical
data, prices or roles (constitution Principle I, 1.1.2).

## R11. Routes and the Booking tab

**Decision**: the Booking tab (`/booking`) is the booking screen (Figma `booking.jpg`), with a
"حجوزاتي" action in the top bar. My bookings is `/booking/mine`, the success screen
`/booking/done/:id`, and change is `/booking/change/:id` (the booking screen pre-filled). All are inside
the shell so the Booking tab stays selected; nested routes get a back button pointing right (RTL rule).

**Note**: docs/design/README.md maps the Home screenshot to 002, but the feature description lists only
booking, success and my bookings. Home stays a placeholder; its design is left for a later feature.
