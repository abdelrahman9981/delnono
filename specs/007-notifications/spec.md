# Feature Specification: Notifications (local reminders)

**Feature Branch**: `007-notifications`

**Created**: 2026-10-25

**Status**: Draft

**Input**: User description: "007 notifications. Source: BRD D-42 (Phase 1 reminders are local notifications scheduled on the phone when a booking is made or changed and cancelled when it is cancelled; server push waits for Blaze), D-18 (booking reminder one day and one hour before; the guardian turns each type on or off; no duplicate sends for the same event), D-17 (vaccine reminder 3 days before and on the day), FR-45 (basic vaccines and the additional ones the family chose), D-34 (an in-app notifications page). Design: docs/design/screens/Notifications.dc.html (page and settings) and the bell with an unread count on Home (figma/home.jpg)."

**Design**: `docs/design/screens/Notifications.dc.html`: header «الإشعارات», «الجديد» and «قبل كده» groups, «تعليم الكل كمقروء», then «إعدادات الإشعارات» with two switches (booking reminders "قبل الميعاد بيوم وبساعة", vaccine reminders "قبلها بـ ٣ أيام وفي يومها") and the note "لو قفلتي نوع، هتلاقي التذكير برضه هنا في الصفحة دي." Home: a bell with an unread count (`figma/home.jpg`). Arabic RTL; forward chevrons ‹, back ›.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Booking reminders on the phone (Priority: P1)

A guardian books a visit. The phone shows a reminder one day before and one hour before, even with the app closed and offline. If the booking is changed (by the guardian or by the clinic), the reminders move; if it is cancelled, they disappear. No reminder is shown twice for the same booking and time.

**Why this priority**: Missed visits cost the clinic a place and the family a visit (D-18); reminders are the main reason for this feature.

**Independent Test**: Book a visit two days ahead; the phone has two reminders scheduled (day before, hour before). Move it to another hour; the reminders follow. Cancel it; none are left.

**Acceptance Scenarios**:

1. **Given** a confirmed booking more than a day away, **Then** two reminders are scheduled: 24 hours and 1 hour before it starts.
2. **Given** a booking less than a day away, **Then** only the 1-hour reminder is scheduled; a time already past is never scheduled.
3. **Given** a booking changed by the guardian or moved by the clinic, **When** the app next opens or receives the change, **Then** the reminders match the new time and the old ones are gone.
4. **Given** a cancelled booking (by anyone), **Then** its reminders are removed.
5. **Given** the same booking seen again (app restart, data refresh), **Then** nothing is scheduled twice.
6. **Given** a reminder on the phone, **When** the guardian taps it, **Then** the app opens on My bookings.

---

### User Story 2 - Vaccine reminders (Priority: P1)

For each child, the phone shows a reminder 3 days before a vaccine dose is due and on the due day, at 9:00 in the morning (Cairo time): for basic vaccines from the child's schedule, and for additional vaccines whose series the family started (a dose is recorded and more doses remain, FR-45). Doses already given get no reminder.

**Why this priority**: On-time vaccines are a core promise of the app (D-17, FR-45).

**Independent Test**: A child whose next basic dose is due in 5 days has reminders on day 2 and day 5 at 9:00; recording the dose removes them.

**Acceptance Scenarios**:

1. **Given** a basic dose not yet given, due on a future date, **Then** reminders are scheduled 3 days before and on that day at 9:00 Cairo time (past times skipped).
2. **Given** an additional vaccine with dose 1 recorded and 2 doses in total, **Then** dose 2 gets reminders based on dose 1's date plus the vaccine's interval.
3. **Given** an additional vaccine the family never started, **Then** no reminder (it is optional).
4. **Given** a dose recorded at the clinic, **Then** its reminders are removed next time the app syncs.
5. **Given** a vaccine reminder, **When** tapped, **Then** the app opens that child's profile.

---

### User Story 3 - The notifications page and the bell (Priority: P2)

The Home bell shows how many reminders the guardian has not read. The page lists reminders whose time has come and booking confirmations, newest first, in «الجديد» (unread) and «قبل كده» (read), with "mark all as read".

**Why this priority**: Notifications are easy to miss or dismiss on the phone; the page keeps them (D-34).

**Independent Test**: With a reminder whose time has passed and a new booking, the bell shows 2; opening the page lists both under «الجديد»; "mark all as read" moves them to «قبل كده» and the bell shows nothing.

