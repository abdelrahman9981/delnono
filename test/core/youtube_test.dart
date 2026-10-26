import 'package:delnono/core/content/youtube.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the id from every YouTube link form (006 R3)', () {
    for (final link in [
      'https://www.youtube.com/watch?v=WjbDIjEH38U',
      'https://youtube.com/watch?feature=share&v=WjbDIjEH38U&t=3',
      'https://m.youtube.com/watch?v=WjbDIjEH38U',
      'https://youtu.be/WjbDIjEH38U?si=abc',
      'https://youtube.com/shorts/WjbDIjEH38U?feature=share',
      'https://www.youtube.com/embed/WjbDIjEH38U',
      'https://www.youtube-nocookie.com/embed/WjbDIjEH38U',
      'https://www.youtube.com/live/WjbDIjEH38U',
      '  https://youtube.com/shorts/WjbDIjEH38U  ',
    ]) {
      expect(youtubeIdFrom(link), 'WjbDIjEH38U', reason: link);
    }
    expect(youtubeIdFrom('https://youtu.be/-MGXzWjohFU'), '-MGXzWjohFU');
  });

  test('refuses other sites and broken ids', () {
    for (final link in [
      'https://vimeo.com/123456',
      'https://example.com/watch?v=WjbDIjEH38U',
      'https://youtube.com.evil.com/watch?v=WjbDIjEH38U',
      'https://www.youtube.com/watch?v=short',
      'https://www.youtube.com/@doctor',
      'https://www.youtube.com/channel/UC47gpnTXG0ki52IwM85Oqdg',
      'WjbDIjEH38U',
      'javascript:alert(1)',
      '',
    ]) {
      expect(youtubeIdFrom(link), isNull, reason: link);
    }
  });

  test('thumbnail and watch links', () {
    expect(youtubeThumb('WjbDIjEH38U'), 'https://i.ytimg.com/vi/WjbDIjEH38U/hqdefault.jpg');
    expect(youtubeWatchUrl('WjbDIjEH38U').toString(), 'https://www.youtube.com/shorts/WjbDIjEH38U');
  });
}
