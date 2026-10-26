import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';

/// `followUp/{b}`: the follow-up list for an age band (doctor-owned, data-model.md).
class FollowUpBand {
  const FollowUpBand({
    required this.fromMonths,
    required this.toMonths,
    required this.title,
    required this.items,
    this.order = 0,
    this.dangerSigns = const [],
    this.proposed = false,
  });

  factory FollowUpBand.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> s) {
    final d = s.data()!;
    return FollowUpBand(
      fromMonths: (d['fromMonths'] as num).toInt(),
      toMonths: (d['toMonths'] as num).toInt(),
      title: d['title'] as String? ?? '',
      items: [for (final i in (d['items'] as List? ?? const [])) '$i'],
      order: (d['order'] as num?)?.toInt() ?? 0,
      dangerSigns: [for (final i in (d['dangerSigns'] as List? ?? const [])) '$i'],
      proposed: d['reviewStatus'] == 'proposed',
    );
  }

  /// «إمتى تتصلي بالدكتور» items for this age only, shown before the general ones.
  final List<String> dangerSigns;

  /// Researched for the demo and not yet approved by the doctor (`reviewStatus: proposed`).
  final bool proposed;

  /// The band covers fromMonths ≤ age < toMonths.
  final int fromMonths;
  final int toMonths;
  final String title;
  final List<String> items;
  final int order;
}

/// `settings/followUp`. Defaults apply when missing.
class FollowUpSettings {
  const FollowUpSettings({this.maxAgeMonths = 48, this.dangerSigns = const [], this.proposed = false});

  factory FollowUpSettings.fromMap(Map<String, dynamic>? d) => FollowUpSettings(
    maxAgeMonths: (d?['maxAgeMonths'] as num?)?.toInt() ?? 48,
    dangerSigns: [for (final i in (d?['dangerSigns'] as List? ?? const [])) '$i'],
    proposed: d?['reviewStatus'] == 'proposed',
  );

  final int maxAgeMonths;
  final List<String> dangerSigns;
  final bool proposed;
}

final followUpBandsProvider = StreamProvider<List<FollowUpBand>>(
  (ref) => ref
      .watch(firestoreProvider)
      .collection('followUp')
      .snapshots()
      .map((q) => q.docs.map(FollowUpBand.fromSnapshot).toList()..sort((a, b) => a.order.compareTo(b.order))),
);

final followUpSettingsProvider = StreamProvider<FollowUpSettings>(
  (ref) =>
      ref.watch(firestoreProvider).doc('settings/followUp').snapshots().map((s) => FollowUpSettings.fromMap(s.data())),
);
