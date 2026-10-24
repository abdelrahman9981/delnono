# Feature Specification: Two Clinics

**Feature Branch**: `004-two-clinics`

**Created**: 2026-10-24

**Status**: Draft

**Input**: User description: "004 Two clinics. Source: docs/BRD.md D-44 to D-49 (and D-06, D-07, D-14, D-28, D-31 as amended). Clinic records with placeholder data for both clinics; all clinic settings and prices move under each clinic. Booking: the guardian picks the clinic first, then sees that clinic's days, hours, places and prices; booking success and my bookings show the clinic name and address. Home shows both clinics' cards (address, hours, call, WhatsApp). Slots, prices, cancel window and vaccine days read per clinic; existing tests updated; migrate the seed data. Package coverage works in both clinics (D-46). Visits, measurements and doses carry a clinic id (D-48). Family booking limits (one active booking per day, at most 2 upcoming) apply across both clinics (D-49). Out of scope: the dashboard screens (005), staff accounts (005)."

**Design**: Home follows `docs/design/figma/home.jpg` (greeting, doctor card, then the clinic cards in place of the single "احجزي ميعاد" and "واتساب" actions); booking, success and my bookings follow the 002 designs with a clinic step and the clinic name and address added. The app's RTL rule applies (forward chevrons ‹, back ›). The Home "خدمات العيادة" grid and "الجاي عندكم" list are not part of this feature.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Book at the clinic I choose (Priority: P1)

A guardian opens the Booking tab and first picks one of the doctor's clinics (name and area). The days, hours, places left, vaccine days and prices shown are that clinic's. They finish the booking as in 002, and the success screen and "My bookings" show the clinic's name and address.

**Why this priority**: The doctor works in two places; a booking without a clinic sends families to the wrong address (D-44).

**Independent Test**: With two seeded clinics that differ in hours, vaccine days and visit price, book at each and check that the hours, prices and the clinic shown on success and in "My bookings" match the chosen clinic.

**Acceptance Scenarios**:

1. **Given** the booking screen, **When** the guardian has not chosen a clinic, **Then** they choose one before any day or hour is shown; with only one active clinic it is chosen for them.
2. **Given** clinic A open Sat–Thu evenings and clinic B open Sun–Thu mornings, **When** the guardian picks a clinic, **Then** only that clinic's open days and hours are offered, with places left out of that clinic's capacity.
3. **Given** different visit and vaccine prices at the two clinics, **When** the guardian books, **Then** the summary and the fixed price use the chosen clinic's prices (D-45).
4. **Given** a confirmed booking, **Then** the success screen and the booking card in "My bookings" show the clinic's name and address.
5. **Given** the same hour at both clinics, **When** one clinic's hour is full, **Then** the other clinic's hour is unaffected.

---

### User Story 2 - Family limits across clinics (Priority: P1)

A family can hold one active booking per day and at most two upcoming bookings in total, whichever clinics they are at (D-49).

**Why this priority**: Without a shared limit a family could take places at both clinics on the same day.

**Independent Test**: Book at clinic A for a day, then try clinic B for the same day; then hold two upcoming bookings at different clinics and try a third.

**Acceptance Scenarios**:

1. **Given** a booking at clinic A on a day, **When** the guardian tries to book clinic B the same day, **Then** it is refused with the message pointing to the existing booking.
2. **Given** two upcoming bookings at any clinics, **When** the guardian tries a third, **Then** it is refused.
3. **Given** two guardians booking the last place of the same hour at the same clinic at the same moment, **Then** exactly one succeeds (as 002).

---

### User Story 3 - Home shows both clinics (Priority: P1)

Anyone opening the app, signed in or not, sees on Home the doctor's card and one card per clinic with its name, address, working hours, a call button and a WhatsApp button, and a "احجزي هنا" action that opens booking with that clinic chosen.

**Why this priority**: Families need to know where each clinic is and how to reach it before they book; Home is public (D-09).

**Independent Test**: Open Home signed out; check both cards and their buttons; tap "احجزي هنا" on clinic B and check that booking opens with clinic B chosen after sign-in.

**Acceptance Scenarios**:

1. **Given** two active clinics, **When** Home opens, **Then** both cards show name, address, working days and hours, call and WhatsApp.
2. **Given** a clinic card, **When** the guardian taps call or WhatsApp, **Then** the dialer or WhatsApp opens with that clinic's number.
3. **Given** a clinic card, **When** the guardian taps "احجزي هنا", **Then** booking opens with that clinic chosen (after sign-in if needed).
4. **Given** a clinic marked inactive, **Then** it is not shown and cannot be booked.

---

### User Story 4 - Change, cancel and contact by clinic (Priority: P2)

Cancel and change follow the booking's clinic: its cancel window, its hours, and "كلمي العيادة" opens that clinic's WhatsApp. A change stays at the same clinic.

**Why this priority**: Rules that differ per clinic must be applied to the right booking; 002 behaviour otherwise unchanged.

**Independent Test**: Set different cancel windows at the two clinics and check when each booking can still be cancelled; inside the window, check the WhatsApp number.

**Acceptance Scenarios**:

1. **Given** clinic A's cancel window is 3 hours and clinic B's is 6, **When** a booking at B starts in 5 hours, **Then** it can no longer be cancelled or changed and "كلمي العيادة" opens clinic B's WhatsApp.
2. **Given** a change, **Then** only the booking's clinic's days and hours are offered, and prices kept or added follow 002's rules with that clinic's prices.

---

### User Story 5 - Package valid in both clinics (Priority: P2)

A family with an active annual package sees the visit as covered at either clinic (D-46); the package record keeps the clinic that sold it.

**Why this priority**: The package is sold once for the family; it must not depend on where the visit happens.

**Independent Test**: Seed a package sold at clinic A; book a visit at clinic B and check "مغطّى بالباقة".

**Acceptance Scenarios**:

1. **Given** an active package sold at clinic A, **When** the guardian books a visit at clinic B, **Then** the visit is covered and vaccines are still charged at clinic B's prices.
2. **Given** a covered booking, **Then** the booking records the clinic where the visit happens, so staff count the covered visit there (005).

---

### User Story 6 - The child's record shows where (Priority: P3)

Every visit, measurement and dose records the clinic where it happened, and the visit history shows the clinic name (D-48). The child record stays one record across clinics.

**Why this priority**: Needed by staff (005) and helpful to families; the guardian screens change little.

**Independent Test**: Seed visits at both clinics; check that the visit history shows each visit's clinic and that measurements and doses keep their clinic.

**Acceptance Scenarios**:

1. **Given** visits at both clinics, **When** the guardian opens the visit history, **Then** each visit shows its clinic name.
2. **Given** a measurement or dose, **Then** it records the clinic where it was taken.

### Edge Cases

- Only one clinic active: the clinic step is skipped and that clinic is used; Home shows one card.
- A clinic made inactive after bookings were made: existing bookings stay and still show its name and address; new bookings there are refused.
- Records made before this feature (seed data from 002 and 003, or any booking, visit, measurement or dose without a clinic): they belong to the main clinic.
- A clinic without a phone or WhatsApp number: that button is hidden.
- The vaccine list: names and the schedule are the doctor's and the same in both clinics; whether a vaccine is offered and its price are per clinic. A vaccine not offered at a clinic cannot be booked there.
- "متى تتصلين بالدكتور": one call button per active clinic plus the ambulance 123.
- The guardian opens booking from a clinic card while signed out: after sign-in and registration, booking opens with that clinic chosen.
- Account deletion (001): cancels upcoming bookings at every clinic and frees their places.

## Requirements *(mandatory)*

### Functional Requirements

**Clinics**

- **FR-001**: The app MUST support two or more clinics, each with its own name, short area name, address, phone, WhatsApp, working days and hours, holidays, capacity per hour, vaccine days and cancel window (D-44).
- **FR-002**: Each clinic MUST have its own prices: visit price, package price, and for each vaccine whether it is offered there, its price and whether the price is shown (D-45).
- **FR-003**: Clinics MUST have an active flag and a display order; only active clinics are shown and bookable.
- **FR-004**: Clinic details, hours and prices are clinic settings (constitution Principle III), seeded for two clinics with values clearly marked as placeholders until the dashboard (005) edits them (D-36).
- **FR-005**: Clinic details (name, area, address, hours, phone, WhatsApp) MUST be readable without signing in, for Home (D-09).

