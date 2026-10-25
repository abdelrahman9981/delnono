# Tasks: Notifications (local reminders)

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/local-notifier.md](contracts/local-notifier.md)
**Tests**: required (constitution V); the planner first.

## Phase 1: Setup

- [ ] T001 Add flutter_local_notifications and shared_preferences (`flutter pub add`); Android: core library desugaring in android/app/build.gradle(.kts), POST_NOTIFICATIONS and the plugin's receivers in android/app/src/main/AndroidManifest.xml; iOS: notification delegate in ios/Runner/AppDelegate.swift
- [ ] T002 [P] Arabic strings for reminders, the page, the switches and the permission note in l10n/app_ar.arb

## Phase 2: Foundational

- [ ] T003 Tests first in test/features/notifications/reminders_test.dart: booking 24 h and 1 h (past skipped, cancelled/done none), vaccine 3 days and day at 09:00 Cairo for not-given basic doses, next dose of a started additional series by interval, none for unstarted additional or given doses, stable keys and ids, 50 nearest only, switches filter scheduling but not the feed; feed has confirmations and cancellations
- [ ] T004 Implement lib/features/notifications/domain/reminders.dart (`planReminders`, `feedItems`, `reminderId`)
- [ ] T005 [P] lib/features/notifications/data/notification_prefs.dart (shared_preferences; defaults per data-model.md) with tests
- [ ] T006 [P] lib/features/notifications/data/local_notifier.dart: interface, `PluginNotifier` (Cairo `TZDateTime`, inexact, payload = route), `NoopNotifier` on web

## Phase 3: User Story 1 + 2 — Reminders on the phone (P1)

- [ ] T007 [US1] lib/features/notifications/data/reminder_sync.dart: provider watching bookings, children, doses per child, schedule, catalogue and prefs; calls `replaceAll` with the planned list (switches applied); `cancelAll` on sign-out; started from the app root
- [ ] T008 [US1] Tests in test/features/notifications/reminder_sync_test.dart with a FakeNotifier: booking added, moved, cancelled; a dose recorded; sign-out clears
- [ ] T009 [US1] Tap → route: init in lib/main.dart with the router; cold-start launch details

## Phase 4: User Story 3 + 4 — Page, bell and switches (P2)

- [ ] T010 [US3] lib/features/notifications/presentation/notifications_screen.dart per Notifications.dc.html (groups, mark all read, items open their route, switches with the note) and route `/notifications` in lib/app/router.dart
- [ ] T011 [US3] Bell with unread count on Home (lib/features/home/home_screen.dart), signed-in only
- [ ] T012 [US4] Permission: ask on the first booking success and when a switch is turned on; denied note with a button to the phone's settings
- [ ] T013 Widget tests in test/features/notifications/notifications_screen_test.dart (groups, mark read, bell count, switches, permission note) and add the page to test/app/layout_test.dart

## Phase 5: Polish

- [ ] T014 Integration test integration_test/notifications_test.dart (book → bell shows the confirmation → page → mark read; switch off/on) on the simulator
- [ ] T015 Mark tasks done; analyze, flutter test, functions and rules tests (unchanged), simulator run at the end

## Analyze (2026-10-25)

Coverage: FR-001/002/004 → T003, T004, T007, T008; FR-003 → T007; FR-005 → T005, T010; FR-006 → T012; FR-007/008 → T010, T011; FR-009 → T009, T010; FR-010 → T007; FR-011 → T002, T003; FR-012 → T013. No CRITICAL or HIGH findings. LOW: the page hides items older than 60 days (research R4) — implementation detail, kept out of the spec.
