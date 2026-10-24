import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../../auth/data/auth_repository.dart';

/// True while the app reads from its offline cache (research R7). Watches the guardian document's
/// metadata; reports offline only after 2 s from the cache, so a normal start (cache first, then the
/// server) does not flash the note.
final offlineProvider = StreamProvider<bool>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(false);
  final out = StreamController<bool>();
  Timer? pending;
  final sub = ref.watch(firestoreProvider).doc('guardians/$uid').snapshots(includeMetadataChanges: true).listen((s) {
    pending?.cancel();
    if (s.metadata.isFromCache) {
      pending = Timer(const Duration(seconds: 2), () => out.add(true));
    } else {
      out.add(false);
    }
  }, onError: (Object _) {});
  ref.onDispose(() {
    pending?.cancel();
    sub.cancel();
    out.close();
  });
  return out.stream;
});
