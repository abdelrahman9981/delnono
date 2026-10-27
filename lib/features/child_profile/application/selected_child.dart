import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/private_files.dart';
import '../../children/data/children_repository.dart';

/// Keeps the last selected child on the device (research R8).
abstract interface class SelectedChildStore {
  Future<String?> read();
  Future<void> write(String childId);
}

/// A one-line file among the app's private files (deleted on sign-out).
class FileSelectedChildStore implements SelectedChildStore {
  const FileSelectedChildStore();

  Future<File> get _file async => File('${(await PrivateFiles.dir('profile')).path}/selected_child');

  @override
  Future<String?> read() async {
    try {
      final f = await _file;
      if (!await f.exists()) return null;
      final id = (await f.readAsString()).trim();
      return id.isEmpty ? null : id;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String childId) async {
    try {
      await (await _file).writeAsString(childId);
    } catch (_) {}
  }
}

/// The web demo keeps it in browser storage, cleared on sign-out like the files (PrivateFiles).
class PrefsSelectedChildStore implements SelectedChildStore {
  const PrefsSelectedChildStore();

  static const _key = '${PrivateFiles.webPrefix}selected_child';

  @override
  Future<String?> read() async {
    try {
      return await SharedPreferencesAsync().getString(_key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String childId) async {
    try {
      await SharedPreferencesAsync().setString(_key, childId);
    } catch (_) {}
  }
}

final selectedChildStoreProvider = Provider<SelectedChildStore>(
  (ref) => kIsWeb ? const PrefsSelectedChildStore() : const FileSelectedChildStore(),
);

/// The child id the guardian picked last, or null until one is picked or loaded.
class SelectedChildController extends Notifier<String?> {
  @override
  String? build() {
    ref.read(selectedChildStoreProvider).read().then((id) {
      if (id != null && state == null) state = id;
    });
    return null;
  }

  void select(String childId) {
    state = childId;
    ref.read(selectedChildStoreProvider).write(childId);
  }
}

final selectedChildIdProvider = NotifierProvider<SelectedChildController, String?>(SelectedChildController.new);

/// The child shown on "طفلي": the selected one while it is still linked, else the first child.
final currentChildProvider = Provider<Child?>((ref) {
  final children = ref.watch(childrenProvider).value ?? const <Child>[];
  if (children.isEmpty) return null;
  final id = ref.watch(selectedChildIdProvider);
  return children.firstWhere((c) => c.id == id, orElse: () => children.first);
});
