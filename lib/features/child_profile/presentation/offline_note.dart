import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../../../core/widgets/notice.dart';
import '../data/offline_status.dart';

/// "إنتي أوفلاين · دي آخر بيانات اتحملت" while the profile is read from the cache (FR-022, US6).
class OfflineNote extends ConsumerWidget {
  const OfflineNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(offlineProvider).value != true) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Notice(
        AppLocalizations.of(context).offlineBanner,
        key: const Key('offline-note'),
        kind: NoticeKind.warn,
        icon: Icons.cloud_off_outlined,
      ),
    );
  }
}
