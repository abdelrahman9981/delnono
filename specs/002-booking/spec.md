# Feature Specification: Booking

**Feature Branch**: `002-booking`

**Created**: 2026-10-23

**Status**: Draft

**Input**: User description: "002 Booking. Source: docs/BRD.md (FR-03–FR-07, FR-47, FR-52–FR-54, FR-59, FR-60, D-01–D-07, D-27, D-28, D-31) and docs/requirements.md item 4–5. App-only booking of an hour slot with configurable capacity (default 6), entry by arrival order, full hours disabled. Visit type: clinic visit, or vaccine only (vaccine days only, takes a normal place, pays vaccine price only). One or more children per booking; siblings in the same visit take one place and pay one visit price; vaccines chosen per child. Instant, atomic confirmation; a second attempt on a full hour sees "الميعاد اتحجز". Cancel or change up to 3 hours before (setting), after that "كلمي العيادة"; a cancelled place is freed at once. Status: confirmed → arrived → done, or cancelled, or no-show; only staff set arrived/done/no-show (004). Price fixed at booking time. Prices, capacity, working hours, vaccine days and the cancel window are settings with marked placeholder values until 004. Screens: booking, booking success, my bookings (upcoming and past). Out of scope: walk-ins and arrival (004), package logic (006, but show "covered by package" if a package exists), reminders (007), online visits and payment (Phase 2)."

**Design**: `docs/design/figma/booking.jpg`, `booking-success.jpg`, `my-bookings.jpg` and the Figma prototype in `docs/design/README.md`. The Figma list chevrons point the wrong way for RTL; the app's rule applies (forward ‹, back ›). The dark-mode toggle and notification bell in the Figma top bar are not part of this feature (the app follows the system theme; notifications are feature 007).

## Clarifications

### Session 2026-10-23

- Q: When a guardian changes a confirmed booking, which prices does it keep? → A: The fixed prices for children and vaccines already booked are kept; only added items get today's prices.
- Q: Can one family have more than one active booking on the same day? → A: No. One active booking per family per day; to add a child, change the existing booking.
- Q: How many upcoming bookings can one family hold at once? → A: Up to 2 upcoming bookings per family, as a clinic setting.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Book a clinic visit (Priority: P1)

A signed-in guardian opens the Booking tab, chooses "clinic visit", picks a day, picks an hour that still has places (for example ٦ لـ ٧ م, "فاضل ٤ من ٦"), selects one or more of their children, reviews the total and confirms. The booking is confirmed at once and a success screen shows the booking number, day, hour, children and amount to pay at the clinic, with a reminder that entry within the hour is by arrival order.

**Why this priority**: Booking from the app is the main reason families install it (D-27: booking is app-only). Everything else in this feature builds on a confirmed booking.

**Independent Test**: With a registered guardian and one child, book a visit for an hour with free places and confirm the success screen and the booking in "My bookings".

**Acceptance Scenarios**:

1. **Given** a guardian on the booking screen, **When** they pick a day, **Then** only that day's open hours are shown, each with the number of places left out of the hour's capacity, and full hours are shown as "مكتمل" and cannot be picked.
2. **Given** a day the clinic is closed (outside working days or on a holiday), **When** the guardian looks at the days, **Then** that day cannot be picked.
3. **Given** two siblings selected for the same visit, **When** the guardian confirms, **Then** the booking takes one place in the hour and the visit price is charged once (FR-52, D-06).
4. **Given** a valid selection, **When** the guardian confirms, **Then** the booking is confirmed immediately (no clinic approval), gets a booking number, and the success screen shows it (D-01).
5. **Given** the success screen, **When** the guardian taps "عرض حجوزاتي", **Then** "My bookings" opens with the new booking under upcoming.

---

### User Story 2 - No double booking of the last place (Priority: P1)

Two guardians try to take the last place in the same hour at the same moment. Exactly one booking is confirmed; the other guardian is told "الميعاد اتحجز" and picks another hour, with nothing charged or reserved.

**Why this priority**: Overbooking breaks the clinic's day and the trust in app-only booking (D-03, D-27).

**Independent Test**: Fill an hour to one place left, send two confirmations together, and check that exactly one succeeds and the hour shows full.

**Acceptance Scenarios**:

