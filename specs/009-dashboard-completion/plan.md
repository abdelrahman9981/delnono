# Implementation Plan: Dashboard Completion (desk registration and duplicate files)

**Branch**: `009-dashboard-completion` | **Date**: 2026-10-25 | **Spec**: [spec.md](spec.md)

## Summary

Three staff callables and their dashboard screens: `registerFamily` (FR-64: children on a number, unlinked, with the server-side duplicate check of FR-65), `mergeChildren` (FR-65: doctor only, moves records in one transaction and closes the other file) and `staffLinkChildren` (001 FR-021a). The guardian app does not change: desk-registered children are ordinary unlinked children on a number, which 001's linking flow already offers after the birth-date check.

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47 (dashboard, Flutter Web); TypeScript on Node 22 (Cloud Functions)
**Primary Dependencies**: Riverpod 3, go_router 18, cloud_functions, cloud_firestore; firebase-functions v2, firebase-admin
**Storage**: Cloud Firestore (`children` and their subcollections, `bookings`, `linkAttempts`, `guardians`, `auditLog`)
**Testing**: flutter test (widget and layout), Mocha + Functions/Firestore emulators, rules-unit-testing, browser e2e (`scripts/dashboard_e2e.sh`)
**Target Platform**: Dashboard in a desktop or tablet browser; Functions in us-central1 (emulator only until Blaze)
**Project Type**: Mobile app + web dashboard + serverless backend (one repo)
**Performance Goals**: Registration of a family under 2 minutes at the desk (SC-001); a merge of a typical file (< 200 records) in one transaction
**Constraints**: All writes through callables (staff never write children directly); a merge is all or nothing; no medical judgement
**Scale/Scope**: Two clinics, a handful of staff; files with tens of records

## Constitution Check

| Principle | Check |
|---|---|
| I. Privacy and consent first | Desk records hold only the number and child data; nothing is shown to an app account until the birth-date check or an in-person staff link (audited). ✅ |
| II. Medical safety | Merge moves records unchanged; no automatic deduplication or judgement. ✅ |
| III. Configurable | No new settings; validation reuses the app's limits. ✅ |
| IV. Arabic RTL, accessible | New dialogs and cards follow the dashboard rules; layout test covers them. ✅ |
| V. Test-first, emulator-tested | Functions tests per callable, rules unchanged and retested, widget and layout tests, e2e still green. ✅ |
| VI. Simple | Three callables, no new collections; closing a file reuses existing queries by clearing its number and link. ✅ |
| VII. Cost | No new paid services; emulator only (Blaze-dependent deploy stays "blocked: Blaze"). ✅ |
| Roles (D-11, D-29, D-47) | Merge is doctor only; registration and staff link are any active staff; every action audited (D-13). ✅ |

## Project Structure

```text
functions/src/callables/staff/family.ts      # registerFamily, mergeChildren, staffLinkChildren
functions/src/lib/phone.ts                   # phoneE164 shared with searchChildren
functions/src/index.ts                       # exports
functions/test/functions/staff/family.test.ts
lib/dashboard/screens/register_family_dialog.dart
lib/dashboard/screens/merge_dialog.dart
lib/dashboard/screens/children_search_screen.dart   # "+ تسجيل أسرة"
lib/dashboard/screens/today_screen.dart             # walk-in → register
lib/dashboard/screens/child_file_screen.dart        # merge (doctor), link (staff), merged notice
test/dashboard/family_test.dart
```

**Structure Decision**: Same layout as 005; new callables sit beside `childFile.ts` in `callables/staff`.

## Complexity Tracking

None.
