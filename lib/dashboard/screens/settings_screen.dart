import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/settings/settings_repository.dart';
import '../data/dashboard_api.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';

/// The settings documents as stored.
final settingsDocProvider = StreamProvider.family<Map<String, dynamic>, String>(
  (ref, id) => ref.watch(firestoreProvider).doc('settings/$id').snapshots().map((s) => s.data() ?? const {}),
);

/// One editable setting: document, field, label, and whether it is a number or a long text.
typedef SettingField = ({String doc, String field, String label, bool number, bool long});

/// App settings and texts (005 US8, FR-024), doctor only. The policy version only goes up; raising it
/// asks every guardian to accept again (001 FR-017).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _c = <String, TextEditingController>{};

  List<(String, List<SettingField>)> _sections(AppLocalizations l10n) => [
    (
      l10n.dashSetPolicy,
      [
        (doc: 'policy', field: 'currentVersion', label: l10n.dashSetPolicyVersion, number: true, long: false),
        (doc: 'policy', field: 'privacyPolicyText', label: l10n.dashSetPrivacyText, number: false, long: true),
        (doc: 'policy', field: 'termsText', label: l10n.dashSetTermsText, number: false, long: true),
      ],
    ),
    (
      l10n.dashSetSignIn,
      [
        (doc: 'auth', field: 'maxCodeAttempts', label: l10n.dashSetMaxCodeAttempts, number: true, long: false),
        (doc: 'auth', field: 'resendWaitSeconds', label: l10n.dashSetResendWait, number: true, long: false),
        (doc: 'auth', field: 'reverifyAfterDays', label: l10n.dashSetReverifyDays, number: true, long: false),
      ],
    ),
    (
      l10n.dashSetBooking,
      [
        (doc: 'booking', field: 'bookingHorizonDays', label: l10n.dashSetHorizon, number: true, long: false),
        (doc: 'booking', field: 'maxUpcomingPerFamily', label: l10n.dashSetMaxUpcoming, number: true, long: false),
      ],
    ),
    (
      l10n.dashSetChild,
      [
        (doc: 'followUp', field: 'maxAgeMonths', label: l10n.dashSetFollowUpAge, number: true, long: false),
        (doc: 'vaccines', field: 'lateAfterDays', label: l10n.dashSetLateDays, number: true, long: false),
      ],
    ),
  ];

  TextEditingController _ctl(SettingField f, Map<String, dynamic> doc) =>
      _c.putIfAbsent('${f.doc}.${f.field}', () => TextEditingController(text: '${doc[f.field] ?? ''}'));

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = _sections(l10n);
    final docs = {
      for (final id in ['policy', 'auth', 'booking', 'followUp', 'vaccines']) id: ref.watch(settingsDocProvider(id)),
    };
    if (docs.values.any((d) => !d.hasValue)) return const Center(child: CircularProgressIndicator());

    return DashPage(
      title: l10n.dashNavSettings,
      subtitle: l10n.dashSettingsHint,
      showClinic: false,
      children: [
        for (final (i, (title, fields)) in sections.indexed) ...[
          if (i > 0) const SizedBox(height: 16),
          DashCard(
            title: title,
            icon: Icons.tune,
            tone: Tone.values[i % Tone.values.length],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 14,
                  children: [
                    for (final f in fields)
                      SizedBox(
                        width: f.long ? double.infinity : 300,
                        child: DashField(
                          label: f.label,
                          child: TextField(
                            key: Key('setting-${f.doc}-${f.field}'),
                            controller: _ctl(f, docs[f.doc]!.value!),
                            maxLines: f.long ? 6 : 1,
                            keyboardType: f.number ? TextInputType.number : null,
                            decoration: dashInput(context),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: FilledButton(
                    onPressed: () async {
                      final byDoc = <String, Map<String, Object>>{};
                      for (final f in fields) {
                        final t = _c['${f.doc}.${f.field}']!.text.trim();
                        byDoc.putIfAbsent(f.doc, () => {})[f.field] = f.number ? (int.tryParse(t) ?? 0) : t;
                      }
                      await runAction(context, () async {
                        for (final e in byDoc.entries) {
                          await ref.read(dashboardApiProvider).call('updateSettings', {
                            'doc': e.key,
                            'fields': e.value,
                          });
                        }
                      }, done: l10n.dashSaved);
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
