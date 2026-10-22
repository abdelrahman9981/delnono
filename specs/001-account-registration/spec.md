# Feature Specification: Account and Registration

**Feature Branch**: `001-account-registration`

**Created**: 2026-10-22

**Status**: Draft

**Input**: User description: "001 Account and registration. Source: docs/BRD.md (FR-01, FR-02, FR-25–FR-27, FR-61–FR-67, D-08, D-09, D-10, D-32) and docs/requirements.md items 1–3 and 12. Browse home and content without login; booking and child data require login. Phone + OTP: code valid 5 min, 5 attempts, resend after 60 s, persistent session; change phone via OTP on the new number. First run: guardian details (name, relation, optional email) → explicit consent to privacy policy and child data collection (nothing stored before consent) → first child. Multiple children per account; children the clinic registered on the same phone appear after verification; warn on duplicate name + birth date. Guardian edits child name and allergies only; birth date and sex are staff-only. Account deletion removes the app account; the clinic keeps the medical record."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Sign in with a mobile number (Priority: P1)

A guardian opens the app, enters their mobile number, receives a one-time code by SMS and enters it. From then on the app keeps them signed in until they sign out or delete the account.

**Why this priority**: Every other part of the app that touches a child (booking, child profile, vaccines) needs a verified guardian. Nothing else in Phase 1 works without it.

**Independent Test**: Install the app, sign in with a mobile number and code, close and reopen the app, and confirm the guardian is still signed in.

**Acceptance Scenarios**:

1. **Given** a guardian on the sign-in screen, **When** they enter a valid Egyptian mobile number and the correct code within 5 minutes, **Then** they are signed in.
2. **Given** a code was sent, **When** the guardian enters it after 5 minutes, **Then** it is rejected with an Arabic message and they can request a new code.
3. **Given** a code was sent, **When** the guardian enters a wrong code 5 times, **Then** that code stops working and they must request a new one.
4. **Given** a code was just sent, **When** fewer than 60 seconds have passed, **Then** the resend option is unavailable and shows the remaining wait.
5. **Given** a signed-in guardian, **When** they close and reopen the app days later, **Then** they are still signed in without a new code.

---

### User Story 2 - First-run registration with consent (Priority: P1)

After their first sign-in, a guardian enters their details (full name, relation to the child, optional email), reads the privacy policy and terms, gives explicit consent to the collection of their child's data, and then registers their first child (name, birth date, sex; optionally birth weight and allergies).

**Why this priority**: Consent is a legal precondition (Egypt Law 151/2020, constitution Principle I). No child data may exist in the app until it is recorded.

**Independent Test**: Run first-run registration end to end and confirm the guardian, the consent record and the first child exist. Run it again, stop before consent, and confirm no guardian or child data was kept.

**Acceptance Scenarios**:

1. **Given** a newly verified guardian, **When** they finish guardian details, consent and first child, **Then** the account, the consent record (with date and policy version) and the child profile are saved.
2. **Given** a guardian on the consent step, **When** they do not accept, **Then** they cannot continue and no guardian or child data is saved.
3. **Given** a guardian who closed the app before consenting, **When** they sign in again, **Then** registration restarts at guardian details.
4. **Given** the child form, **When** name, birth date or sex is missing, **Then** the child cannot be saved and the missing field is named in Arabic.
5. **Given** the guardian details form, **When** the email is left empty, **Then** registration continues.

---

### User Story 3 - Browse without an account (Priority: P2)

A parent who has not signed in can open the home screen and the content library. When they try to book or open child data, the app asks them to sign in and then returns them to what they were doing.

**Why this priority**: Letting parents see the clinic and its advice before committing their phone number lowers the barrier to joining. It also matches the "no guest mode" decision (D-09): browsing is open, anything personal is not.

**Independent Test**: On a fresh install, open home and content without signing in; tap booking and confirm the sign-in prompt appears; sign in and confirm the guardian lands back on booking.

**Acceptance Scenarios**:

1. **Given** a visitor who is not signed in, **When** they open home or content, **Then** both are shown.
2. **Given** a visitor who is not signed in, **When** they open booking or a child area, **Then** they are asked to sign in.
3. **Given** a visitor asked to sign in from booking, **When** they complete sign-in (and first-run registration if new), **Then** they return to booking.

