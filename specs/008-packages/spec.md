# Feature Specification: Packages (the annual family package)

**Feature Branch**: `008-packages`

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "008 packages. Source of truth: docs/BRD.md (FR-48, FR-49, FR-51, FR-56, FR-57, FR-60, D-14, D-15, D-45, D-46 package valid in both clinics with revenue to the selling clinic and covered visits recorded where they happen, D-49 family limits across clinics), docs/requirements.md, constitution 1.3.x, docs/design/. Fill the «الباقة» section in «حسابي». Already built in 004/005: selling at the desk, coverage in booking and payment, package revenue in reports, the profile's package status."

**Design**: no dedicated mockup. «الباقة» in «حسابي» follows `docs/design/screens/Settings.dc.html` (gift icon, «باقة يوسف · لحد ١٢ يناير ٢٠٢٧ · في العيادتين», green «سارية» pill). The Home service card «الباقة السنوية · لكل الإخوة» (`figma/home.jpg`) opens the package page. Arabic RTL; forward chevrons ‹, back ›.

## Clarifications

### Session 2026-10-26 (night run)

All answers below are **Assumption (night run) — needs owner review**: chosen as the option most consistent with the BRD, recorded here, and not yet confirmed by the owner.

- Q: Does a renewal bought before the current package ends start the same day or after it ends? → A: **Assumption (night run) — needs owner review.** It starts the day after the current one ends, so no paid days are lost (D-14: renewal is a new cash payment, no refunds). Renewal is allowed from 14 days before the end, the same window as the expiry notice.
- Q: When does the guardian get the 14-day expiry notice? → A: **Assumption (night run) — needs owner review.** A local reminder at 09:00 Cairo time 14 days before the end date and a line on the notifications page (007 machinery, D-42); it is part of the booking reminders switch, and it is skipped when a renewal already follows.
- Q: What does the guardian app show about the package before the family buys it? → A: **Assumption (night run) — needs owner review.** A package page: price at each clinic (D-45), 12 months from purchase, all siblings, unlimited clinic visits, vaccines not included (FR-56), valid in both clinics (D-46), bought in cash at the clinic (FR-49; no in-app payment in Phase 1). The booking summary shows a one-line hint to it when the family has no package.
- Q: Is the package per child or per family? → A: **Assumption (night run) — needs owner review.** Per family (FR-51, FR-57, D-15): it covers every child on the guardian's account, including a sibling added later at no charge (D-14); «حسابي» shows one line per child with the same dates.
- Q: Can staff edit what the package includes (FR-48)? → A: **Assumption (night run) — needs owner review.** Phase 1 has one annual package per clinic; staff edit its price and duration in clinic settings (already in 005). Name and coverage text are fixed by the BRD (FR-51, FR-56) and shown from the app's texts; a second package type is out of scope.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - The guardian sees the family's package in «حسابي» (Priority: P1)

In «حسابي», the «الباقة» section shows the family package: for each child "باقة يوسف · لحد ١٢ يناير ٢٠٢٧ · في العيادتين" with a «سارية» pill, or «خلصت» with the end date, or, without a package, a line that opens the package page.

**Why this priority**: The section was reserved for 008; families need to know whether a visit is covered (FR-51, D-46).

**Independent Test**: A family with an active package sees each child with the end date and «سارية»; after the end date the line says «خلصت»; without any package the line opens the package page.

**Acceptance Scenarios**:

1. **Given** an active family package ending 2027-01-12, **Then** each child shows "لحد ١٢ يناير ٢٠٢٧ · في العيادتين" and «سارية».
2. **Given** a package that ended, **Then** each child shows "خلصت في …" and the line opens the package page.
3. **Given** no package, **Then** one line "اشتركي في الباقة السنوية" opens the package page.
4. **Given** a renewal already bought, **Then** the line shows the renewal's end date.

---

### User Story 2 - The package page and the booking hint (Priority: P1)

From Home («الباقة السنوية» service card), «حسابي», or a hint in the booking summary, the guardian opens a page that explains the annual package: the price at each clinic, 12 months, all siblings, unlimited clinic visits, vaccines charged as usual, valid in both clinics, bought in cash at the clinic.

**Why this priority**: FR-48 requires the package to be shown to the mother when booking.

