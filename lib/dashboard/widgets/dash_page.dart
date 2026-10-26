import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/messenger.dart';
import '../../features/clinics/data/clinics_repository.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import 'dash_ui.dart';

/// A dashboard page (docs/design/dashboard): the page's top bar with its title, the clinic switch
/// and actions, then the content in a scrolling column on the canvas, and an optional sticky
/// [bottom] bar (the save bar).
class DashPage extends StatelessWidget {
  const DashPage({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.showClinic = true,
    this.bottom,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final bool showClinic;
  final Widget? bottom;
  final List<Widget> children;

  static const maxContentWidth = 1240.0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DashTopBar(
        title: title,
        subtitle: subtitle,
        leading: leading,
        actions: [if (showClinic) const ClinicSwitch(), ...actions],
      ),
      Expanded(
        child: LayoutBuilder(
          builder: (context, box) {
            final gutter = box.maxWidth < 900 ? 16.0 : 28.0;
            final end = (box.maxWidth - maxContentWidth - gutter).clamp(gutter, double.infinity);
            // Every card is built (pages are short), so a field is found even before it is scrolled to.
            return SingleChildScrollView(
              key: const Key('dash-page-scroll'),
              padding: EdgeInsetsDirectional.fromSTEB(gutter, 22, end, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            );
          },
        ),
      ),
      ?bottom,
    ],
  );
}

/// The clinic in the top bar (D-47): a segmented switch for the doctor, the clinic's name for a
/// secretary.
class ClinicSwitch extends ConsumerWidget {
  const ClinicSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final staff = ref.watch(staffSessionProvider).value;
    final clinics = ref.watch(allClinicsProvider).value ?? const <Clinic>[];
    final currentId = ref.watch(currentClinicIdProvider);
    final current = clinics.where((c) => c.id == currentId).firstOrNull;
    if (staff == null || current == null) return const SizedBox.shrink();
    String label(Clinic c) => c.area.isEmpty ? c.name : l10n.dashClinicArea(c.area);
    if (!staff.isDoctor) {
      return StatusPill(label(current), PillKind.info, key: const Key('dash-clinic-name'), dot: false);
    }
    return Tooltip(
      message: l10n.dashSwitchClinic,
      child: SegmentSwitch<String>(
        key: const Key('dash-clinic-picker'),
        options: [for (final c in clinics) (c.id, label(c))],
        value: current.id,
        onChanged: (id) => ref.read(selectedClinicIdProvider.notifier).select(id),
      ),
    );
  }
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
      'duplicate' => l10n.dashErrDuplicate,
      'same_file' => l10n.dashErrSameFile,
      'other_number' => l10n.dashErrOtherNumber,
      'closed' => l10n.dashErrClosed,
      'booked_together' => l10n.dashErrBookedTogether,
      'too_large' => l10n.dashErrTooLarge,
      'no_account' => l10n.dashErrNoAccount,
      'already_linked' => l10n.dashErrAlreadyLinked,
      'not_locked' => l10n.dashErrNotLocked,
      'too_early' => l10n.dashErrTooEarly,
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
