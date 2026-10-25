import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/format/age.dart';
import '../../core/format/arabic_digits.dart';
import '../data/dashboard_api.dart';
import '../router.dart';
import '../widgets/dash_page.dart';
import '../widgets/dash_ui.dart';

/// Find a child by name or the guardian's phone (005 FR-013). Opening the file is logged.
class ChildrenSearchScreen extends ConsumerStatefulWidget {
  const ChildrenSearchScreen({super.key});

  @override
  ConsumerState<ChildrenSearchScreen> createState() => _ChildrenSearchScreenState();
}

class _ChildrenSearchScreenState extends ConsumerState<ChildrenSearchScreen> {
  final _query = TextEditingController();
  List<Map<String, dynamic>>? _results;
  bool _busy = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_query.text.trim().length < 2) return;
    setState(() => _busy = true);
    await runAction(context, () async {
      final r = await ref.read(dashboardApiProvider).call('searchChildren', {'query': _query.text.trim()});
      _results = [for (final c in (r['children'] as List? ?? const [])) Map<String, dynamic>.from(c as Map)];
    });
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final results = _results ?? const <Map<String, dynamic>>[];
    return DashPage(
      title: l10n.dashNavChildren,
      subtitle: l10n.dashChildFileAudited,
      children: [
        DashCard(
          title: l10n.dashSearch,
          icon: Icons.search,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('child-search'),
                  controller: _query,
                  decoration: dashInput(context, hint: l10n.dashSearchHint).copyWith(prefixIcon: const Icon(Icons.search)),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(key: const Key('child-search-go'), onPressed: _busy ? null : _search, child: Text(l10n.dashSearch)),
            ],
          ),
        ),
        if (_results != null) ...[
          const SizedBox(height: 16),
          DashCard(
            title: l10n.dashResultsCount(arabicDigits(results.length)),
            icon: Icons.child_care_outlined,
            tone: Tone.pink,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (results.isEmpty)
                Padding(padding: const EdgeInsets.all(14), child: Text(l10n.dashNoResults, style: TextStyle(color: c.muted))),
              for (final (i, r) in results.indexed) ...[
                if (i > 0) Divider(height: 1, color: c.border),
                ListTile(
                  key: Key('child-result-${r['id']}'),
                  leading: InitialAvatar('${r['name']}', tone: r['sex'] == 'female' ? Tone.pink : Tone.blue),
                  title: Text('${r['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${arabicAge('${r['birthDate']}', l10n)} · ${r['guardianPhone'] ?? ''}'),
                  // chevron_right mirrors with the text direction: it points left (‹, forward) in RTL.
                  trailing: Icon(Icons.chevron_right, color: c.muted),
                  onTap: () => context.go('${DashRoutes.children}/${r['id']}'),
                ),
              ],
            ]),
          ),
        ],
      ],
    );
  }
}
