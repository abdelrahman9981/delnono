/// YouTube links (006 R3, D-50): the same rule as the server's `youtubeId`.
library;

const _hosts = {
  'youtube.com',
  'www.youtube.com',
  'm.youtube.com',
  'music.youtube.com',
  'youtube-nocookie.com',
  'www.youtube-nocookie.com',
};
final _id = RegExp(r'^[A-Za-z0-9_-]{11}$');

/// The 11-character video id of a YouTube link, or null for anything else.
String? youtubeIdFrom(String link) {
  final url = Uri.tryParse(link.trim());
  if (url == null || (url.scheme != 'https' && url.scheme != 'http')) return null;
  final host = url.host.toLowerCase();
  final parts = url.pathSegments.where((p) => p.isNotEmpty).toList();
  String? id;
  if (host == 'youtu.be') {
    id = parts.firstOrNull;
  } else if (_hosts.contains(host) && parts.isNotEmpty) {
    if (parts[0] == 'watch') {
      id = url.queryParameters['v'];
    } else if (const {'shorts', 'embed', 'live', 'v'}.contains(parts[0])) {
      id = parts.length > 1 ? parts[1] : null;
    }
  }
  return id != null && _id.hasMatch(id) ? id : null;
}

/// The video's thumbnail on YouTube's image server (no storage of our own).
String youtubeThumb(String id) => 'https://i.ytimg.com/vi/$id/hqdefault.jpg';

/// Opens in the YouTube app when installed.
Uri youtubeWatchUrl(String id) => Uri.parse('https://www.youtube.com/shorts/$id');
