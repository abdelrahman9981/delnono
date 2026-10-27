import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../core/format/arabic_digits.dart';
import '../../features/child_profile/data/vaccine_schedule_repository.dart';
import '../data/dashboard_api.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';

/// The doctor's vaccine list and basic schedule (005 US5, FR-040, Principle II). Approving sets the
/// review date shown to families and clears the placeholder marks.
class VaccinesAdminScreen extends ConsumerStatefulWidget {
  const VaccinesAdminScreen({super.key});

  @override
  ConsumerState<VaccinesAdminScreen> createState() => _VaccinesAdminScreenState();
}

class _VaccinesAdminScreenState extends ConsumerState<VaccinesAdminScreen> {
  final _names = <String, TextEditingController>{};
  final _source = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    for (final c in [..._names.values, _source]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save({required bool approve}) async {
    final l10n = AppLocalizations.of(context);
    await runAction(
      context,
      () => ref.read(dashboardApiProvider).call('updateCatalogue', {
        'vaccines': [
          for (final e in _names.entries) {'id': e.key, 'name': e.value.text.trim()},
        ],
        'source': _source.text.trim(),
        'approve': approve,
      }),
      done: approve ? l10n.dashApproved : l10n.dashSaved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalogue = ref.watch(vaccineCatalogueProvider).value ?? const <String, VaccineInfo>{};
    final schedule = ref.watch(vaccineScheduleProvider).value ?? const <ScheduleEntry>[];
    final info = ref.watch(vaccineSettingsProvider).value;
    if (!_loaded && catalogue.isNotEmpty && info != null) {
      _loaded = true;
      for (final v in catalogue.values) {
        _names[v.id] = TextEditingController(text: v.name);
      }
      _source.text = info.source;
    }

    return DashPage(
      title: l10n.dashNavVaccines,
      actions: [
        OutlinedButton(key: const Key('vaccines-save'), onPressed: () => _save(approve: false), child: Text(l10n.save)),
        FilledButton(
          key: const Key('vaccines-approve'),
          onPressed: () => _save(approve: true),
          child: Text(l10n.dashApprove),
        ),
      ],
      showClinic: false,
      children: [
        DashCard(
          title: l10n.dashScheduleSource,
          hint: info?.reviewedOn == null ? null : l10n.vaccinesReviewed('${info!.reviewedOn}'),
          icon: Icons.verified_outlined,
          tone: Tone.green,
          child: TextField(key: const Key('vaccines-source'), controller: _source, decoration: dashInput(context)),
        ),
        const SizedBox(height: 16),
        DashCard(
          title: l10n.dashCatalogue,
          icon: Icons.vaccines_outlined,
          padding: EdgeInsets.zero,
          child: DashTable(
            headers: [l10n.dashColVaccine, l10n.dashCategory],
            flex: const [3, 2],
            rows: [
              for (final v in catalogue.values)
                DashRow(key: Key('vaccine-${v.id}'), cells: [
                  TextField(controller: _names[v.id], decoration: dashInput(context)),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    StatusPill(
                      v.kind == VaccineKind.additional ? l10n.additionalBadge : l10n.vaccinesBasic,
                      v.kind == VaccineKind.additional ? PillKind.walkIn : PillKind.info,
                      dot: false,
                    ),
                    if (v.proposed) ProposedBadge(key: Key('proposed-vaccine-${v.id}')),
                  ]),
                ]),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DashCard(
          title: l10n.vaccinesBasic,
          icon: Icons.event_repeat_outlined,
          tone: Tone.yellow,
          padding: EdgeInsets.zero,
          child: DashTable(
            headers: [l10n.dashColVaccine, l10n.dashColDose, l10n.dashColDate],
            flex: const [3, 1, 3],
            rows: [
              for (final e in schedule)
                DashRow(key: Key('schedule-${e.id}'), cells: [
                  Text(catalogue[e.vaccineId]?.name ?? e.vaccineId, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(arabicDigits(e.dose)),
                  Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text('${e.ageLabel} · ${l10n.dashDueMonths(arabicDigits(e.dueAge.months))}'),
                    if (e.proposed) ProposedBadge(key: Key('proposed-schedule-${e.id}')),
                  ]),
                ]),
            ],
          ),
        ),
      ],
    );
  }
}
