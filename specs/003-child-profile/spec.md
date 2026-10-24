# Feature Specification: Child Profile and Vaccines

**Feature Branch**: `003-child-profile`

**Created**: 2026-10-24

**Status**: Draft

**Input**: User description: "003 Child profile and vaccines (guardian app, read-only). Source: docs/BRD.md (FR-12–FR-16, FR-24, FR-40–FR-45, D-16, D-17, D-29, D-30, D-33, D-37) and docs/requirements.md items 7–9. Child profile: latest weight (kg), length and head circumference (cm) with their date, growth chart of the child's own measurements only, package status, switch between children; no automatic medical judgments anywhere (no "normal", "on track", no percentile labels); values and charts only. Vaccines: basic (Egyptian MOH schedule) and optional extra ones with a clear marker; dose states scheduled, due, given, late (after 7 days, a setting), missed; given doses show date and lot number; show the schedule source and last review date; the schedule and extra vaccines are doctor-approved data, seeded with clearly marked placeholders. Visits and prescriptions: visit history with the prescription photo uploaded by the doctor (photos in Cloud Storage; Storage emulator; deployment blocked: Blaze). Age follow-up lists (until age 4) with "متى تتصلين بالدكتور" containing the clinic call button and the ambulance 123 button (D-33); all follow-up and danger-sign text is doctor-owned placeholder data in brackets. Child profile and loaded data readable offline. Guardians only read; staff entry of measurements, doses and prescriptions is feature 004; seed sample data. Design: docs/design/figma/child-profile.jpg and docs/design/screens/FollowUp.dc.html. Out of scope: reminders (007), content library (005), staff screens (004)."

**Design**: `docs/design/figma/child-profile.jpg` (My child tab) and `docs/design/screens/FollowUp.dc.html` (age follow-up and "متى تتصلين بالدكتور"); see `docs/design/README.md`. The app's RTL rule applies (forward chevrons ‹, back ›). The dark-mode toggle and notification bell in the Figma top bar are not part of this feature (the app follows the system theme; notifications are feature 007).

## Clarifications

### Session 2026-10-24

- Q: Does the guardian see the doctor's written medical notes from a visit? → A: No. In Phase 1 the guardian sees the prescription photo and what was recorded (measurements, doses); the doctor's notes stay with the clinic.
- Q: Who other than the linked guardian can open a prescription photo? → A: The doctor only; the secretary cannot (FR-23, D-11, D-29).
- Q: How is the "طفلي" tab organised? → A: It opens on the selected child's profile (switcher, package, latest measurements, chart, as in the design), with entries that open separate Vaccines, Visits and Follow-up screens; the details edit and add child stay reachable from the profile.
- Q: Can a visit have more than one prescription photo? → A: Yes, one or more pages per visit, shown in order.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - See my child's latest measurements and growth chart (Priority: P1)

A signed-in guardian opens the "طفلي" tab. At the top they switch between their children. For the selected child they see the latest weight (kg), length (cm) and head circumference (cm), each with the date it was measured, and a growth chart that plots only this child's own recorded measurements against age. Nothing on the screen says whether a value is normal, low, high or on track.

**Why this priority**: The child profile is part of the closed test scope (D-35) and is what families come back to after each visit (FR-13).

**Independent Test**: With a guardian whose child has three seeded measurements, open the tab and check the latest values and dates, the chart points, and that switching children changes everything on screen.

**Acceptance Scenarios**:

1. **Given** a child with several measurements, **When** the guardian opens the profile, **Then** each of weight, length and head circumference shows its most recent value with unit and the date it was measured.
2. **Given** a child with measurements, **When** the guardian views the growth chart, **Then** it shows only that child's recorded values by age, and the guardian can switch the chart between weight, length and head circumference.
3. **Given** any measurement or chart, **Then** no label, color, icon or text states or suggests a medical judgment (for example "طبيعي", "في المعدل", percentiles, green or red ranges) (D-37).
4. **Given** a guardian with two children, **When** they pick the other child in the switcher, **Then** all sections show that child's data.
5. **Given** a child with no measurements yet, **Then** the profile says no measurements are recorded yet and that they are recorded at the clinic visit, and no chart is drawn.

---

### User Story 2 - Vaccine schedule and doses (Priority: P1)

The guardian opens the child's vaccines. They see the basic schedule (Egyptian Ministry of Health) and, clearly marked apart, the optional extra vaccines the doctor suggests for the child's age. Each dose shows its state: scheduled, due, given, late or missed. Given doses show the date given and the lot number when recorded. The list shows where the schedule comes from and when the doctor last reviewed it.