1. **Given** an hour with one place left, **When** two guardians confirm at the same time, **Then** exactly one booking is created and the other sees "الميعاد اتحجز" and is returned to choose an hour.
2. **Given** an hour the guardian was looking at became full before they confirmed, **When** they confirm, **Then** they see "الميعاد اتحجز" and the hour shows as full.
3. **Given** an hour that is full, **When** a confirmed booking in it is cancelled, **Then** the place is available to other guardians immediately (D-02).

---

### User Story 3 - Book vaccines (Priority: P1)

A guardian books a vaccine visit for a child on one of the clinic's vaccine days, either together with a clinic visit or as "vaccine only". They choose the vaccines per child; each vaccine has its own price that is added to the visit. A vaccine-only booking takes a normal place in the hour and pays only the vaccine prices (D-31).

**Why this priority**: Vaccines are a core reason for visits and have different days and prices; getting them wrong charges families the wrong amount.

**Independent Test**: On a vaccine day, book "vaccine only" for one child with one vaccine; the total equals that vaccine's price and the hour loses one place.

**Acceptance Scenarios**:

1. **Given** "vaccine only" or a visit with vaccines, **When** the guardian looks at days, **Then** only the clinic's vaccine days can be picked (FR-53).
2. **Given** two children, **When** the guardian picks vaccines, **Then** they choose vaccines separately for each child, and a child may have none (D-31).
3. **Given** a vaccine-only booking, **When** it is confirmed, **Then** no visit price is charged, the total is the sum of the chosen vaccine prices, and the booking takes one place in the hour.
4. **Given** a visit with vaccines, **When** the total is shown, **Then** it is the visit price (once for siblings) plus each chosen vaccine's price (FR-54).
5. **Given** a vaccine whose price the clinic chose not to show, **When** it is chosen, **Then** the summary says its price is paid at the clinic instead of a number, and the total says it does not include that vaccine.

---

### User Story 4 - My bookings (Priority: P2)

The guardian opens "My bookings" and sees upcoming bookings (confirmed, or arrived today) and past ones (done, cancelled, no-show), each with day, hour, children, visit type, booking number, status and the amount due at the clinic as fixed when it was booked.

**Why this priority**: Guardians need to see what they booked and what they will pay; the clinic depends on them coming at the right hour.

**Independent Test**: With one upcoming and one past booking, both appear under the right tab with the right status and amount.

**Acceptance Scenarios**:

1. **Given** bookings in different states, **When** the guardian opens "My bookings", **Then** upcoming lists confirmed bookings (and arrived ones on their day) from soonest, and past lists done, cancelled and no-show bookings from most recent.
2. **Given** the clinic changed the visit price after a booking was confirmed, **When** the guardian views that booking, **Then** it still shows the price fixed at booking time (FR-47).
3. **Given** a no-show booking, **When** the guardian views it, **Then** it shows "لم يحضر" with no penalty or charge (D-05).
4. **Given** no bookings, **When** the guardian opens "My bookings", **Then** an empty state offers "احجزي ميعاد جديد".

---

### User Story 5 - Cancel or change a booking (Priority: P2)

Until a set time before the hour starts (default 3 hours), the guardian can cancel a confirmed booking or change it to another day and hour. After that, the card says "فاضل أقل من ٣ ساعات" and offers "كلمي العيادة" (WhatsApp, support only) instead of cancel or change.

**Why this priority**: Freeing places early lets other families book; a late change needs the clinic's judgment (D-04).

**Independent Test**: Cancel a booking 4 hours before its hour and check that the place is free; try at 2 hours and check that only "كلمي العيادة" is offered. Change a booking after a price rise and check that the booked items keep their old prices.

**Acceptance Scenarios**:

1. **Given** a confirmed booking more than the cancel window before its hour, **When** the guardian cancels and confirms, **Then** it becomes cancelled and its place is free at once (D-02).
2. **Given** a confirmed booking more than the cancel window before its hour, **When** the guardian changes it to another hour with free places, **Then** the old place is freed and the new one taken in one step, the booking keeps its number, and the success screen shows the new time.
3. **Given** the new hour fills while changing, **When** the guardian confirms the change, **Then** they see "الميعاد اتحجز" and the original booking is unchanged.
4. **Given** a booking within the cancel window, **When** the guardian opens it, **Then** cancel and change are not offered, and "كلمي العيادة" opens the clinic's WhatsApp chat (D-27: support, not booking).
5. **Given** the cancel window setting is changed, **When** guardians view their bookings, **Then** the new window applies.

