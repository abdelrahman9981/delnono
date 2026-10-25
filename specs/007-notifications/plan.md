# Implementation Plan: Notifications (local reminders)

**Branch**: `007-notifications` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

## Summary

The app computes, from data it already has (the guardian's bookings, children, recorded doses, the basic schedule and the vaccine catalogue), the list of reminders that should exist, and replaces the phone's scheduled local notifications with it whenever that data or the settings change (research R1). The same computation, for times already past, plus booking confirmations and cancellations, feeds the notifications page and the bell. No server changes; server push stays "blocked: Blaze" (D-42).

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47
**Primary Dependencies**: flutter_local_notifications (scheduled local notifications), timezone (already used; Africa/Cairo), shared_preferences (switches and read markers), Riverpod 3, go_router 18
**Storage**: Device only (shared_preferences); reads Firestore through existing providers
**Testing**: flutter test (pure planner unit tests, widget tests with a fake notifier), integration tests on the iOS simulator
**Target Platform**: iOS and Android phones; web (demo) uses a no-op notifier
**Project Type**: Mobile app (existing)
**Constraints**: iOS keeps at most 64 pending notifications → schedule the 50 nearest; Android 13+ needs POST_NOTIFICATIONS; inexact scheduling (no exact-alarm permission); times in Cairo time
**Scale/Scope**: A family: a few bookings and children, tens of doses

## Constitution Check

| Principle | Check |
|---|---|
| I. Privacy | Reminders stay on the device; texts name only the family's own child; signing out clears them. ✅ |
| II. Medical safety | Texts state child, vaccine and date only; no judgement. ✅ |
| III. Configurable | Reminder offsets from the BRD (D-17, D-18) as named constants in one place; per-type switches. ✅ |
| IV. Arabic RTL, accessible | Page per design, RTL, large text checked in the layout test. ✅ |
| V. Test-first | Planner is pure and unit-tested before the screens; widget tests with a fake notifier; simulator run at the end. ✅ |
| VI. Simple | No new server code or collections; rebuild-all instead of diffing. ✅ |
| VII. Cost | Local notifications are free and need no Blaze (D-42). ✅ |

## Project Structure

```text
lib/features/notifications/
  domain/reminders.dart          # planReminders, feedItems, stable ids (pure)
  data/notification_prefs.dart   # switches, read markers, permission asked (shared_preferences)
  data/local_notifier.dart       # LocalNotifier interface, plugin and no-op implementations
  data/reminder_sync.dart        # watches inputs, replaces scheduled reminders
  presentation/notifications_screen.dart
  presentation/notifications_bell.dart
lib/app/router.dart (route), lib/features/home/home_screen.dart (bell)
lib/features/booking/... booking success (permission ask)
android/app/build.gradle(.kts), AndroidManifest.xml; ios/Runner/AppDelegate.swift
test/features/notifications/*
```

## Complexity Tracking

None.