**Acceptance Scenarios**:

1. **Given** a booking confirmed, **Then** the page shows "تم تأكيد حجزك" with the child and date.
2. **Given** a reminder time that has passed, **Then** the page shows it, even if that type is turned off on the phone.
3. **Given** unread items, **Then** the bell shows their count (up to "٩+"); with none, no count.
4. **Given** the guardian opens an item, **Then** it is marked read and opens My bookings or the child profile.
5. **Given** a signed-out visitor, **Then** there is no bell.

---

### User Story 4 - Turning each type on or off (Priority: P2)

On the notifications page the guardian turns booking reminders and vaccine reminders on or off separately. Off removes that type's phone reminders; on schedules them again. The page still lists them.

**Why this priority**: D-18 requires the guardian to control each type.

**Independent Test**: Turn vaccine reminders off: no vaccine reminders remain on the phone, booking reminders stay; turn on again: they come back.

**Acceptance Scenarios**:

1. **Given** vaccine reminders turned off, **Then** no vaccine reminder is scheduled and booking reminders are unchanged.
2. **Given** the phone's permission for notifications is not granted, **When** the guardian turns a type on or books a visit, **Then** the app asks for permission once, and if refused shows that reminders appear only in the page, with a way to the phone's settings.
3. **Given** the choices, **Then** they stay after the app restarts.

### Edge Cases

- More reminders than the phone allows at once: the nearest ones are scheduled first (at most 50 pending), the rest when the app next opens.
- The phone's clock or time zone differs from Cairo: reminder times are computed in Cairo time.
- Two children with doses due the same day: one reminder per child and dose.
- A guardian signs out or deletes the account: all reminders are removed from the phone.
- The web build (demo): no phone reminders; the page and bell still work.
- A reminder's text never contains a medical judgement; it names the child, the vaccine and the date only (Principle II).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST schedule local reminders for each confirmed upcoming booking at 24 hours and 1 hour before it starts, skipping times already past.
- **FR-002**: The app MUST schedule local reminders for each not-given basic dose (due date from the child's schedule) and for the next dose of each started additional series, at 9:00 Cairo time 3 days before and on the due day, skipping past times.
- **FR-003**: The scheduled reminders MUST always match the current data: rebuilt when the app starts, when bookings or doses change, and when settings change; each reminder MUST have a stable identity, so nothing is scheduled twice (D-18).
- **FR-004**: Cancelled, changed and done bookings, and given doses, MUST leave no stale reminder.
- **FR-005**: Each type (booking, vaccine) MUST be switchable on and off on the device; the choices MUST persist.
- **FR-006**: The app MUST ask for notification permission when first needed (turning a type on, or after a booking), at most once per type change, and explain if refused.
- **FR-007**: The app MUST show a notifications page with reminders whose time has come and booking confirmations, grouped new and earlier, with "mark all as read", per the design.
- **FR-008**: Home MUST show a bell with the unread count for signed-in guardians.
- **FR-009**: Tapping a reminder or a page item MUST open My bookings (booking) or the child's profile (vaccine).
- **FR-010**: Signing out or deleting the account MUST remove every scheduled reminder.
- **FR-011**: Reminder texts MUST be Arabic, name the child, the visit or vaccine and the time, and contain no medical judgement.
- **FR-012**: The new screens MUST lay out without overflow on phones, light and dark, normal and large text.

### Key Entities

- **Reminder**: kind (booking 24 h, booking 1 h, vaccine 3 days, vaccine day), the booking or child and dose it is for, the time, the text, a stable id.
- **Notification item** (page): a reminder whose time has come, or a booking confirmation; read or unread.
- **Notification settings** (device): booking on/off, vaccine on/off; read markers.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of upcoming confirmed bookings have their reminders scheduled within one app session after they are made or changed.
- **SC-002**: 0 reminders for cancelled bookings or given doses after the app syncs.
- **SC-003**: No reminder is shown twice for the same booking or dose and time.
- **SC-004**: A guardian turns a reminder type off or on in under 10 seconds.

## Assumptions

- Phase 1 has no server push (D-42); reminders exist on the phones that have the app signed in. Server push (FCM) is "blocked: Blaze" and comes later.
- 9:00 Cairo time for vaccine reminders, following the design's sample ("٩ ص").
- Settings and read markers are per device (local reminders are per device too).
- Booking confirmations in the page come from the guardian's bookings; there is no separate notifications store on the server in Phase 1.