**Why this priority**: The vaccine record is the most-asked-for part of the medical file and is in the closed test scope (FR-14, FR-41, D-17).

**Independent Test**: With seeded schedule data and doses for a child, check each dose's state against the child's birth date and today, the given-dose details, the extra-vaccine marker, and the source and review date.

**Acceptance Scenarios**:

1. **Given** the schedule and a child's birth date, **When** the guardian opens vaccines, **Then** every basic dose is listed with its due age and due date, grouped by age, in schedule order.
2. **Given** a dose that was recorded as given, **Then** it shows "given" with the date given and the lot number if one was recorded.
3. **Given** a dose not given whose due date is in the future, **Then** it shows "scheduled"; from its due date it shows "due"; once more than the late threshold (default 7 days) has passed it shows "late"; once its last allowed age has passed it shows "missed" (D-17).
4. **Given** extra vaccines defined by the doctor, **Then** they appear with a clear "إضافي" marker, separate from basic vaccines, with the doctor's note and suggested age; the screen says the choice is the family's (FR-41 to FR-43).
5. **Given** the schedule settings, **Then** the screen shows the schedule source and the date of the doctor's last review (D-17).
6. **Given** placeholder schedule data, **Then** vaccine names and notes appear in brackets as placeholders until the doctor approves the real data (D-36).

---

### User Story 3 - Visit history and prescriptions (Priority: P2)

The guardian opens the child's visit history and sees past visits, newest first, with the date and the measurements and doses recorded at that visit. When the doctor uploaded a prescription photo for the visit, the guardian can open it full screen and zoom.

**Why this priority**: Families need the prescription after the visit (FR-15, D-30), but the profile and vaccines are useful without it.

**Independent Test**: With seeded visits (one with a prescription photo), open the history, open the photo, and check that another family's photo cannot be opened.

**Acceptance Scenarios**:

1. **Given** a child with visits, **When** the guardian opens the history, **Then** visits are listed newest first with date, visit type, and what was recorded at that visit.
2. **Given** a visit with a prescription photo, **When** the guardian taps it, **Then** the photo opens full screen with zoom.
3. **Given** a photo that belongs to another family's child, **Then** it cannot be read even with its address (constitution Principle I).
4. **Given** a visit without a prescription, **Then** no prescription entry is shown for it.

---

### User Story 4 - Age follow-up and when to call the doctor (Priority: P2)

For a child under 4 years old, the guardian sees the follow-up list for the child's current age (for example "متابعة الشهر التاسع") and the "متى تتصلين بالدكتور" danger signs, with a button to call the clinic and a button to call the ambulance (123). The screen states that the lists are for follow-up only and do not diagnose.

**Why this priority**: Required for Phase 1 (FR-16, D-33), but depends on doctor-owned text that is still placeholder.

**Independent Test**: With seeded age lists, open follow-up for a 9-month-old and a 5-year-old, and tap both call buttons.

**Acceptance Scenarios**:

1. **Given** a child under 4, **When** the guardian opens follow-up, **Then** the list for the child's current age band and the danger signs are shown.
2. **Given** the danger signs, **When** the guardian taps "اتصلي بالعيادة", **Then** the phone dialer opens with the clinic number; **When** they tap "الإسعاف ١٢٣", **Then** the dialer opens with 123.
3. **Given** a child 4 years or older, **Then** age follow-up is not shown and a short note says it covers ages up to 4; the danger signs and call buttons stay available.
4. **Given** placeholder lists, **Then** every item appears in brackets as placeholder text (D-36).

---

### User Story 5 - Package status (Priority: P3)

The guardian sees on the profile whether the family has an active annual package, until when, and how much time is left.

**Why this priority**: Packages are feature 006; this only displays an existing record.

**Independent Test**: Seed an active package for the family and check the card; remove it and check that the card is not shown.

**Acceptance Scenarios**:

1. **Given** an active package covering today, **Then** the profile shows it as active with its end date and the months left.
2. **Given** a package that ended, **Then** it shows as ended with its end date.
3. **Given** no package, **Then** no package card is shown.

---

### User Story 6 - Read offline (Priority: P2)

A guardian who opened the profile before opens it again without a connection and still sees the child's details, measurements, chart, vaccines, visit history and follow-up as last loaded, with a note that they are offline.

