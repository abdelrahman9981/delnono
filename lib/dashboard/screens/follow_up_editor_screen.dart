import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/settings/settings_repository.dart';
import '../../features/child_profile/data/follow_up_repository.dart';
import '../data/dashboard_api.dart';
import '../data/staff_session.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';

/// The saved drafts, or null when there are none (research R7).
final followUpDraftsProvider = StreamProvider<({List<FollowUpBand> bands, List<String>? dangerSigns})?>(
  (ref) => ref.watch(firestoreProvider).collection('followUpDrafts').snapshots().map((q) {
    if (q.docs.isEmpty) return null;
    final settings = q.docs.where((d) => d.id == '_settings').firstOrNull;
    return (
      bands: [
        for (final d in q.docs)
          if (d.id != '_settings') FollowUpBand.fromSnapshot(d),
      ]..sort((a, b) => a.order.compareTo(b.order)),
      dangerSigns: settings == null
          ? null
          : [for (final s in (settings.data()['dangerSigns'] as List? ?? const [])) '$s'],
    );
  }),
);

/// Follow-up lists and danger signs (005 US6): staff edit drafts; the app keeps showing the published
/// lists until the doctor publishes (D-19, Principle II).
class FollowUpEditorScreen extends ConsumerStatefulWidget {
  const FollowUpEditorScreen({super.key});

  @override
  ConsumerState<FollowUpEditorScreen> createState() => _FollowUpEditorScreenState();
}

class _BandEdit {
  _BandEdit(FollowUpBand b)
    : title = TextEditingController(text: b.title),
      from = TextEditingController(text: '${b.fromMonths}'),
      to = TextEditingController(text: '${b.toMonths}'),
      items = TextEditingController(text: b.items.join('\n'));

  final TextEditingController title, from, to, items;
}

class _FollowUpEditorScreenState extends ConsumerState<FollowUpEditorScreen> {
  List<_BandEdit>? _bands;
  final _danger = TextEditingController();

  void _load() {
    if (_bands != null) return;
    final drafts = ref.read(followUpDraftsProvider);
    final live = ref.read(followUpBandsProvider);
    final settings = ref.read(followUpSettingsProvider);
    if (!drafts.hasValue || !live.hasValue || !settings.hasValue) return;
    final d = drafts.value;
    _bands = [for (final b in d?.bands ?? live.value!) _BandEdit(b)];
    _danger.text = (d?.dangerSigns ?? settings.value!.dangerSigns).join('\n');
  }

  Map<String, Object> _payload() => {
    'bands': [
      for (final b in _bands!)
        {
          'title': b.title.text.trim(),
          'fromMonths': int.tryParse(b.from.text) ?? 0,
          'toMonths': int.tryParse(b.to.text) ?? 0,
          'items': b.items.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        },
    ],
    'dangerSigns': _danger.text.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.watch(followUpDraftsProvider);
    ref.watch(followUpBandsProvider);
    ref.watch(followUpSettingsProvider);
    _load();
    final isDoctor = ref.watch(staffSessionProvider).value?.isDoctor ?? false;
    final api = ref.read(dashboardApiProvider);
    if (_bands == null) return const Center(child: CircularProgressIndicator());

    return DashPage(
      title: l10n.dashNavFollowUp,
      actions: [
        OutlinedButton(
          key: const Key('follow-up-save'),
          onPressed: () =>
              runAction(context, () => api.call('saveFollowUpDraft', _payload()), done: l10n.dashDraftSaved),
          child: Text(l10n.dashSaveDraft),
        ),
        if (isDoctor)
          FilledButton(
            key: const Key('follow-up-publish'),
            onPressed: () => runAction(context, () async {
              await api.call('saveFollowUpDraft', _payload());
              await api.call('publishFollowUp', {});
            }, done: l10n.dashPublished),
            child: Text(l10n.dashPublish),
          ),
      ],
      subtitle: l10n.dashDraftNote,
      showClinic: false,
      children: [
        DashCard(
          title: l10n.whenToCall,
          hint: l10n.dashOnePerLine,
          icon: Icons.warning_amber_rounded,
          tone: Tone.pink,
          child: TextField(
            key: const Key('danger-signs'),
            controller: _danger,
            maxLines: 5,
            decoration: dashInput(context),
          ),
        ),
        const SizedBox(height: 16),
        for (final (i, b) in _bands!.indexed) ...[
          DashCard(
            key: Key('band-$i'),
            title: b.title.text.isEmpty ? l10n.dashFollowUpBands : b.title.text,
            icon: Icons.checklist_rtl,
            tone: Tone.green,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: b.title,
                        decoration: InputDecoration(labelText: l10n.dashItemTitle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: b.from,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l10n.dashAgeFrom),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: b.to,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l10n.dashAgeTo),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.dashRemove,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => _bands!.removeAt(i)),
                    ),
                  ],
                ),
                TextField(
                  controller: b.items,
                  maxLines: 4,
                  decoration: InputDecoration(helperText: l10n.dashOnePerLine),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const Key('band-add'),
            onPressed: () => setState(
              () => _bands!.add(_BandEdit(const FollowUpBand(fromMonths: 0, toMonths: 1, title: '', items: []))),
            ),
            icon: const Icon(Icons.add),
            label: Text(l10n.dashAddBand),
          ),
        ),
      ],
    );
  }
}
