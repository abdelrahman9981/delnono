# Feature Specification: Dashboard Completion (desk registration and duplicate files)

**Feature Branch**: `009-dashboard-completion`

**Created**: 2026-10-25

**Status**: Draft

**Input**: User description: "Dashboard completion. Source: BRD FR-64 (the secretary registers a guardian and child from the dashboard, e.g. for a walk-in, with the same data; when the guardian later signs in with the same mobile number, the children registered on it appear automatically after verification) and FR-65 (duplicate prevention: a child with the same name and birth date on the same number shows a warning instead of a new file; merging duplicate files is for the doctor only). Also 001 FR-021a, promised there and not yet built: after a guardian is locked out of linking, staff link the children from the dashboard."

**Design**: no mockup for these screens. They follow the dashboard rules in `docs/design/README.md` ("Clinic dashboard") and `docs/design/dashboard/dash.css`: cards with a header row, labelled fields, dates from a date picker, status pills. Arabic RTL; forward chevrons ‹, back ›.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The secretary registers a family at the desk (Priority: P1)

A family arrives without the app, for example as a walk-in. The secretary enters the guardian's mobile number and each child's name, birth date and sex (birth weight and allergies optional), the same data a guardian gives in the app (FR-63). The children get files at once, so measurements and doses can be recorded today. When the guardian later signs in to the app with that number, the app offers these children and links them after the birth-date check (001 FR-021).

**Why this priority**: Without it, walk-in children have no file, and nothing can be recorded for them (FR-64).

**Independent Test**: Register a family with two children on a new number from the dashboard; open one child's file and record a weight; sign in to the guardian app with that number, pass the birth-date check, and see both children with the weight.

**Acceptance Scenarios**:

1. **Given** the Children screen, **When** the secretary registers a number and two children, **Then** both children have files on that number, not linked to any app account, and each registration is in the audit log.
2. **Given** a walk-in in Today's list, **When** the secretary chooses to register it, **Then** the form opens with the walk-in's number and children's names already filled in.
3. **Given** desk-registered children on a number, **When** a guardian verifies that number in the app, **Then** the app asks for one child's birth date and, when it matches, links all of them (001 FR-021; no new behaviour in the app).
4. **Given** a number whose guardian already has an app account, **When** the secretary registers a child on it, **Then** the child is still created unlinked and the guardian links it with the same birth-date check, so a number reassigned to someone else never shows a child by itself.

---

### User Story 2 - A duplicate is caught instead of created (Priority: P1)

If a child with the same name and birth date already exists on the same number, the dashboard warns and shows that file instead of creating a second one (FR-65), whoever registered the first one (the guardian or the clinic).

**Why this priority**: Two files for one child split the medical record; preventing them is cheaper than merging them.

**Independent Test**: Register "يوسف أحمد", born 2024-03-15, on a number; register "يوسف  احمد" (other spacing and spelling of alef) with the same birth date on the same number: a warning appears with a link to the existing file and nothing new is created.

**Acceptance Scenarios**:

1. **Given** an existing child on a number, **When** staff register the same name (compared the same way as the app's check) and birth date on that number, **Then** no file is created, and the warning names the existing child and opens its file.
2. **Given** a family registration with several children where one is a duplicate, **Then** nothing is created, and the warning says which child is the duplicate, so the secretary can remove it and save again.
3. **Given** the same name and birth date on a different number, **Then** it is not a duplicate.

---

### User Story 3 - The doctor merges two files of one child (Priority: P2)

When two files exist for one child anyway (for example, different spellings of the name), the doctor merges them: chooses the file to keep, sees both side by side, and confirms. Measurements, doses and visits move to the kept file with their dates, clinics and change logs; upcoming bookings for the other file move to the kept file; the other file is closed and no longer appears in search or in the guardian's app. Only the doctor can merge (FR-65).

**Why this priority**: Rare, but without it a split record stays split forever.

**Independent Test**: Create two files for one child on the same number, each with one measurement; as the doctor, merge them; the kept file has both measurements, the other no longer appears in search, and the audit log has the merge.

**Acceptance Scenarios**:

1. **Given** the doctor in a child file, **When** they choose "merge with another file", **Then** they can pick only other open files on the same number, and see both files' basic data and record counts before confirming.
2. **Given** a confirmed merge, **Then** every measurement, dose and visit of the closed file is in the kept file, unchanged, and the closed file records which file it was merged into.
3. **Given** the closed file had an upcoming booking, **Then** the booking lists the kept child instead; if that booking already listed the kept child, the closed child is removed from it.
4. **Given** a secretary, **Then** no merge action is offered, and a merge request is refused.
5. **Given** a closed file, **Then** it does not appear in staff search or the guardian's app, and opening it shows which file it was merged into.

---

### User Story 4 - Staff link children after a locked link (Priority: P3)

A guardian who entered three wrong birth dates is told to contact the clinic (001 FR-021a). At the desk, after checking who the guardian is in person, staff link the number's unlinked children to that guardian's account and clear the lock.

**Why this priority**: Promised to guardians in 001; rare.

**Independent Test**: Lock linking for a number with three wrong dates in the app; in the dashboard, open one of the number's unlinked children and link it; the guardian app shows the children, and the lock is gone.

**Acceptance Scenarios**:

1. **Given** an unlinked child whose number has a guardian account, **When** staff choose "link to the guardian's account" and confirm, **Then** all unlinked children on that number are linked to that account, the lock (if any) is cleared, and the audit log records who linked them.
2. **Given** a number with no guardian account, **Then** no link action is offered (the guardian links in the app after signing in).

### Edge Cases

- The number is typed as 01xxxxxxxxx, +201xxxxxxxxx or 201xxxxxxxxx: all mean the same number (as in staff search).
- A birth date in the future, or a child older than the follow-up age the app supports, is refused with the field named (same rules as the app, FR-63).
- The secretary of clinic 1 registers a child: the file records that it was registered at clinic 1; the child's file is open to staff of both clinics as any file (D-46, D-48).
- Merging a file into itself, or with a file on another number, is refused.
- Merging two files that both have records on the same day keeps both records; nothing is deduplicated automatically (no medical judgement, Principle II).
- A merge while a guardian is viewing the closed file: the closed file disappears from their app; the kept file appears if it is linked to them.
- A closed file is never reopened; a wrong merge is fixed by the doctor correcting records, not by un-merging (kept out of scope).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Staff (secretary or doctor) MUST be able to register, from the dashboard, a mobile number and one or more children with name, birth date and sex, and optionally birth weight (kg) and allergies, validated as in the app (001 FR-018).
- **FR-002**: Desk-registered children MUST be stored on the number with no linked app account, marked as registered by staff at the staff member's current clinic, and MUST be linked only through the app's birth-date check (001 FR-021) or by staff under FR-008.
- **FR-003**: Registration MUST be offered from the Children screen and from a walk-in in Today, prefilled with the walk-in's number and children's names.
- **FR-004**: Before creating anything, the server MUST check each child against existing open files on the same number by normalised name and birth date; on any match it MUST create nothing and return the matching child(ren), which the dashboard shows with a link to the file.
- **FR-005**: Only the doctor MUST be able to merge two open files on the same number, choosing the kept file; the server MUST refuse merges by anyone else, of a file with itself, or across numbers.
- **FR-006**: A merge MUST move every measurement, dose and visit (with their change logs and staff notes) to the kept file unchanged, repoint the closed child in upcoming bookings to the kept child (dropping it when the booking already has the kept child), and mark the closed file as merged into the kept one, all at once or not at all.
- **FR-007**: Closed (merged) files MUST NOT appear in staff search, the guardian's app, or the duplicate check, and opening one MUST say which file it was merged into.
- **FR-008**: Staff MUST be able to link a number's unlinked children to the guardian account on that number, which clears a linking lock (001 FR-021a).
- **FR-009**: Every registration, merge and staff link MUST be written to the audit log with the staff member, the number and the children (D-13).
- **FR-010**: The new screens MUST follow the dashboard design rules (cards, labelled fields, dates from a date picker, RTL) and lay out without overflow at desktop and tablet widths, light and dark, normal and large text.

### Key Entities

- **Child file (existing)**: gains who registered it (`guardian` or `staff`) and at which clinic for desk registrations, and for a closed file, which file it was merged into and when.
- **Merge record**: in the audit log: kept file, closed file, the doctor, and how many measurements, doses, visits and bookings moved.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A secretary registers a family of one guardian and two children in under 2 minutes.
- **SC-002**: 100% of desk-registered children on a number appear in the guardian's app after the birth-date check passes.
- **SC-003**: No second file is created for a child with the same normalised name and birth date on the same number.
- **SC-004**: After a merge, the kept file holds 100% of both files' measurements, doses and visits, and the closed file is in no search or guardian view.
- **SC-005**: Only the doctor can merge; 100% of merge attempts by other accounts are refused.

## Assumptions

- The guardian app's linking flow (001 FR-021, FR-021a) is unchanged; desk-registered children are ordinary unlinked children on a number.
- The guardian's own name is not stored at the desk: the guardian enters their details in the app at first sign-in (001), and nothing from the clinic's record is shown before the birth-date check.
- Staff check the guardian's identity in person before linking under FR-008; the dashboard records who linked.
- Un-merging is out of scope; corrections after a merge are record corrections by the doctor.
- Walk-ins stay as they are; registering a walk-in's family creates child files but does not change the walk-in entry.