**Why this priority**: The child profile must be readable offline (D-21, constitution Principle VII).

**Independent Test**: Load the profile, turn off the connection, restart the app, and open each section.

**Acceptance Scenarios**:

1. **Given** data loaded before, **When** the device is offline, **Then** all sections show the last loaded data.
2. **Given** a prescription photo opened before, **When** offline, **Then** it still opens; a photo never opened before shows that it needs a connection.
3. **Given** no data was ever loaded for a child, **When** offline, **Then** the screen says a connection is needed the first time.

### Edge Cases

- A guardian with no children: the tab offers to add a child (001), as today.
- A child linked through the birth-date re-check or consent update (001): the profile follows the same guard; nothing is shown until the guardian passes it.
- A measurement corrected by the doctor (004): the guardian sees only the corrected value; the change log is for staff.
- Only one or two measurements: the chart shows the points it has; with one point it shows the single point.
- A measurement type with no value (for example head circumference never measured): that card shows "لسه متسجلش".
- A dose given outside the schedule date or a dose given early: it shows as given with its date; state rules apply only to doses not given.
- The schedule changes after doses were given: given doses keep their recorded date and lot; states of the rest follow the new schedule.
- A child born before a dose's schedule existed or older than its last allowed age at registration: the dose shows "missed" only if not recorded as given; the doctor can record past doses (004).
- Extra vaccines whose suggested age has passed: they stay listed, without a "late" or "missed" state, because they are optional.
- The clinic phone number is not set: the clinic call button is hidden and the 123 button still shows.
- A child unlinked from the account, or the account deleted (001): its data is no longer readable on this phone, including cached data (cache cleared on sign-out).

## Requirements *(mandatory)*

### Functional Requirements

**Profile**

- **FR-001**: The "طفلي" tab MUST open on the profile of one of the guardian's linked children, with a switcher between children; the last selected child is remembered on the device. The profile shows the package, latest measurements and growth chart, and opens separate Vaccines, Visits and Follow-up screens.
- **FR-002**: The profile MUST show the child's name, age, and allergies if recorded (FR-12), and a way to edit name and allergies (001).
- **FR-003**: The profile MUST show the latest weight (kg, one decimal), length (cm) and head circumference (cm), each with the date it was measured (FR-13, D-16).
- **FR-004**: The profile MUST show a growth chart of the child's own recorded measurements against age, switchable between weight, length and head circumference. It MUST NOT show reference curves, percentiles or ranges (D-37; D-16 reference curves need the doctor's approval and are not in this feature).
- **FR-005**: No screen in this feature may show an automatic medical judgment about measurements, growth or vaccines (for example "طبيعي", "في المعدل", "on track", percentile labels, or colors meaning good or bad) (constitution Principle II, D-37). Vaccine dose states are schedule facts, not medical judgments.

**Vaccines**

