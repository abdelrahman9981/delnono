import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/format/arabic_digits.dart';
import '../data/dashboard_api.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';

/// Other open files on the same number (009 FR-005): staff search by the number.
final _sameNumberProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, phone) async {
  final r = await ref.read(dashboardApiProvider).call('searchChildren', {'query': phone});
  return [for (final c in (r['children'] as List? ?? const [])) Map<String, dynamic>.from(c as Map)];
});

/// A file's record counts, through `openChildFile` (the opening is logged, as any file).
final _countsProvider = FutureProvider.autoDispose.family<(int, int, int), String>((ref, id) async {
  final f = await ref.read(dashboardApiProvider).call('openChildFile', {'childId': id});
  int n(String k) => (f[k] as List?)?.length ?? 0;
  return (n('measurements'), n('doses'), n('visits'));
});

/// The doctor merges two files of one child (009 US3, BRD FR-65): picks the other file on the same
/// number, chooses which one stays, sees both, and confirms. Returns the kept file's id.
class MergeDialog extends ConsumerStatefulWidget {
  const MergeDialog({super.key, required this.child, required this.counts});

  /// The open file: `id`, `name`, `birthDate`, `sex`, `guardianPhone`.
  final Map<String, dynamic> child;
  final (int, int, int) counts;

  @override
  ConsumerState<MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends ConsumerState<MergeDialog> {
  String? _otherId;
  late String _keepId = '${widget.child['id']}';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final thisId = '${widget.child['id']}';
    final others = ref.watch(_sameNumberProvider('${widget.child['guardianPhone']}'));
    final candidates = [for (final o in others.value ?? const <Map<String, dynamic>>[]) if (o['id'] != thisId) o];
    final other = candidates.where((o) => o['id'] == _otherId).firstOrNull;
    final otherCounts = _otherId == null ? null : ref.watch(_countsProvider(_otherId!)).value;

    Widget side(Map<String, dynamic> f, (int, int, int)? counts) {
      final keep = f['id'] == _keepId;
      return Container(
        key: Key('merge-side-${f['id']}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: keep ? c.greenSoft : c.surface,
          border: Border.all(color: keep ? c.green : c.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          StatusPill(keep ? l10n.dashMergeKeep : l10n.dashMergeClose, keep ? PillKind.ok : PillKind.noShow, dot: false),
          const SizedBox(height: 8),
          Text('${f['name']}', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('${f['birthDate']} · ${f['sex'] == 'female' ? l10n.sexFemale : l10n.sexMale}', style: TextStyle(color: c.muted)),
          if (counts != null)
            Text(
              l10n.dashRecordCounts(arabicDigits(counts.$1), arabicDigits(counts.$2), arabicDigits(counts.$3)),
              style: TextStyle(fontSize: 12, color: c.muted),
            ),
        ]),
      );
    }

    return AlertDialog(
      title: Text(l10n.dashMergeFile),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text(l10n.dashMergeHint, style: TextStyle(fontSize: 13, color: c.muted)),
            const SizedBox(height: 12),
            if (others.isLoading) const Center(child: CircularProgressIndicator()),
            if (others.hasValue && candidates.isEmpty) Text(l10n.dashMergeNoOthers, key: const Key('merge-none')),
            for (final o in candidates)
              ListTile(
                key: Key('merge-pick-${o['id']}'),
                selected: o['id'] == _otherId,
                leading: Icon(o['id'] == _otherId ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text('${o['name']}'),
                subtitle: Text('${o['birthDate']}'),
                onTap: () => setState(() {
                  _otherId = '${o['id']}';
                  _keepId = thisId;
                }),
              ),
            if (other != null) ...[
              const SizedBox(height: 12),
              SegmentSwitch<String>(
                key: const Key('merge-keep'),
                options: [(thisId, '${widget.child['name']}'), ('${other['id']}', '${other['name']}')],
                value: _keepId,
                onChanged: (v) => setState(() => _keepId = v),
              ),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: [
                SizedBox(width: 260, child: side(widget.child, widget.counts)),
                SizedBox(width: 260, child: side(other, otherCounts)),
              ]),
            ],
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.dashClose)),
        FilledButton(
          key: const Key('merge-confirm'),
          onPressed: other == null || _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  final closeId = _keepId == thisId ? '${other['id']}' : thisId;
                  final ok = await runAction(
                    context,
                    () => ref.read(dashboardApiProvider).call('mergeChildren', {'keepId': _keepId, 'closeId': closeId}),
                    done: l10n.dashMerged,
                  );
                  if (!context.mounted) return;
                  if (ok) {
                    Navigator.pop(context, _keepId);
                  } else {
                    setState(() => _busy = false);
                  }
                },
          child: Text(l10n.dashMergeConfirm),
        ),
      ],
    );
  }
}