---

### User Story 4 - See children the clinic already registered (Priority: P2)

The secretary registered a guardian and child at the clinic desk (for example, a walk-in) using the guardian's mobile number. When that guardian later signs in to the app with the same number, those children appear in their account.

**Why this priority**: Many families will visit the clinic before installing the app. Without this link they would see an empty account or create duplicate records.

**Independent Test**: Register a guardian and child from the dashboard, sign in to the app with the same number, and confirm the child appears after verification.

**Acceptance Scenarios**:

1. **Given** children registered by the clinic on a mobile number, **When** a guardian verifies that number in the app and enters the correct birth date of one of those children, **Then** those children appear in the account.
2. **Given** children registered by the clinic on a mobile number, **When** the guardian enters a wrong birth date 3 times, **Then** no children are linked and an Arabic message asks them to contact the clinic.
3. **Given** a clinic-registered guardian signing in for the first time, **When** first-run registration starts, **Then** the guardian enters their own details (nothing from the clinic's record is shown before the birth-date check), consent is still required before the birth-date check, and the "first child" step is skipped once children are linked.
4. **Given** the birth-date check is shown, **When** the guardian chooses "these aren't my children, add a child", **Then** nothing is linked, no attempt is counted, and they go to adding a child; the check is offered again at their next sign-in until the children are linked or the check is locked.
5. **Given** a number with no clinic-registered children, **When** a guardian verifies it, **Then** the account starts with no children.

---

### User Story 5 - Manage children (Priority: P2)

A guardian adds more children to the same account, and edits a child's name and allergies. Birth date and sex are shown but cannot be changed by the guardian.

**Why this priority**: Families with siblings are a core use case (shared visits, family package). Limiting edits protects the vaccine schedule and growth tracking, which depend on birth date and sex.

**Independent Test**: Add a second child, edit the first child's name and allergies, and confirm birth date and sex are read-only.

**Acceptance Scenarios**:

1. **Given** a signed-in guardian with one child, **When** they add another child, **Then** both children appear under the account.
2. **Given** an existing child with the same name and birth date on this account, **When** the guardian tries to add the child again, **Then** a warning is shown and no duplicate profile is created.
3. **Given** a child profile, **When** the guardian edits the name or allergies, **Then** the change is saved and recorded with date and editor.
4. **Given** a child profile, **When** the guardian looks at birth date or sex, **Then** they are read-only, with a note to contact the clinic to correct them.
5. **Given** a child older than 4 years, **When** the guardian registers them, **Then** registration is accepted.

---

### User Story 6 - Change mobile number (Priority: P3)

A signed-in guardian changes the account's mobile number by verifying a code sent to the new number. The account, children and history stay the same.

**Why this priority**: Numbers change, but rarely. It is needed before public release, not for the first booking.

**Independent Test**: Change the number on a test account and confirm sign-in works with the new number, not the old one, and the children are unchanged.

**Acceptance Scenarios**:

1. **Given** a signed-in guardian, **When** they enter a new number and the correct code sent to it, **Then** the account's number changes and the old number no longer signs in to this account.
2. **Given** a new number that already belongs to another app account, **When** the guardian tries to change to it, **Then** the change is refused, the account keeps its current number, and an Arabic message asks the guardian to contact the clinic.

---

### User Story 7 - Delete account (Priority: P3)

A guardian deletes their account from inside the app. Their app account and access end; the clinic keeps the children's medical record for the period set by legal review.

**Why this priority**: Required by the BRD (FR-27, D-32), by Egypt Law 151/2020 and by app store rules, but not needed to book a first visit.

**Independent Test**: Delete a test account, confirm the guardian is signed out and the account cannot be opened, and confirm the dashboard still shows the children's medical record.

**Acceptance Scenarios**:

1. **Given** a signed-in guardian, **When** they request deletion, **Then** they see what will be removed and what the clinic keeps, and must confirm before anything is deleted.
2. **Given** a confirmed deletion, **When** it completes, **Then** the guardian is signed out, the app account is removed, and the deletion is recorded in the audit log.
3. **Given** a deleted account, **When** the clinic opens one of its children in the dashboard, **Then** the medical record is still there.

---

### Edge Cases

- The guardian enters a number that is not a valid Egyptian mobile number: rejected before any code is sent.
- The SMS never arrives: the guardian can resend after 60 seconds; repeated requests from the same number are capped per day to limit cost and abuse.
- No connection during sign-in or registration: an Arabic message explains that a connection is needed; nothing is half-saved.
- The guardian enters a birth date in the future or more than 18 years ago: rejected.
- The guardian signs in on a second device: both stay signed in.
- The privacy policy changes materially after consent: the guardian must accept the new version before reaching child data again.
- The guardian deletes their account while they have upcoming bookings: those bookings are cancelled and their places freed (details in feature 002).
- A guardian whose account was deleted signs in again with the same number: they start first-run registration as a new guardian, and the clinic-registered children on that number are linked again under FR-021.
- A guardian tries to edit birth date or sex through any route: refused.
- A guardian with clinic-registered children fails the birth-date check: the account still works and they can add children themselves; the clinic's children stay unlinked until staff link them.
- WhatsApp is not installed: the link opens the WhatsApp web chat for the clinic's number instead.
- A guardian adds a child themselves that the clinic already registered on the same number (same name and birth date): the duplicate warning (FR-022) applies.

## Requirements *(mandatory)*

### Functional Requirements

**Access**

- **FR-001**: The app MUST show the home screen and content library without sign-in.
- **FR-002**: The app MUST require sign-in and completed registration (including consent) before booking or viewing, adding or editing child data.
- **FR-003**: After sign-in from a protected area, the app MUST return the guardian to that area.
- **FR-004**: The app MUST NOT offer a guest mode that stores any personal or child data.

**Sign-in**

- **FR-005**: Guardians MUST sign in with an Egyptian mobile number and a one-time code sent to it by SMS. The mobile number is the account identity.
- **FR-006**: A code MUST expire 5 minutes after it is sent.
- **FR-007**: A code MUST stop working after 5 wrong entries.
- **FR-008**: A new code MUST NOT be sendable until 60 seconds after the previous one; the app MUST show the remaining wait.
- **FR-009**: The number of codes sent to one number per day MUST be capped.
- **FR-010**: A guardian MUST stay signed in across app restarts until they sign out or delete the account.
- **FR-011**: Each account MUST have exactly one guardian in Phase 1.

**First-run registration**

- **FR-012**: First-run registration MUST follow this order: guardian details, then consent, then first child.
- **FR-013**: Guardian details MUST include full name and relation to the child (mother, father, other); email is optional and validated only if given.
- **FR-014**: The app MUST show the privacy policy and terms of use, and MUST require explicit consent both to the policy and terms and to the collection of child data, before registration can continue.
- **FR-015**: The app MUST NOT store any guardian details or child data entered in the app before consent is given (records the clinic created at the desk are the clinic's own). If registration is abandoned before consent, it restarts at guardian details.
- **FR-016**: The consent record MUST include the date, time and policy version accepted.
- **FR-017**: When the policy version changes materially, the guardian MUST accept the new version before reaching child data again.

**Children**

- **FR-018**: A child profile MUST require name, birth date and sex; birth weight (kg) and allergies are optional.
- **FR-019**: An account MUST support more than one child.
- **FR-020**: Children of any age MUST be registrable; age-based follow-up and content stop at 4 years (handled by later features).
- **FR-021**: When a guardian verifies a number on which the clinic has registered children, the app MUST ask the guardian for the birth date of one of those children, and MUST link the children to the account only if it matches. Mobile numbers in Egypt get reassigned, and this stops a new owner of a number from seeing another family's children.
- **FR-021a**: After 3 wrong birth dates, the app MUST stop offering the link and ask the guardian to contact the clinic, where staff can link the children from the dashboard. Failed attempts are recorded in the audit log.
- **FR-022**: If a child with the same name and birth date already exists on the same number, the app MUST warn the guardian and MUST NOT create a duplicate. Merging duplicates is for the doctor only.
- **FR-023**: Guardians MUST be able to edit a child's name and allergies only; each edit is recorded with date and editor.
- **FR-024**: Guardians MUST NOT be able to change a child's birth date or sex; only doctor and secretary can, because they drive the vaccine schedule and growth tracking.

**Phone change**

- **FR-025**: A signed-in guardian MUST be able to change the account's number by verifying a code sent to the new number, under the same code rules as sign-in.
- **FR-025a**: If the new number already belongs to another app account, the app MUST refuse the change and ask the guardian to contact the clinic; the two accounts are never merged or reassigned from the app.
- **FR-026**: After a phone change, the account, its children and history MUST be unchanged, and the old number MUST no longer sign in to this account.

**Account deletion**

- **FR-027**: Guardians MUST be able to delete their account from inside the app, after a confirmation that explains what is removed and what the clinic keeps.
- **FR-028**: Deletion MUST remove the app account, the guardian's sign-in and personal app settings, and end all sessions.
- **FR-029**: Deletion MUST NOT remove children's medical records held by the clinic; they are kept for the period set by legal review.
- **FR-030**: Deletion MUST be recorded in the audit log.

**Account screen**

- **FR-033**: The account screen MUST show the guardian's name, number and relation, their children, the accepted policy version, and entries for changing number, signing out and deleting the account.
- **FR-034**: The account screen MUST offer a "talk to the clinic on WhatsApp" link that opens a chat with the clinic's WhatsApp number, labelled for questions and support only, not booking (D-21, D-27). The number is a clinic setting.
- **FR-035**: The account screen MUST show a Notifications entry as a placeholder until feature 007 provides the notifications page and settings.

**General**

- **FR-031**: All screens, messages and errors in this feature MUST be in Arabic with right-to-left layout.
- **FR-032**: Sign-in, registration, phone change and deletion require a connection; the app MUST say so in Arabic when offline.

### Key Entities

- **Guardian account**: one guardian per account in Phase 1. Mobile number (identity), full name, relation, optional email, created date, status (active, deleted).
- **Consent record**: belongs to a guardian account. Policy version, date and time accepted, what was consented to (policy and terms, child data collection).
- **Child**: name, birth date, sex, optional birth weight, optional allergies, linked guardian number, who registered the child (guardian or clinic), edit history. Survives account deletion as part of the clinic's record.
- **Clinic-registered guardian**: guardian details and number entered by the secretary at the clinic, before any app account exists. Becomes linked to an app account when the number is verified.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new guardian completes sign-in, registration and their first child in under 3 minutes.
- **SC-002**: At least 90% of guardians who start first-run registration finish it in the closed test.
- **SC-003**: Zero child records entered by a guardian in the app exist without a matching consent record.
- **SC-004**: 100% of clinic-registered children on a verified number appear in that guardian's account once the linking check (FR-021) passes.
- **SC-005**: Zero duplicate child profiles (same name, birth date and number) are created by guardians.
- **SC-006**: In 100% of tests, a signed-in guardian is not asked for a new code after restarting the app, unless they signed out, deleted the account or changed number.
- **SC-007**: An account deletion request completes in under 1 minute and leaves the clinic's medical record intact in 100% of tests.

## Assumptions

- Guardians use Egyptian mobile numbers (+20) able to receive SMS.
- "Relation" offers mother, father and other; "other" needs no free text in Phase 1.
- The daily cap on codes per number (FR-009) is a security setting; its value and whether it is editable from the dashboard are decided in the plan.
- Whether code validity, attempt limit and resend wait (FR-006 to FR-008) are dashboard settings or fixed security values is decided in the plan; the values above are the defaults.
- The BRD's acceptance criterion ("a warning is shown and no duplicate is created") overrides the looser "warn" in the input: the guardian cannot create the duplicate.
- Guardians who lose access to their old number, or whose new number already has an account (FR-025a), change it through the clinic; staff-side number change and staff-side child linking (FR-021a) belong to feature 004 (clinic dashboard).
- The limit of 3 birth-date attempts (FR-021a) is a default; whether it is a dashboard setting is decided in the plan.
- Upcoming bookings on a deleted account are cancelled; the rule itself belongs to feature 002 (booking).
- The retention period for clinic-held records after deletion is set by the lawyer review required by the constitution (Principle I).
- The privacy policy and terms text are provided by the clinic; placeholder text is clearly marked until then (D-36).
- A second guardian per account is out of scope (D-10).