- **FR-006**: The app MUST show the child's vaccine schedule: basic vaccines (Egyptian Ministry of Health schedule) and the doctor's optional extra vaccines, with a clear marker that tells them apart (FR-41).
- **FR-007**: Each basic dose MUST show its due age and due date (from the child's birth date) and one state: scheduled, due, given, late, or missed (D-17).
- **FR-008**: Dose states MUST be: given when a dose is recorded; otherwise scheduled before the due date, due from the due date, late after the late threshold (default 7 days, a clinic setting), and missed after the dose's last allowed age if the schedule defines one.
- **FR-009**: Given doses MUST show the date given and the lot number when recorded (FR-44).
- **FR-010**: Each extra vaccine MUST show its name, suggested age, number of doses, interval between doses and the doctor's note (FR-42); its price only if the doctor chose to show it (FR-43). Doses given show as given; others carry no late or missed state.
- **FR-011**: The vaccine screen MUST show the schedule source and the date of the doctor's last review (D-17).
- **FR-012**: The schedule, extra vaccines, late threshold, source and review date MUST be doctor-approved clinic data read at runtime, not constants (FR-40, constitution Principles II and III); until feature 004 adds the editing screens they are seeded with values clearly marked as placeholders (D-36).

**Visits and prescriptions**

- **FR-013**: The app MUST show the child's visit history, newest first, with date, visit type, and the measurements and doses recorded at that visit (FR-15).
- **FR-014**: When a visit has a prescription photo uploaded by the doctor, the guardian MUST be able to open it full screen with zoom (D-30).
- **FR-015**: Prescription photos MUST be readable only by the guardian linked to the child (with current consent and an active session, as in 001) and by the doctor; the secretary and anyone else cannot read them, even with the file's address (FR-23, D-11).
- **FR-015a**: A visit MAY have one or more prescription photos (pages), shown in order. The doctor's written medical notes are not shown to the guardian in Phase 1.

**Follow-up and emergencies**

- **FR-016**: For children under 4, the app MUST show the follow-up list for the child's current age band (FR-16); age bands and their items are doctor-owned data.
- **FR-017**: The app MUST show "متى تتصلين بالدكتور" danger signs with a button that calls the clinic and a button that calls the ambulance (123) (FR-24, D-33).
- **FR-018**: For children 4 or older, age follow-up MUST NOT be shown; the danger signs and call buttons remain.
- **FR-019**: Follow-up and danger-sign text MUST be doctor-owned data, seeded as placeholders in brackets until the doctor approves it (constitution Principle II, D-36), and the screen MUST state that the lists do not diagnose.

**Package**

- **FR-020**: If the family has a package record, the profile MUST show its state (active or ended), end date and the months left; with no package nothing is shown (owned by 006, read only here).

**Access and offline**

- **FR-021**: Guardians MUST only read their own linked children's measurements, doses, visits and prescriptions, with current consent and an active session (001); they cannot create, change or delete any of them (D-11, D-29). Staff entry is feature 004.
- **FR-022**: The profile, measurements, vaccines, visits, follow-up and prescription photos already opened MUST be readable offline (D-21, constitution Principle VII).
- **FR-023**: Guardian reads of their own children's records are not written to the audit log (constitution Principle I).
- **FR-024**: All screens and messages MUST be Arabic, right to left, light and dark, following the design files, with forward chevrons pointing left and back buttons right.
- **FR-025**: Sample data (measurements, doses, visits with a prescription photo, follow-up lists) MUST be seeded for the local test environment so the screens can be tried before feature 004.

### Key Entities

- **Measurement**: child, date measured, weight (kg) and/or length (cm) and/or head circumference (cm), visit it was taken at, who recorded it; corrections kept in a staff-only change log (004).
- **Vaccine schedule entry**: vaccine, basic or extra, dose number, due age, last allowed age (optional), doctor's note, order; plus for extras: suggested age, number of doses, interval, price and whether it is shown.
- **Schedule info**: source, last review date, late threshold.
- **Dose record**: child, schedule entry, date given, lot number (optional), visit, who recorded it.
- **Visit**: child, date, visit type, booking (if any), prescription photos (one or more, uploaded by the doctor), doctor's notes (staff only, never sent to the guardian app).
- **Follow-up age band**: age range (months), title, items; **Danger signs**: list of items. Both doctor-owned.
- **Package** (read-only, owned by 006): family, start and end dates, active.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A guardian finds a child's latest weight and its date within 5 seconds of opening the "طفلي" tab.
- **SC-002**: For every seeded test case, each dose shows the state given by FR-008 (100% match across scheduled, due, late, missed and given cases, including the day before and after each boundary).
- **SC-003**: No screen in this feature contains any text or marker of a medical judgment (verified by review and automated text checks against a list of forbidden words).
- **SC-004**: 100% of attempts to read another family's child data or prescription photo are refused.
- **SC-005**: After one load, all profile sections open offline in 100% of test runs.
- **SC-006**: Profile screens open within 3 seconds on 4G (D-22).

## Assumptions

- Ages and dates are in Cairo time; a child's age band is computed from the birth date.
- The basic schedule is seeded from the Egyptian MOH schedule as a placeholder list in brackets; the doctor confirms the names, ages and last allowed ages in feature 004.
- The late threshold (7 days) is a clinic setting; "missed" applies only where the schedule sets a last allowed age.
- Extra vaccines are suggestions; the family decides by booking them (002). Choosing which extra vaccines get reminders is part of notifications (007).
- Measurements and doses are recorded by the secretary or doctor in feature 004; until then they come from seed data.
- The birth weight entered by the guardian (001) is shown as the chart's birth point for weight, labelled as birth weight.
- Package display shows the state, end date and months left; usage counts are left to feature 006.
- Prescription photos are stored in Cloud Storage; the local Storage emulator is used in development and tests; deploying Storage needs the Blaze plan (D-38) and is marked "blocked: Blaze".
- The clinic call number is a clinic setting (seeded placeholder); 123 is fixed by Egyptian emergency services.
- Visits are created by staff in feature 004 (from a booking or a walk-in); here they are read only.
