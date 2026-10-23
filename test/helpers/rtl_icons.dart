import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

enum Pointing { left, right }

final _drawnLeft = {
  Icons.chevron_left,
  Icons.arrow_back,
  Icons.arrow_back_ios,
  Icons.arrow_back_ios_new,
  Icons.navigate_before,
  Icons.keyboard_arrow_left,
  Icons.arrow_left,
};
final _drawnRight = {
  Icons.chevron_right,
  Icons.arrow_forward,
  Icons.arrow_forward_ios,
  Icons.navigate_next,
  Icons.keyboard_arrow_right,
  Icons.arrow_right,
};

/// Where a directional icon actually points on screen: its drawn direction, flipped when the
/// icon mirrors with the text direction and the text direction is RTL. Null for other icons.
Pointing? pointing(Element element) {
  final icon = (element.widget as Icon).icon;
  if (icon == null) return null;
  final drawn = _drawnLeft.contains(icon) ? Pointing.left : (_drawnRight.contains(icon) ? Pointing.right : null);
  if (drawn == null) return null;
  final mirrored = icon.matchTextDirection && Directionality.of(element) == TextDirection.rtl;
  if (!mirrored) return drawn;
  return drawn == Pointing.left ? Pointing.right : Pointing.left;
}

bool _insideBackButton(Element e) {
  var inside = false;
  e.visitAncestorElements((a) {
    if (a.widget is BackButton || a.widget is BackButtonIcon) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside;
}

/// In RTL, back icons must point right and every other chevron or arrow (forward) must point left.
/// Returns a description of each icon that points the wrong way.
List<String> wrongWayIcons(WidgetTester tester) {
  final wrong = <String>[];
  for (final e in find.byType(Icon).evaluate()) {
    if (Directionality.of(e) != TextDirection.rtl) continue;
    final p = pointing(e);
    if (p == null) continue;
    final back = _insideBackButton(e);
    final expected = back ? Pointing.right : Pointing.left;
    if (p != expected) {
      wrong.add('${back ? 'back' : 'forward'} icon ${(e.widget as Icon).icon} points ${p.name}');
    }
  }
  return wrong;
}
