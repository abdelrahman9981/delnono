import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../core/content/youtube.dart';

/// Builds the in-app player; widget tests replace it (no WebView there).
typedef VideoPlayerBuilder = Widget Function(String youtubeId, VoidCallback onError);

final videoPlayerBuilderProvider = Provider<VideoPlayerBuilder>(
  (ref) => (id, onError) => ShortPlayer(youtubeId: id, onError: onError),
);

/// Opens the video in the YouTube app (or the browser when it is not installed).
final openYoutubeProvider = Provider<Future<bool> Function(String youtubeId)>(
  (ref) => (id) => launchUrl(youtubeWatchUrl(id), mode: LaunchMode.externalApplication),
);

/// A YouTube Short in the IFrame player, vertical 9:16 (006 R1). Calls [onError] when YouTube
/// refuses to play it here (not embeddable, private, removed).
class ShortPlayer extends StatefulWidget {
  const ShortPlayer({super.key, required this.youtubeId, required this.onError});

  final String youtubeId;
  final VoidCallback onError;

  @override
  State<ShortPlayer> createState() => _ShortPlayerState();
}

class _ShortPlayerState extends State<ShortPlayer> {
  late final _controller = YoutubePlayerController.fromVideoId(
    videoId: widget.youtubeId,
    autoPlay: true,
    params: const YoutubePlayerParams(
      showFullscreenButton: false,
      playsInline: true,
      strictRelatedVideos: true,
      interfaceLanguage: 'ar',
    ),
  );
  StreamSubscription<YoutubePlayerValue>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _controller.listen((v) {
      if (v.error != YoutubeError.none) widget.onError();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => YoutubePlayer(
    controller: _controller,
    aspectRatio: 9 / 16,
    autoFullScreen: false,
    enableFullScreenOnVerticalDrag: false,
    backgroundColor: Colors.black,
  );
}
