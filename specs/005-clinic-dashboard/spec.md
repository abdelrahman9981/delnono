# Feature Specification: Clinic Dashboard

**Feature Branch**: `005-clinic-dashboard`

**Created**: 2026-10-24

**Status**: Draft

**Input**: User description: "005 Clinic dashboard (Flutter Web, in this repo, deployed to Firebase Hosting later). Source: BRD FR-19–FR-23, FR-28, FR-37–FR-40, FR-46–FR-49, FR-58–FR-60, D-05–D-07, D-11–D-13, D-19, D-20, D-29, D-36 and D-44–D-48. Staff sign-in, one account per staff member, created and disabled by the doctor only, each secretary tied to one clinic. Today: hour calendar and arrival queue (arrived, done, no-show), walk-ins, stop walk-ins when full, cash payment and package per visit. Schedule: working hours, holidays, capacity, vaccine days, per clinic. Child file: basic data; secretary records measurements and doses (date, lot number); only the doctor corrects them after saving, with a change log; doctor-only notes. Prices, packages and the vaccine list, per clinic. Content and follow-up lists: secretary drafts, doctor publishes. Reports: daily and monthly (bookings, arrivals, no-shows, walk-ins, cash, packages sold), date filter, CSV without medical data, per clinic, and both clinics for the doctor. Settings and texts, staff accounts, audit log (doctor only). Desktop browser first, usable on a tablet; Arabic RTL; same design tokens (docs/design/tokens.css)."

**Design**: no Figma for the dashboard. It uses the app's design tokens (`docs/design/tokens.css`): colours, Readex Pro, radii, cards, pills, buttons, light and dark; a side navigation on desktop that becomes a drawer on a tablet. Arabic RTL; forward chevrons ‹, back ›.

## Clarifications

### Session 2026-10-24

- Q: How do staff sign in? → A: Email and password, one account each, created by the doctor with a temporary password that must be changed at first sign-in. Phone codes stay for guardians (no SMS cost for staff, desktop use).
- Q: When is a child's visit recorded: on arrival or when done? → A: When marked "تم" (done); measurements, doses and payment attach to that visit (D-48).
- Q: Can a status be undone? → A: Statuses move forward only; the doctor alone can undo a mistaken "لم يحضر" or "تم" on the same day, recorded in the audit log.
- Q: What happens to a walk-in child who is not registered? → A: The walk-in keeps the family name, phone and child names; no child record is created automatically; staff can register the child's basic data on that phone, and the family links it in the app (001 FR-021).
- Q: Can the secretary change her clinic's prices and schedule? → A: Yes, for her clinic only (FR-46, D-47); every change is in the audit log. The vaccine list and schedule themselves are the doctor's.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Staff sign in with their own account (Priority: P1)

A secretary or the doctor opens the dashboard in a browser and signs in with their own account. The secretary sees only her clinic; the doctor sees every clinic and can switch between them. Accounts are created and disabled only by the doctor.

**Why this priority**: Every other dashboard task depends on knowing who is acting and which clinic they may see (D-11, D-12, D-47).

**Independent Test**: Sign in as the seeded doctor and the seeded secretary of clinic 1; check what each can see; disable the secretary and check she can no longer sign in or read anything.

**Acceptance Scenarios**:

1. **Given** a staff account, **When** they sign in, **Then** the dashboard opens on Today for their clinic (the doctor: the main clinic, with a clinic switcher).
2. **Given** a secretary of clinic 1, **Then** no screen, list or report shows clinic 2's bookings, queue, payments or settings, and requests for them are refused.
3. **Given** the doctor, **When** they create a staff account (name, email, role, clinic for a secretary), **Then** the person can sign in with a temporary password and must set their own on first sign-in.
4. **Given** a disabled account, **Then** it cannot sign in, and any open session loses access.
5. **Given** a guardian account, **When** it tries the dashboard, **Then** access is refused.

---

### User Story 2 - Today: calendar and arrival queue (Priority: P1)

The secretary sees today's hours for her clinic with the bookings in each hour and places left. When a family arrives she marks "وصل"; they join the arrival queue in arrival order. When they are seen she marks "تم"; after the hour she marks families who did not come as "لم يحضر". She adds walk-ins to the queue, and can stop walk-ins for the day when the clinic is full.

**Why this priority**: The queue is the clinic's daily work (D-06, FR-58 to FR-60).

**Independent Test**: With seeded bookings for today, mark arrivals out of booking order, add a walk-in, mark done and no-show, and check the queue order, statuses and places left.

**Acceptance Scenarios**:

1. **Given** today's bookings, **Then** the calendar shows each working hour with its bookings (number, children, visit type, status) and places left out of the capacity.
2. **Given** a confirmed booking, **When** the secretary marks "وصل", **Then** it joins the queue at the end, ordered by arrival time; no priority for package holders (FR-60).
3. **Given** an arrived booking, **When** marked "تم", **Then** it leaves the waiting list and shows as done; a visit is recorded for each child at this clinic (D-48).
4. **Given** a confirmed booking whose hour has ended, **When** marked "لم يحضر", **Then** its status is no-show (no penalty, D-05).
5. **Given** a family without a booking, **When** the secretary adds a walk-in (name, phone, children, visit type) to the current hour, **Then** it takes a place in that hour's capacity and joins the queue (FR-58, FR-59); a full hour refuses walk-ins.
6. **Given** "إيقاف الحالات بدون حجز" is on for today, **Then** no walk-in can be added until it is turned off (D-07).
7. **Given** a booking, **When** the secretary cancels or moves it on the family's behalf, **Then** capacity, hours and family limits apply (not the cancel window) and the action is recorded with her name (FR-37).

---

### User Story 3 - Payment and package per visit (Priority: P1)

When a visit is done, the secretary records the cash amount paid, or that the visit was covered by the family's package, and the vaccines charged. She can sell an annual package to a family at her clinic's price.

**Why this priority**: Cash is the only payment in Phase 1 and must be recorded per visit (FR-49, D-14, D-46).

**Independent Test**: Record cash for a visit, record a package-covered visit, sell a package, and check the totals in the daily report.

**Acceptance Scenarios**:

1. **Given** a done visit, **When** the secretary records payment, **Then** the amount defaults to the booking's fixed price (visit and vaccines, or vaccines only when covered) and can be adjusted; it is stored with who recorded it and the clinic.
2. **Given** a family with an active package, **Then** the visit is marked covered and the package's covered visit is counted at this clinic (D-46).
3. **Given** a family without an active package, **When** the secretary sells one, **Then** it is created for the family with this clinic's package price, starting today and ending after the package duration (12 months, a setting), and the revenue counts for this clinic.

---

### User Story 4 - Child file, measurements and doses (Priority: P1)

Staff search a child by name or guardian phone and open the child file. The secretary sees basic data (name, age, guardian phone) and records measurements (weight, length, head circumference) and vaccine doses (date, lot number) at her clinic. After saving, only the doctor can correct them, and every correction is kept in a change log. The doctor also writes visit notes that no one else sees.

**Why this priority**: Measurements and doses feed the guardian's child profile (003) and are in the closed test scope (D-29, D-35).

**Independent Test**: As a secretary record a measurement and a dose; try to edit them (refused); as the doctor correct them and read the change log; write a note; check the guardian app shows the new values and never the note.

**Acceptance Scenarios**:

1. **Given** a search by name or phone, **Then** matching children are listed with name, age and guardian phone; opening one is written to the audit log (D-13, FR-28).
2. **Given** the secretary, **When** she saves a measurement or a dose, **Then** it is stored with the date, the clinic and her name, and appears in the guardian's profile.
3. **Given** a saved measurement or dose, **When** the secretary tries to change it, **Then** it is refused.
4. **Given** the doctor, **When** they correct a saved value, **Then** the value changes, the change log keeps the old and new value, who and when, and the audit log records it.
5. **Given** the doctor, **When** they write a note on a visit, **Then** only the doctor can read it (not the secretary, not the guardian).
6. **Given** a staff member, **When** they edit basic data (birth date, sex, name, allergies), **Then** the change is saved and recorded (001 FR-024).

---

### User Story 5 - Schedule, prices, packages and vaccines per clinic (Priority: P2)

Staff edit their clinic's working hours, holidays, capacity per hour, vaccine days, cancel window, visit price, package price and duration, and which vaccines are offered with their price and whether the price is shown. The doctor edits the vaccine list itself (names, basic or additional, the schedule) and approves it.

**Why this priority**: Every value the app reads was a placeholder until now (D-36, Principle III).

**Independent Test**: Change clinic 2's hours, holiday and visit price; check the guardian booking screen for clinic 2 changes at once and confirmed bookings keep their price.

**Acceptance Scenarios**:

1. **Given** a secretary, **Then** she edits only her clinic's schedule and prices; the doctor edits any clinic.
2. **Given** a price change, **Then** confirmed bookings keep their fixed price (FR-47) and the change is in the audit log (D-13).
3. **Given** the doctor, **When** they edit the vaccine list or schedule and approve it, **Then** the review date updates and the placeholder mark is removed for approved items.
4. **Given** a secretary, **Then** she cannot change the vaccine list or schedule (doctor-owned medical data, Principle II).

---

### User Story 6 - Content and follow-up lists (Priority: P2)

The secretary drafts tips and videos (title, category, suitable age, link) and edits follow-up lists and danger signs as drafts; only the doctor publishes or archives them.

