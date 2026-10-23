import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/messenger.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/errors/arabic_errors.dart';
import '../../../core/format/arabic_digits.dart';
import '../../../core/validation/registration_rules.dart';
import '../../../core/widgets/birth_date_picker.dart';
import '../../../core/widgets/notice.dart';
import '../application/session_controller.dart';
import '../data/auth_repository.dart';
import '../data/session_api.dart';

/// Birth-date re-check after inactivity (`/reverify`; FR-010a, FR-010b). Same layout as linking
/// clinic children (docs/design/screens/LinkChildren.dc.html).
class ReverifyScreen extends ConsumerStatefulWidget {
  const ReverifyScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<ReverifyScreen> createState() => _ReverifyScreenState();
}

class _ReverifyScreenState extends ConsumerState<ReverifyScreen> {
  DateTime? _date;
  bool _submitting = false;
  int? _remaining;
  bool _locked = false;
  Object? _error;

  Future<void> _pick() async {
    final picked = await ref.read(birthDatePickerProvider)(context, initial: _date);
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _confirm() async {
    if (_date == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(sessionApiProvider).reverifyGuardian(isoDate(_date!));
      // Lifting the flag lets the guard continue to `from`.
      ref.read(sessionControllerProvider.notifier).reverified();
    } on ReverifyWrongBirthDate catch (e) {
      setState(() => _remaining = e.remaining);
    } on ReverifyLocked {
      setState(() => _locked = true);
    } catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    ref.read(sessionControllerProvider.notifier).reset();
    appMessengerKey.currentState?.clearSnackBars();
    if (mounted) context.go(Routes.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.screenReverify), automaticallyImplyLeading: false),
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
                    child: Icon(Icons.verified_user_outlined, color: c.blue, size: 30),
                  ),
                  Text(l10n.reverifyHeading, style: text.titleLarge?.copyWith(fontSize: 19), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(l10n.reverifyIntro, style: text.bodyMedium?.copyWith(color: c.muted), textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(l10n.reverifyBirthDateLabel, style: text.labelMedium),
            const SizedBox(height: 7),
            InkWell(
              key: const Key('reverify-birth-date'),
              onTap: _locked ? null : _pick,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined, size: 20)),
                child: Text(
                  _date == null ? l10n.childBirthDatePick : arabicDigits(DateFormat.yMMMMd('ar').format(_date!)),
                  style: text.bodyLarge?.copyWith(color: _date == null ? c.muted : null),
                ),
              ),
            ),
            if (_locked) ...[
              const SizedBox(height: 12),
              Notice(l10n.reverifyLocked, kind: NoticeKind.danger),
            ] else if (_remaining != null) ...[
              const SizedBox(height: 12),
              Notice(l10n.reverifyWrongDate(l10n.otpAttempts(_remaining!, arabicDigits(_remaining!))), kind: NoticeKind.warn),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Notice(arabicErrorMessage(_error!, l10n), kind: NoticeKind.danger),
            ],
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _date == null || _submitting || _locked ? null : _confirm,
              child: _submitting
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(l10n.confirm),
            ),
            const SizedBox(height: 6),
            OutlinedButton(onPressed: _signOut, child: Text(l10n.accountSignOut)),
          ],
        ),
      ),
    );
  }
}