**Independent Test**: Open the page signed out from Home: it lists both clinics' prices from clinic settings and the coverage rules; booking without a package shows the hint, booking with one shows "الكشف مغطّى بالباقة".

**Acceptance Scenarios**:

1. **Given** clinic prices 1500 and 1600, **Then** the page shows both, each with its clinic name.
2. **Given** the family has an active package, **Then** the page starts with its status and end date.
3. **Given** a booking summary for a family without a package, **Then** a one-line hint opens the page; with a package, the summary shows the visit covered (existing).

---

### User Story 3 - Expiry notice and renewal (Priority: P2)

Fourteen days before the package ends, the guardian gets a reminder and a line on the notifications page. At the desk, staff renew it from the child file in those last 14 days; the renewal starts the day after the current package ends, at the selling clinic's price, and its revenue goes to that clinic.

**Why this priority**: D-14 requires the 14-day notice and renewal by a new cash payment.

**Independent Test**: A package ending in 10 days: the app scheduled a reminder 14 days before (already past → shown on the page); the dashboard child file offers "تجديد الباقة"; renewing creates a package starting the day after the current end.

**Acceptance Scenarios**:

1. **Given** a package ending on 2026-12-01, **Then** a reminder is scheduled for 2026-11-17 at 09:00 Cairo (past times skipped) and appears on the page once due.
2. **Given** a renewal already bought, **Then** no expiry reminder for the current package.
3. **Given** a package ending within 14 days, **When** staff choose "تجديد الباقة", **Then** a new package starts the day after the current end, for the clinic's months, at the clinic's price, sold at that clinic, audited.
4. **Given** more than 14 days left, **Then** renewal is refused (`too_early`), and selling a second package is still refused (`has_package`).
5. **Given** a renewal already bought, **Then** a second renewal is refused (`has_package`).

### Edge Cases

- A family whose package ended yesterday books today: the visit is charged (coverage ended); the page and «حسابي» say «خلصت».
- A renewal bought at clinic 2 covers visits in clinic 1 (D-46); its revenue is clinic 2's.
- A child added after the package was bought is covered at no charge (D-14, per-family package).
- Signed out: the package page is public (prices only); «الباقة» in «حسابي» is hidden.
- Package texts state facts (dates, prices, coverage); no medical judgement.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: «حسابي» MUST show a «الباقة» section for signed-in guardians: per child, the family package's end date, "في العيادتين" and «سارية», or «خلصت» with the date, or a line to the package page when there is none.
- **FR-002**: The app MUST provide a public package page with each active clinic's package price and duration (from clinic settings) and the coverage rules (FR-51, FR-56, D-14, D-46, FR-49), opened from Home, «حسابي» and the booking summary.
- **FR-003**: When the family has an active package, the package page MUST show its status and end date first.
- **FR-004**: The booking summary MUST show a hint to the package page when the family has no package covering the chosen day.
- **FR-005**: The app MUST schedule a local reminder 14 days before the active package ends, at 09:00 Cairo time, unless a renewal follows, and list it on the notifications page once due (007); it follows the booking reminders switch.
- **FR-006**: Staff MUST be able to renew a family's package from the child file within its last 14 days; the renewal MUST start the day after the current end, use the selling clinic's price and duration, record the selling clinic, and be audited.
- **FR-007**: Renewal earlier than 14 days before the end MUST be refused (`too_early`); a second renewal or a second active package MUST be refused (`has_package`).
- **FR-008**: Screens MUST lay out without overflow on phones and the dashboard at its sizes, light and dark, normal and large text.

### Key Entities

- **Package (existing)**: guardian, sold at clinic, price, startsOn, endsOn, active, sold by, sold on; a renewal is another package whose startsOn is the day after the previous endsOn.
- **Package offer (clinic settings, existing)**: price and months per clinic.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of families with a package see its end date in «حسابي».
- **SC-002**: A renewal never overlaps or leaves a gap: it starts exactly the day after the current end.
- **SC-003**: Every active package ending more than 14 days ahead has its expiry reminder scheduled within one app session.
- **SC-004**: The package page loads both clinics' prices from settings, no hard-coded price.

## Assumptions

- All clarifications above are night-run assumptions pending owner review.
- Phase 1 payment is cash at the clinic; the app sells nothing (FR-49, FR-50).
- Prices and durations already live per clinic (005, D-45).
