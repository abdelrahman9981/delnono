import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_localizations.dart';
import '../../app/theme.dart';
import '../../core/format/age.dart';
import '../data/dashboard_api.dart';
import '../router.dart';
import '../widgets/dash_page.dart';

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
    return DashPage(
      title: l10n.dashNavChildren,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('child-search'),
                controller: _query,
                decoration: InputDecoration(labelText: l10n.dashSearchHint, prefixIcon: const Icon(Icons.search)),
                onSubmitted: (_) => _search(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              key: const Key('child-search-go'),
              onPressed: _busy ? null : _search,
              child: Text(l10n.dashSearch),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_results != null && _results!.isEmpty) Text(l10n.dashNoResults, style: TextStyle(color: c.muted)),
        for (final r in _results ?? const <Map<String, dynamic>>[])
          Card(
            child: ListTile(
              key: Key('child-result-${r['id']}'),
              title: Text('${r['name']}'),
              subtitle: Text('${arabicAge('${r['birthDate']}', l10n)} · ${r['guardianPhone'] ?? ''}'),
              // chevron_right mirrors with the text direction: it points left (‹, forward) in RTL.
              trailing: Icon(Icons.chevron_right, color: c.muted),
              onTap: () => context.go('${DashRoutes.children}/${r['id']}'),
            ),
          ),
      ],
    );
  }
}
