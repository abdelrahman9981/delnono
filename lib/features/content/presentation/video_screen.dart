import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_localizations.dart';
import '../application/connectivity.dart';
import '../data/content_repository.dart';
import 'video_player.dart';

/// A Short in a full-screen vertical player (owner: 9:16, not a 16:9 box). When YouTube refuses to
/// play it here, or offline, a clear message; «شوفي الفيديو على يوتيوب» is always offered (D-50).
class VideoScreen extends ConsumerStatefulWidget {
  const VideoScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends ConsumerState<VideoScreen> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = ref.watch(publishedContentProvider);
    final item = content.value?.where((i) => i.id == widget.id && i.isVideo).firstOrNull;
    final online = ref.watch(onlineProvider).value ?? true;
    const white = TextStyle(color: Colors.white, height: 1.5);

    Widget message(Key key, String text) => Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 44),
        const SizedBox(height: 12),
        Text(text, key: key, textAlign: TextAlign.center, style: white.copyWith(fontSize: 16)),
      ]),
    );

    final Widget body;
    if (!content.hasValue) {
      body = const CircularProgressIndicator(color: Colors.white);
    } else if (item == null) {
      body = message(const Key('content-not-found'), l10n.contentNotFound);
    } else if (!online) {
      body = message(const Key('video-offline'), l10n.contentVideoOffline);
    } else if (_failed) {
      body = message(const Key('video-unavailable'), l10n.contentVideoUnavailable);
    } else {
      body = AspectRatio(
        aspectRatio: 9 / 16,
        child: ref.watch(videoPlayerBuilderProvider)(item.youtubeId!, () {
          if (mounted) setState(() => _failed = true);
        }),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        // The theme's title style has its own (dark) colour; on this black screen it must be white.
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
        title: Text(item?.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: Center(key: const Key('video-stage'), child: body)),
          if (item != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(item.title, style: white.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('open-youtube'),
                  // The theme fills outlined buttons with the light surface; here it stays transparent.
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  onPressed: () => ref.read(openYoutubeProvider)(item.youtubeId!),
                  icon: const Icon(Icons.open_in_new),
                  label: Text(l10n.contentOpenYoutube),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}
