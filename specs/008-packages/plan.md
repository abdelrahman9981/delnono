# Implementation Plan: Packages (the annual family package)

**Branch**: `008-packages` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

## Summary

Selling, coverage (booking and payment, by date) and revenue already exist (004, 005). 008 adds what the guardian sees and the renewal: a public package page with each clinic's price and the rules, the «الباقة» section in «حسابي», a booking hint, a 14-day expiry reminder through 007's planner, and renewal at the desk (`sellPackage` with `renew: true`) that starts the day after the current package ends.

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47; TypeScript / Node 22
**Primary Dependencies**: Riverpod 3, go_router 18, cloud_firestore, cloud_functions; firebase-functions v2
**Storage**: Firestore `packages` (existing), `clinics/{id}.packagePrice|packageMonths` (existing)
**Testing**: flutter test (domain, widgets, layout), Functions tests on the emulator, rules tests unchanged, simulator integration at the end, dashboard e2e at merge
**Target Platform**: iOS/Android app, dashboard in the browser
**Constraints**: No in-app payment (FR-49); coverage stays date-based on the server (`book.ts`, `queue.ts`)
**Scale/Scope**: One package per family at a time, plus at most one renewal waiting

## Constitution Check

| Principle | Check |
|---|---|
| I. Privacy | Package status shown only to the family; page is public with prices only. ✅ |
| II. Medical safety | Facts only (dates, prices, coverage). ✅ |
| III. Configurable | Price and months from clinic settings; no hard-coded price. ✅ |
| IV. Arabic RTL | New page and section per the design rules; layout tests. ✅ |
| V. Test-first | Domain and callable tests before code; simulator at the end. ✅ |
| VI. Simple | Renewal is one flag on the existing callable; reminders reuse 007. ✅ |
| VII. Cost | No new services. ✅ |

## Project Structure

```text
functions/src/callables/staff/queue.ts            # sellPackage: renew
functions/test/functions/staff/queue.test.ts      # renewal tests
lib/features/clinics/data/clinics_repository.dart # Clinic.packagePrice, packageMonths
lib/features/packages/domain/family_package.dart  # current / next / ended view (pure)
lib/features/packages/presentation/package_screen.dart  # /package
lib/features/settings/presentation/me_screen.dart # «الباقة»
lib/features/booking/presentation/booking_screen.dart   # hint
lib/features/home/home_screen.dart                # service card
lib/features/notifications/domain/reminders.dart  # package:14d
lib/dashboard/screens/child_file_screen.dart       # تجديد الباقة
```

## Complexity Tracking

None.
