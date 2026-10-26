import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';

/// Whether the animated intro may show. Tests turn it off: it covers the app and a tap skips it.
final splashEnabledProvider = Provider<bool>((ref) => true);

/// The animated intro after the native splash (docs/design/README.md "Splash and brand",
/// brand/splash_preview.gif): the icon scales in with a small bounce, the heart pops in, the baby
/// blinks, then the app name and the doctor's line fade in. At most 2.2 s, a tap skips it, the
/// phone's "reduce motion" skips it, and it shows once per cold start. Drawn with Flutter, no video.
class SplashIntro extends ConsumerStatefulWidget {
  const SplashIntro({super.key, required this.child});

  final Widget child;

  /// Once per process: a cold start shows it, returning from the background does not.
  static bool shownThisRun = false;

  static const duration = Duration(milliseconds: 2000);
  static const fadeOut = Duration(milliseconds: 200);

  @override
  ConsumerState<SplashIntro> createState() => _SplashIntroState();
}

class _SplashIntroState extends ConsumerState<SplashIntro> with TickerProviderStateMixin {
  late final _play = AnimationController(vsync: this, duration: SplashIntro.duration);
  late final _out = AnimationController(vsync: this, duration: SplashIntro.fadeOut);
  late bool _done = SplashIntro.shownThisRun || !ref.read(splashEnabledProvider);

  @override
  void initState() {
    super.initState();
    if (_done) return;
    SplashIntro.shownThisRun = true;
    _play.forward().whenComplete(_finish);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_done && MediaQuery.of(context).disableAnimations) {
      _play.stop();
      setState(() => _done = true);
    }
  }

  void _finish() {
    if (_done || _out.isAnimating) return;
    _out.forward().whenComplete(() {
      if (mounted) setState(() => _done = true);
    });
  }

  @override
  void dispose() {
    _play.dispose();
    _out.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    Animation<double> part(double from, double to, Curve curve) =>
        CurvedAnimation(parent: _play, curve: Interval(from, to, curve: curve));
    final icon = part(0, .3, Curves.easeOutBack);
    final heart = part(.32, .5, Curves.elasticOut);
    final blink = part(.5, .62, Curves.easeInOut);
    final words = part(.55, .8, Curves.easeOut);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        FadeTransition(
          opacity: ReverseAnimation(_out),
          child: GestureDetector(
            key: const Key('splash-intro'),
            behavior: HitTestBehavior.opaque,
            onTap: _finish,
            // A Material, so the texts get the theme's font (the intro sits above the Navigator).
            child: Material(
              color: dark ? const Color(0xFF0F1E2B) : const Color(0xFFF7F4EE),
              child: Center(
                child: AnimatedBuilder(
                  animation: _play,
                  builder: (context, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: icon.value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: .6 + .4 * icon.value,
                          child: CustomPaint(
                            size: const Size.square(132),
                            painter: _BabyIcon(heart: heart.value, blink: blink.value),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Opacity(
                        opacity: words.value,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - words.value)),
                          child: Column(children: [
                            Text(
                              l10n.appTitle,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: dark ? Colors.white : const Color(0xFF16324B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.splashDoctorLine,
                              style: TextStyle(fontSize: 13, color: dark ? const Color(0xFFB8C7D3) : const Color(0xFF5F6F7E)),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The app icon (assets/icon/app_icon_1024.png) drawn on a 100 × 100 grid, with the heart's pop
/// ([heart] 0–1, may overshoot) and a blink ([blink] 0–1, eyes squeeze shut at the middle).
class _BabyIcon extends CustomPainter {
  const _BabyIcon({required this.heart, required this.blink});

  final double heart;
  final double blink;

  static const navy = Color(0xFF16324B);
  static const pink = Color(0xFFF08AA3);
  static const cheek = Color(0xFFF7C1CE);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final square = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 100, 100), const Radius.circular(24));
    canvas.drawRRect(
      square.shift(const Offset(0, 3)),
      Paint()
        ..color = const Color(0x2216324B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      square,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8AC9E9), Color(0xFFCBE7EE), Color(0xFFF4CCD6)],
          stops: [0, .55, 1],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    canvas.drawCircle(const Offset(50, 53.5), 28.5, Paint()..color = Colors.white);

    final line = Paint()
      ..color = navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    // The curl on top.
    canvas.drawPath(
      Path()
        ..moveTo(49.4, 26)
        ..cubicTo(48, 19, 51, 16, 55, 16)
        ..cubicTo(59, 16, 60.5, 20, 58, 22.5)
        ..cubicTo(56, 24.2, 53.5, 22.8, 54.3, 20.8),
      line,
    );
    // Happy closed eyes; a blink squeezes them flat.
    final squeeze = 1 - .8 * math.sin(blink * math.pi);
    for (final x in [43.0, 57.0]) {
      canvas.save();
      canvas.translate(x, 51);
      canvas.scale(1, squeeze);
      canvas.drawPath(Path()..moveTo(-4.4, 1.6)..quadraticBezierTo(0, -3.4, 4.4, 1.6), line);
      canvas.restore();
    }
    for (final x in [36.4, 63.6]) {
      canvas.drawCircle(Offset(x, 59.5), 4, Paint()..color = cheek);
    }
    canvas.drawPath(Path()..moveTo(43.4, 62)..quadraticBezierTo(50, 68.5, 56.6, 62), line);
    // The heart pops in.
    if (heart > 0) {
      canvas.save();
      canvas.translate(75.2, 31.5);
      canvas.scale(heart);
      canvas.drawPath(
        Path()
          ..moveTo(0, 6.5)
          ..cubicTo(-9, 1, -7.5, -6.5, -3, -6.5)
          ..cubicTo(-1, -6.5, 0, -5, 0, -3.6)
          ..cubicTo(0, -5, 1, -6.5, 3, -6.5)
          ..cubicTo(7.5, -6.5, 9, 1, 0, 6.5)
          ..close(),
        Paint()..color = pink,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BabyIcon old) => old.heart != heart || old.blink != blink;
}
