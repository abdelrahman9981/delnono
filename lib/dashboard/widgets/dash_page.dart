import 'package:flutter/material.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/messenger.dart';
import '../data/dashboard_api.dart';

/// A dashboard page: a title row with actions, then the content in a scrolling column.
class DashPage extends StatelessWidget {
  const DashPage({super.key, required this.title, this.actions = const [], required this.children});

  final String title;
  final List<Widget> actions;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
      const SizedBox(height: 16),
      ...children,
    ],
  );
}

/// Arabic text for a refused staff action (contracts/callables.md reasons).
String dashErrorText(AppLocalizations l10n, Object e) {
  if (e is StaffActionRefused) {
    return switch (e.reason) {
      'full' => l10n.dashErrFull,
      'walk_ins_stopped' => l10n.dashErrWalkInsStopped,
      'hour_not_over' => l10n.dashErrHourNotOver,
      'wrong_status' => l10n.dashErrWrongStatus,
      'not_today' => l10n.dashErrNotToday,
      'no_package' => l10n.dashErrNoPackage,
      'has_package' => l10n.dashErrHasPackage,
      'doctor_only' => l10n.dashErrDoctorOnly,
      'last_doctor' => l10n.dashErrLastDoctor,
      'bookings_outside_hours' => l10n.dashErrBookingsOutsideHours(
        ((e.details['bookings'] as List?) ?? const []).length,
      ),
      'other_clinic' => l10n.dashErrOtherClinic,
      'outside_hours' || 'started' => l10n.dashErrHourClosed,
      _ when e.code == 'permission-denied' => l10n.dashErrNotAllowed,
      _ when e.code == 'invalid-argument' => l10n.errInvalidInput,
      _ when e.code == 'already-exists' => l10n.dashErrAlreadyExists,
      _ => l10n.errGeneric,
    };
  }
  return l10n.errGeneric;
}

/// Runs a staff action and shows the result or the reason it was refused.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {String? done}) async {
  final l10n = AppLocalizations.of(context);
  try {
    await action();
    if (done != null) showAppMessage(done);
    return true;
  } catch (e) {
    showAppMessage(dashErrorText(l10n, e));
    return false;
  }
}

/// A list row whose actions wrap under the text when space is short (list tiles cannot do that).
class ActionRow extends StatelessWidget {
  const ActionRow({super.key, this.leading, required this.title, this.subtitle, this.actions = const []});

  final Widget? leading;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (subtitle != null) Text(subtitle!, style: text.bodySmall),
                  ],
                ),
                Wrap(spacing: 6, runSpacing: 6, children: actions),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