**Why this priority**: Doctor-owned medical text must be approved before families see it (D-19, D-36, Principle II).

**Independent Test**: As a secretary draft a tip and a follow-up change; check they are not visible to guardians; as the doctor publish them; check guardians now see them.

**Acceptance Scenarios**:

1. **Given** a secretary, **When** she saves content, **Then** it is a draft; she cannot publish.
2. **Given** the doctor, **When** they publish, **Then** guardians can read it; archived items disappear for guardians.
3. **Given** follow-up lists or danger signs edited as a draft, **Then** the app keeps showing the published version until the doctor publishes the draft.

---

### User Story 7 - Reports (Priority: P2)

Staff see daily and monthly numbers for their clinic: bookings, arrivals, no-shows, walk-ins, cash collected and packages sold, with a date filter and CSV export without medical data. The doctor sees each clinic and both together.

**Why this priority**: Required by the BRD (D-20), used after the daily work is in place.

**Independent Test**: With seeded activity on several days at both clinics, compare the report numbers with the seed and open the CSV.

**Acceptance Scenarios**:

1. **Given** a date range, **Then** the report shows one row per day (or per month) with the six numbers, and totals.
2. **Given** a secretary, **Then** only her clinic is reported; the doctor can pick a clinic or both.
3. **Given** the CSV export, **Then** it contains only dates, clinic and the six numbers, no child names, phones or medical data.

---

### User Story 8 - Settings, texts, staff and audit log (Priority: P3)

The doctor edits app texts and settings (policy text and version, sign-in limits, booking horizon and family limits, follow-up age limit, late-dose days), manages staff accounts, and reads the audit log with filters.

**Why this priority**: Needed before launch; used rarely.

**Independent Test**: Change the policy version and check guardians are asked to accept again (001); disable a secretary; filter the audit log by action and date.

**Acceptance Scenarios**:

1. **Given** the doctor, **Then** they can edit the settings and texts; the secretary cannot.
2. **Given** the audit log, **Then** the doctor sees child file openings, medical changes, price and permission changes, with who, when and what, filterable by date and action; entries are kept one year (D-13); no one else can read it.

### Edge Cases

