# Tasks: Packages

**Input**: [spec.md](spec.md), [plan.md](plan.md), [research.md](research.md), [data-model.md](data-model.md), [contracts/callables.md](contracts/callables.md)

## Phase 1: Setup
- [X] T001 Arabic strings for the package page, «الباقة», the hint, the reminder and renewal in l10n/app_ar.arb
- [X] T002 `Clinic.packagePrice` and `packageMonths` in lib/features/clinics/data/clinics_repository.dart

## Phase 2: Foundational
- [X] T003 Tests first in test/features/packages/family_package_test.dart, then `familyPackageView` in lib/features/packages/domain/family_package.dart (current, next, lastEnded, renewable window)

## Phase 3: US1 + US2 — «الباقة» and the package page (P1)
- [X] T004 [US2] lib/features/packages/presentation/package_screen.dart (public route `/package`): status first when the family has one, both clinics' prices and months, coverage rules
- [X] T005 [US1] «الباقة» in lib/features/settings/presentation/me_screen.dart per child (end date, في العيادتين, سارية / خلصت, or a line to the page)
- [X] T006 [US2] Home service card and the booking summary hint (lib/features/home/home_screen.dart, lib/features/booking/presentation/booking_screen.dart)
- [X] T007 [US1][US2] Widget tests (test/features/packages/package_screen_test.dart, me_screen_test.dart additions) and layout sweep entries

## Phase 4: US3 — Expiry notice and renewal (P2)
- [X] T008 [US3] Functions tests first in functions/test/functions/staff/queue.test.ts: renew within 14 days (dates, price, clinic, renews, audit), too_early, has_package for a second renewal, no_package; coverage of a booking after the current end
- [X] T009 [US3] `sellPackage` renew in functions/src/callables/staff/queue.ts
- [X] T010 [US3] Dashboard child file "تجديد الباقة" and the renewal line (lib/dashboard/screens/child_file_screen.dart), widget test
- [X] T011 [US3] Reminder `package:{id}:14d` in lib/features/notifications/domain/reminders.dart and reminder_sync.dart (packages input, booking switch, route /package), tests

## Phase 5: Polish
- [ ] T012 Simulator integration test for «الباقة» and the page (integration_test/packages_test.dart); mark tasks; all checks

## Analyze (2026-10-26)

Coverage: FR-001 → T005; FR-002, FR-003 → T004; FR-004 → T006; FR-005 → T011; FR-006 → T009, T010; FR-007 → T008, T009; FR-008 → T007 (app layout) and the dashboard layout sweep. No CRITICAL or HIGH findings. Note: the clarifications are night-run assumptions; if the owner changes the renewal start date (R1), only T008–T009 change.
