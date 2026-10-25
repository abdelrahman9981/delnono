import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../app/theme.dart';
import '../data/local_notifier.dart';
import '../data/notification_prefs.dart';
import 'notifications_screen.dart' show notificationPermissionProvider;

/// "Remind me before the visit?" on the first booking success (007 FR-006): asks for the phone's
/// permission only when the guardian taps it, and only until asked once.
class ReminderOffer extends ConsumerWidget {
  const ReminderOffer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = Theme.of(context).extension<AppColors>()!;
    final asked = ref.watch(notificationPrefsProvider).value?.askedPermission ?? true;
    final granted = ref.watch(notificationPermissionProvider).value ?? true;
    if (asked || granted) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Card(
        key: const Key('reminder-offer'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: c.blueSoft, shape: BoxShape.circle),
              child: Icon(Icons.notifications_active_outlined, color: c.blue, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(child: Text(l10n.notifAskBody, style: Theme.of(context).textTheme.titleSmall)),
            const SizedBox(width: 8),
            TextButton(
              key: const Key('reminder-offer-yes'),
              onPressed: () async {
                await ref.read(localNotifierProvider).requestPermission();
                await ref.read(notificationPrefsProvider.notifier).setAskedPermission();
                ref.invalidate(notificationPermissionProvider);
              },
              child: Text(l10n.notifAskButton),
            ),
          ]),
        ),
      ),
    );
  }
}
