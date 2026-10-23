import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens links outside the app. A provider so tests can record calls.
abstract interface class ExternalLinks {
  /// Opens a WhatsApp chat with [e164]: the app if installed, otherwise the web chat.
  Future<bool> openWhatsApp(String e164);
}

class UrlLauncherLinks implements ExternalLinks {
  const UrlLauncherLinks();

  @override
  Future<bool> openWhatsApp(String e164) async {
    final digits = e164.replaceAll(RegExp(r'\D'), '');
    final app = Uri.parse('whatsapp://send?phone=$digits');
    if (await canLaunchUrl(app) && await launchUrl(app)) return true;
    return launchUrl(Uri.parse('https://wa.me/$digits'), mode: LaunchMode.externalApplication);
  }
}

final externalLinksProvider = Provider<ExternalLinks>((ref) => const UrlLauncherLinks());
