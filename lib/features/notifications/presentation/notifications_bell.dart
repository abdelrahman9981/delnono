import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/route_guard.dart';
import '../../../core/format/arabic_digits.dart';
import '../../auth/data/auth_repository.dart';
import '../data/reminder_sync.dart';

/// The Home bell with the unread count (figma/home.jpg; 007 FR-008). Signed-in guardians only.
class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authStateProvider).value == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final count = ref.watch(unreadCountProvider);
    return IconButton(
      key: const Key('notifications-bell'),
      tooltip: count == 0 ? l10n.notifTitle : l10n.notifUnreadCount(arabicDigits(count)),
      onPressed: () => context.push(Routes.notifications),
      icon: Badge(
        key: const Key('notifications-badge'),
        isLabelVisible: count > 0,
        label: Text(count > 9 ? '${arabicDigits(9)}+' : arabicDigits(count)),
        child: const Icon(Icons.notifications_none),
      ),
    );
  }
}