- A secretary account without a clinic cannot sign in to any clinic until the doctor assigns one.
- Two secretaries mark the same booking at the same moment: the second sees the current status; statuses only move forward (confirmed → arrived → done; confirmed → no-show), except the doctor can undo a mistaken no-show the same day.
- Walk-in when the hour is full: refused with a message; a walk-in can be added to the next hour instead.
- A walk-in child who is not registered in the app: the walk-in keeps name and phone; staff can later register the child (basic data) on that phone so the family can link it in the app (001 FR-021).
- Capacity lowered below what is already booked: existing bookings stay; no new bookings or walk-ins until places free up.
- Changing hours or holidays that remove an hour with bookings: the change is allowed only after those bookings are moved or cancelled; the dashboard lists them.
- A dose recorded for a vaccine not offered at this clinic: allowed (the doctor's list is shared); the price is not charged automatically.
- The doctor's own account cannot be disabled; there is always at least one active doctor.
- The browser is offline: the dashboard says so and blocks changes (no offline writes for staff).
- Reports span the period before 004: records without a clinic count for the main clinic.

## Requirements *(mandatory)*

### Functional Requirements

**Accounts and access**

- **FR-001**: Each staff member MUST have their own account; only the doctor creates, edits and disables staff accounts (D-12). Roles: doctor, secretary.
- **FR-002**: A secretary MUST be tied to exactly one clinic and MUST only see and change that clinic's bookings, queue, payments, schedule and prices (D-47). The doctor sees and changes every clinic.
- **FR-003**: Guardian accounts MUST NOT access the dashboard or staff data.
- **FR-004**: Disabled accounts MUST lose access at once.

**Today**

- **FR-005**: The dashboard MUST show today's calendar for the clinic: each working hour with its bookings and walk-ins and places left (FR-19, D-28).
- **FR-006**: Staff MUST be able to mark a booking arrived, done or no-show; the arrival queue is ordered by arrival time with no priority (D-06, FR-60).
- **FR-007**: Staff MUST be able to add walk-ins to an hour; walk-ins count against that hour's capacity (FR-58, FR-59, D-07).
- **FR-008**: Staff MUST be able to stop and resume walk-ins for a day (D-07).
- **FR-009**: Staff MUST be able to cancel or move a booking on the family's behalf, recorded with the staff member (FR-37). The app's capacity, hours and family limits apply; the cancel window does not, because families inside it are told to contact the clinic (002 FR-020).
- **FR-010**: Marking done MUST record a visit for each child at the clinic (D-48), linked to the booking or walk-in.

**Payments and packages**

- **FR-011**: Staff MUST record, per visit, the cash amount and whether the package covered it (FR-49); the amount defaults to the fixed price.
- **FR-012**: Staff MUST be able to sell an annual package to a family at their clinic's price; it starts on the sale date, lasts the package duration (default 12 months), is valid in every clinic, and its revenue counts for the selling clinic (D-14, D-46, FR-48).

**Child file**

- **FR-013**: Staff MUST be able to find a child by name or guardian phone and open the child file; every opening by staff MUST be written to the audit log (D-13, FR-28).
- **FR-014**: The secretary MUST see basic data (name, age, sex, guardian phone, allergies) and record measurements and doses with date, lot number and clinic; she MUST NOT see doctor notes or prescriptions (FR-23).
- **FR-015**: Only the doctor MUST be able to correct a saved measurement or dose; each correction keeps the old and new values, who and when, in a change log (D-29).
- **FR-016**: Only the doctor MUST be able to write and read visit notes (D-11).
- **FR-017**: Staff MUST be able to edit a child's basic data, including birth date and sex (001 FR-024), recorded in the child's history.

**Clinic settings and lists**

- **FR-018**: Staff MUST be able to edit their clinic's working hours, holidays, capacity, vaccine days, cancel window, visit price, package price and duration, and vaccine offers and prices (D-44, D-45); the doctor any clinic.
- **FR-019**: Only the doctor MUST be able to edit the vaccine list and schedule, the schedule source and review date (FR-40, Principle II).
- **FR-020**: Price changes MUST NOT change confirmed bookings (FR-47) and MUST be written to the audit log.
- **FR-021**: Content items (tips and videos: title, category, suitable age, link) and follow-up lists and danger signs MUST have draft, published and archived states; secretaries save drafts, only the doctor publishes or archives (D-19, FR-39). Guardians see only published items.

**Reports**

- **FR-022**: Reports MUST show, per day and per month in a date range: bookings, arrivals, no-shows, walk-ins, cash collected for visits, packages sold and package revenue (kept apart from visit cash), per clinic; the doctor can also see both clinics together (D-20).
- **FR-023**: Reports MUST export to CSV with no child names, phones or medical data.

**Settings, texts and audit**

- **FR-024**: The doctor MUST be able to edit app settings and texts (policy text and version, sign-in limits, booking horizon and family limits, follow-up age limit, late-dose days).
- **FR-025**: The audit log MUST record child file openings by staff, medical data changes, price changes and permission changes with who, when and what; only the doctor reads it; entries are kept one year (D-13).

**General**

- **FR-026**: The dashboard MUST work in a desktop browser first and be usable on a tablet; Arabic, right to left, light and dark, using the app's design tokens.
- **FR-027**: Every staff write MUST be checked on the server against the staff member's role and clinic.

### Key Entities

- **Staff member**: name, email, role (doctor, secretary), clinic (secretary), active.
- **Walk-in**: clinic, date, hour, family name and phone, children (registered or by name), visit type, arrival time, status.
- **Arrival**: booking or walk-in, arrival time, status changes with who and when.
- **Visit** (003): child, clinic, date, booking or walk-in; payment (cash amount, covered by package, recorded by); doctor note (doctor only).
- **Package** (002/004): family, clinic that sold it, price paid, start, end, active.
- **Content item**: title, category, suitable age, link, status, author, publisher.
- **Day status**: clinic, date, walk-ins stopped.
- **Audit entry**: who, when, action, subject, details; kept one year.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A secretary marks an arrival or adds a walk-in in under 10 seconds from the Today screen.
- **SC-002**: 100% of secretary requests for another clinic's data are refused.
- **SC-003**: No hour ever holds more bookings and walk-ins than its capacity.
- **SC-004**: Report totals match the recorded bookings, visits, payments and packages exactly for any date range.
- **SC-005**: 100% of staff child-file openings, medical corrections and price or permission changes appear in the audit log.
- **SC-006**: A measurement saved by a secretary appears in the guardian's child profile within 5 seconds.

## Assumptions

- Staff sign in with email and password (Firebase Authentication), separate from guardians' phone sign-in; the doctor's first account is created by the developer during setup (docs/demo-plan.md).
- The dashboard is a second entry point of this Flutter project (Flutter Web), sharing models, theme and Arabic strings with the app; deploying to Firebase Hosting is a later step (Hosting works on the free plan; the callables it uses need Blaze, D-40).
- Package duration defaults to 12 months and is a clinic setting.
- Push notifications from the dashboard (FR-22) are feature 007.
- The guardian Content tab that shows published content is feature 006; this feature only manages content.
- Everything runs on the Firebase emulators until Blaze is enabled for the demo (D-40).