**Booking per clinic**

- **FR-006**: The guardian MUST choose a clinic before choosing a day; with one active clinic it is chosen automatically.
- **FR-007**: Days, hours, places left, vaccine days, the vaccines offered and all prices shown and charged MUST come from the chosen clinic.
- **FR-008**: Places MUST be counted per clinic and hour; the first confirmation wins per clinic and hour (002 FR-009).
- **FR-009**: A booking MUST record its clinic; the success screen and "My bookings" MUST show the clinic's name and address.
- **FR-010**: Cancel and change MUST use the booking's clinic's cancel window and hours; "كلمي العيادة" MUST open that clinic's WhatsApp. A change MUST keep the booking at the same clinic; moving to the other clinic is a cancel and a new booking.
- **FR-011**: A family MUST have at most one active booking per day and at most the maximum number of upcoming bookings (default 2) across all clinics together (D-49). The booking horizon and this maximum stay family-wide settings.
- **FR-012**: Booking numbers MUST stay unique across clinics.

**Home**

- **FR-013**: Home MUST show the doctor's card (placeholder photo until the real one) and one card per active clinic with name, address, working days and hours, a call button, a WhatsApp button and "احجزي هنا", which opens booking with that clinic chosen (after sign-in and registration if needed).

**Package**

- **FR-014**: An active family package MUST cover the visit price at every clinic (D-46); vaccines are charged at the booking clinic's prices.
- **FR-015**: A package record MUST keep the clinic that sold it, and a covered booking MUST keep the clinic where the visit happens, so revenue and covered visits are counted per clinic in 005.

**Child record**

- **FR-016**: Every visit, measurement and dose MUST record the clinic where it happened; the child record is one record across clinics (D-48).
- **FR-017**: The visit history MUST show each visit's clinic name.

**Migration and compatibility**

- **FR-018**: Bookings, visits, measurements, doses and packages without a clinic MUST be read as belonging to the main clinic (the first clinic in display order); the seed data MUST be migrated to two clinics with every record carrying its clinic.
- **FR-019**: Emergency contact on the follow-up screen MUST offer a call button for each active clinic that has a phone number, plus the ambulance 123 (003 FR-017).
- **FR-020**: All new screens and texts MUST be Arabic, right to left, light and dark, with the RTL chevron rule.

### Key Entities

- **Clinic**: id, name, area, address, phone, WhatsApp, active, order; schedule (working hours per weekday, holidays, capacity per hour, vaccine weekdays, cancel window); prices (visit, package, per-vaccine offered/price/shown).
- **Booking** (002, extended): clinic.
- **Hour slot** (002, extended): clinic, day, hour, places taken.
- **Family limits** (002): one active booking per day and the upcoming maximum across clinics.
- **Package** (read here, sold in 005/008): clinic that sold it.
- **Visit, measurement, dose** (003, extended): clinic.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In 100% of bookings the clinic, hours and prices shown on success and in "My bookings" are those of the clinic chosen.
- **SC-002**: No clinic hour ever has more booked places than that clinic's capacity, including simultaneous attempts on the last place.
- **SC-003**: No family ever holds two active bookings on one day or more than the upcoming maximum, across clinics.
- **SC-004**: A guardian reaches either clinic by phone or WhatsApp from Home in one tap.
- **SC-005**: All 001–003 automated checks still pass after the migration.

## Assumptions

- Two placeholder clinics are seeded: "[عيادة المقطم · بيانات مؤقتة]" (main) and "[عيادة مدينة نصر · بيانات مؤقتة]", with different hours, vaccine days and prices so the difference shows.
- Family-wide settings (booking horizon, maximum upcoming bookings, reverify days) stay global; clinic-specific ones move under each clinic.
- The doctor's schedule data (vaccine names, schedule, additional vaccine details, follow-up lists) is the same for both clinics.
- The general support WhatsApp in Account stays the main clinic's number.
- Staff screens and staff accounts (D-47) are feature 005; this feature only stores the clinic on every record so 005 can filter by it.
- Cloud Functions keep running on the emulators until Blaze is enabled for the demo (D-40).
