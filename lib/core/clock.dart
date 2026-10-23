import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef Clock = DateTime Function();

/// Current time; overridden in tests.
final clockProvider = Provider<Clock>((ref) => DateTime.now);
