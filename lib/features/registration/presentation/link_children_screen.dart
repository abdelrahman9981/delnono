import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/messenger.dart';
import '../../../app/route_guard.dart';
import '../../../app/session_flags.dart';
import '../../../app/theme.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/validation/registration_rules.dart';
import '../../../core/widgets/birth_date_picker.dart';
import '../../../core/widgets/notice.dart';
import '../application/registration_controller.dart';
import '../data/registration_api.dart';

/// Link clinic-registered children (design screen 7, docs/design/screens/LinkChildren.dc.html).
/// Nothing about the children is shown before a correct birth date (FR-021). The router guard
/// moves the guardian on once the link succeeds or locks, so results are shown as app messages.
class LinkChildrenScreen extends ConsumerStatefulWidget {
  const LinkChildrenScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<LinkChildrenScreen> createState() => _LinkChildrenScreenState();
}

class _LinkChildrenScreenState extends ConsumerState<LinkChildrenScreen> {
  DateTime? _date;
  bool _submitting = false;
  int? _remaining;
  Object? _error;

  Future<void> _pick() async {
    final picked = await ref.read(birthDatePickerProvider)(context, initial: _date);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _confirm(AppLocalizations l10n) async {
    if (_date == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final linked = await ref.read(registrationApiProvider).linkClinicChildren(isoDate(_date!));
      // Children now exist, so first-run registration is complete.
      ref.read(registrationControllerProvider.notifier).finish();
      showAppMessage(l10n.linkSuccess(linked.map((c) => c.name).join(' و')));
    } on LinkWrongBirthDate catch (e) {
      setState(() => _remaining = e.remaining);
    } on LinkLocked {
      showAppMessage(l10n.linkLocked);
    } on LinkNothingToLink {
      // Already linked elsewhere (e.g. by the clinic); the guard moves on.
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _notMine() {
    ref.read(linkSkippedProvider.notifier).set(true);
    if (ref.read(registrationInProgressProvider)) {
      context.go(Uri(
        path: Routes.registerChild,
        queryParameters: widget.from == null ? null : {'from': widget.from},
      ).toString());
    } else {
      context.go(Routes.childrenAdd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenLinkChildren), automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(color: c.border),
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [c.surface, c.surface, c.blueSoft],
                  stops: const [0, .5, 1],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(color: c.blueSoft, borderRadius: BorderRadius.circular(20)),
                    child: Icon(Icons.family_restroom_outlined, color: c.blue, size: 30),
                  ),
                  Text(l10n.linkHeading, style: text.titleLarge?.copyWith(fontSize: 19), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(l10n.linkIntro, style: text.bodyMedium?.copyWith(color: c.muted), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(l10n.linkBirthDateLabel, style: text.labelMedium),
            const SizedBox(height: 7),
            InkWell(
              key: const Key('link-birth-date'),
              onTap: _pick,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: InputDecoration(
                  helperText: l10n.linkPrivacyNote,
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
                ),
                child: Text(
                  _date == null ? l10n.childBirthDatePick : arabicDigits(DateFormat.yMMMMd('ar').format(_date!)),
                  style: text.bodyLarge?.copyWith(color: _date == null ? c.muted : null),
                ),
              ),
            ),
            if (_remaining != null) ...[
              const SizedBox(height: 12),
              Notice(
                l10n.linkWrongDate(l10n.otpAttempts(_remaining!, arabicDigits(_remaining!))),
                kind: NoticeKind.warn,
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Notice(arabicErrorMessage(_error!, l10n), kind: NoticeKind.danger),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _date == null || _submitting ? null : () => _confirm(l10n),
              child: _submitting
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(l10n.confirm),
            ),
            const SizedBox(height: 6),
            OutlinedButton(onPressed: _submitting ? null : _notMine, child: Text(l10n.linkNotMine)),
          ],
        ),
      ),
    );
  }
}
