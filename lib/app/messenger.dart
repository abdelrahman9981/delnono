import 'package:flutter/material.dart';

/// App-wide messenger, so a message survives the navigation the router guard does right after an
/// action (for example linking children moves the guardian on).
final appMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppMessage(String message) {
  appMessengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 6)));
}
