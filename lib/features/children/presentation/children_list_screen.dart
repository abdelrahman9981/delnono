import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/route_guard.dart';
import '../../../app/theme.dart';
import '../../../core/format/age.dart';
import '../../account/presentation/account_button.dart';
import '../data/children_repository.dart';

/// The guardian's children (`/children`, the "My child" tab). The full child profile with
/// vaccines and growth comes in feature 003.
class ChildrenListScreen extends ConsumerWidget {
  const ChildrenListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final c = Theme.of(context).extension<AppColors>()!;
    final children = ref.watch(childrenProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenChildren),
        automaticallyImplyLeading: false,
        actions: const [AccountButton()],
      ),
      body: SafeArea(
        child: children.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
          data: (list) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              if (list.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.child_care_outlined, size: 48, color: c.muted),
                      const SizedBox(height: 10),
                      Text(l10n.childrenEmpty, style: text.bodyLarge?.copyWith(color: c.muted)),
                    ],
                  ),
                ),
              for (final child in list) ...[
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: CircleAvatar(
                      backgroundColor: child.sex == Sex.female ? c.pinkSoft : c.blueSoft,
                      foregroundColor: child.sex == Sex.female ? c.pink : c.blue,
                      child: Text(child.name.characters.first, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    title: Text(child.name, style: text.titleSmall),
                    subtitle: Text(arabicAge(child.birthDate, l10n), style: text.bodySmall),
                    trailing: Icon(Icons.chevron_left, color: c.muted),
                    onTap: () => context.go('${Routes.children}/${child.id}'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.go(Routes.childrenAdd),
                icon: const Icon(Icons.add),
                label: Text(l10n.childrenAdd),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