---

### User Story 6 - Covered by package (Priority: P3)

If the family has an active annual package (created in feature 006), the visit price shows as "مغطّى بالباقة" and is not charged; vaccine prices are still charged (requirements item 5).

**Why this priority**: Packages are sold in feature 006, but booking must not charge covered families once packages exist.

**Independent Test**: With an active package record for the family, book a visit with a vaccine; the visit shows "مغطّى بالباقة" and the total equals the vaccine price.

**Acceptance Scenarios**:

1. **Given** an active package covering the booking's date, **When** the guardian books a visit, **Then** the summary shows "باقة نشطة" and the visit as "مغطّى بالباقة" with no visit charge.
2. **Given** an active package, **When** the booking includes vaccines, **Then** vaccine prices are still added.
3. **Given** no package or an expired one, **When** the guardian books, **Then** the visit price is charged.

---

### Edge Cases

- The guardian has no children linked: the booking screen asks them to add a child first (link to add child).
- No connection: booking, cancelling and changing need a connection; the app says so in Arabic and nothing is half-done (constitution Principle VII).
- An hour that has already started: it cannot be booked.
- The family already has an active booking that day: a second booking that day is refused with a clear message pointing to the existing one, where children can be added by changing it.
- The family already holds the maximum number of upcoming bookings (default 2): a new booking is refused until one is done, cancelled or past.
- Capacity is lowered by the clinic below the number already booked: existing bookings stay; the hour shows full until places free up.
- A vaccine day is removed after vaccine bookings were made: existing bookings stay as booked; the clinic handles them (004).
- The selected child is unlinked or the account is deleted (001): their upcoming bookings are cancelled and the places freed.
- Arrival order: the app never shows a position or time inside the hour; it says entry is by arrival order (FR-60, D-28).
- Re-check after inactivity or outdated consent (001): booking follows the same guard as child data.

## Requirements *(mandatory)*

### Functional Requirements

**Slots and capacity**

- **FR-001**: Bookings MUST be for an hour slot (for example ٦ لـ ٧ م) on a clinic working day, within the clinic's working hours for that day (D-28).
- **FR-002**: Each hour MUST have a capacity (default 6) that counts every place taken in it, including walk-ins added by staff in feature 004 (FR-59, D-07).
- **FR-003**: The app MUST show, for the chosen day, only hours that have not started, with the places left out of the capacity; full hours MUST be shown as full and not selectable (FR-03).
- **FR-004**: Guardians MUST be able to book from today up to a booking horizon (default 14 days ahead).
- **FR-005**: Days outside working days, holidays and closures MUST NOT be selectable.

**Booking**

- **FR-006**: A booking MUST have a visit type: clinic visit, or vaccine only (FR-04, D-31).
- **FR-007**: A booking MUST include one or more of the guardian's linked children; all children in one booking share one place (D-06, FR-52).
- **FR-008**: Vaccines MUST be chosen per child from the clinic's vaccine list, and only on vaccine days (FR-53, D-31). A vaccine-only booking MUST include at least one vaccine.
- **FR-009**: Confirmation MUST be instant and atomic: the place is taken on the first successful confirmation; if the hour filled meanwhile, the guardian sees "الميعاد اتحجز" and nothing is booked (D-01, D-03).
- **FR-010**: Each booking MUST get a short booking number shown to the guardian and staff (for example "نونو ٢٤٨").
- **FR-011**: A family MUST NOT have more than one active booking on the same day; siblings for that day are added to the same booking (FR-52).
- **FR-011a**: A family MUST NOT hold more than the maximum number of upcoming bookings (default 2, a clinic setting).
- **FR-012**: Booking MUST be possible only in the app; WhatsApp is offered for questions and late changes only (D-27).

**Price**

