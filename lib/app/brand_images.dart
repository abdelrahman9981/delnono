import 'package:flutter/widgets.dart' show Alignment;

/// The clinic's real photos (docs/design/README.md "Photos"), registered in pubspec.yaml.
abstract final class BrandImages {
  /// The doctor, for the Home and Welcome hero cards (960 × 676; his face is right of centre).
  static const doctorHero = 'assets/images/doctor_hero.jpg';

  /// The doctor, square, shown round: clinic card and dashboard sign-in.
  static const doctorAvatar = 'assets/images/doctor_avatar.jpg';

  /// The Moqattam (main) clinic's waiting room (1280 × 721).
  static const waitingRoom = 'assets/images/clinic_waiting_room.jpg';

  /// The second clinic: an illustration until a real photo arrives.
  static const clinic2Illustration = 'assets/images/clinic2_illustration.jpg';

  /// Keeps the doctor's face in frame when the hero is cropped to a phone's width.
  static const doctorHeroFocus = Alignment(0.3, -0.4);
}