- **FR-013**: The visit price MUST be charged once per booking, whatever the number of children (FR-52); a vaccine-only booking has no visit price (D-31).
- **FR-014**: Each chosen vaccine's price MUST be added per child (FR-54).
- **FR-015**: Prices MUST be fixed when the booking is confirmed; later price changes MUST NOT change confirmed bookings, and the guardian sees the current price while booking (FR-47). If a price changed after the summary was shown, the booking MUST NOT be made at a different total: the guardian sees the new total and confirms again.
- **FR-016**: When the family has an active package covering the booking date, the visit price MUST show as covered and not be charged; vaccines are still charged.
- **FR-017**: Payment is cash at the clinic; the app shows the amount due and takes no payment (Phase 2 adds payment).

**My bookings, cancel and change**

- **FR-018**: Guardians MUST see their upcoming and past bookings with day, hour, children, visit type, vaccines, booking number, status and amount due.
- **FR-019**: Booking status MUST be one of confirmed, arrived, done, cancelled, no-show; guardians can only cancel; arrived, done and no-show are set by staff (feature 004) (D-02, D-05).
- **FR-020**: Guardians MUST be able to cancel or change a confirmed booking until the cancel window (default 3 hours) before the hour starts; after that the app MUST offer only "كلمي العيادة" (D-04, FR-06).
- **FR-021**: Cancelling MUST free the place at once (D-02).
- **FR-022**: Changing MUST move the booking to another hour atomically (free the old place and take the new one together), keeping the booking number; if the new hour is full, the original booking is unchanged.
- **FR-023**: A change MAY also change children and vaccines, under the same rules as a new booking. Prices already fixed for the children and vaccines kept in the booking stay as they were; only added children's vaccines, added vaccines, or a visit price that was not charged before (for example a vaccine-only booking changed to a clinic visit) use today's prices (FR-47).

**Settings**

- **FR-024**: Capacity per hour, working days and hours, holidays, vaccine days, the visit price, each vaccine's price and whether it is shown, the cancel window, the booking horizon and the maximum upcoming bookings per family MUST be clinic settings, not constants (constitution Principle III). Until feature 004 adds the editing screens, they are seeded with values clearly marked as placeholders (D-36).

**General**

- **FR-025**: All booking screens, messages and errors MUST be in Arabic, right to left, following docs/design (booking, success, my bookings), with forward chevrons pointing left and back buttons pointing right.
- **FR-026**: Booking, cancelling and changing MUST be recorded with who and when; staff actions come in feature 004.

### Key Entities

- **Booking**: number, guardian, children (one place), visit type, vaccines per child, day and hour, status, price snapshot (visit price or "covered by package", each vaccine price, total), created and changed times, cancel time.
- **Hour slot**: a day and hour with its capacity and the places taken in it (bookings now, walk-ins from 004).
- **Clinic booking settings**: capacity, working days and hours, holidays, vaccine days, visit price, cancel window, booking horizon, maximum upcoming bookings per family.
- **Vaccine**: name, price, whether the price is shown, basic or additional (defined by the doctor; full schedule logic in 003).
- **Package** (read-only here, owned by 006): family, start and end dates, active or not.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A guardian with one child books a visit in under 1 minute from opening the Booking tab.
- **SC-002**: No hour ever has more booked places than its capacity, including under simultaneous attempts on the last place.
- **SC-003**: A cancelled place is bookable by others within 2 seconds of the cancellation.
- **SC-004**: In 100% of bookings the amount shown at confirmation equals the amount shown later in "My bookings", even after price changes.
- **SC-005**: 100% of cancel and change attempts inside the cancel window are refused, and 100% outside it succeed when the place is available.
- **SC-006**: Booking screens open within 3 seconds on 4G (D-22).

## Assumptions

- Days and hours are in Cairo time; an hour "starts" at its listed start (for example 6 pm for ٦ لـ ٧ م).
- Booking horizon (14 days), working hours and holidays are placeholders until the doctor sets them in 004.
- Vaccines offered for booking come from a clinic vaccine list with prices; due-date suggestions per child come with the vaccine schedule in feature 003.
- A vaccine price marked hidden is still charged at the clinic; the app shows it as "بالسعر في العيادة".
- Cancelling has no fee.
- Upcoming bookings of a deleted account are cancelled and their places freed (001 edge case, delivered here).
- Packages are read from a family package record created by feature 006; until then no family has one.
- The success screen and "My bookings" follow the Figma screenshots; "قريب" marks a booking inside the cancel window.
- Reminders before the visit are feature 007; arrival, walk-ins and the queue are feature 004.
