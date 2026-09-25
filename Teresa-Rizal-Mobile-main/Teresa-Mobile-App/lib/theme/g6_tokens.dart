import 'package:flutter/material.dart';

import 'soft_widget.dart';

/// Pack F sizes. Screens reference these so a raw `fontSize:` literal
/// does not land outside the theme.
class G6Type {
  G6Type._();

  static const px9 = 9.0;
  static const px9_5 = 9.5;
  static const px10 = 10.0;
  static const px11 = 11.0;
  static const px12 = 12.0;
  static const px13 = 13.0;
  static const px14 = 14.0;
  static const px16 = 16.0;
  static const px17 = 17.0;
  static const px18 = 18.0;
  static const px20 = 20.0;
  static const px21 = 21.0;
}

/// Pack F colours that are not already a [SoftColors] token.
/// White-alpha stops are the card glass; cream and gold ink are the
/// pending rail. Hex stays in the theme so the screens cannot drift.
class G6Palette {
  G6Palette._();

  static const cream = Color(0xFFFFF6E0);
  static const goldInk = Color(0xFF7A5600);
  static const mockInk = Color(0xFF3D2A00);
  static const mist = Color(0xFFE7EEF8);
  static const ice = Color(0xFFA8ECF6);
  static const lilac = Color(0xFFD9CCFF);
  static const lightGold = Color(0xFFFFE09A);

  static const ink90 = Color(0xE61A2336);
  static const navyClear = Color(0x00101846);
  static const navyStrip = Color(0x47101846);
  static const cardShadow = Color(0x241E3C78);
  static const hairline = Color(0x1F1E3C78);
  static const scrimShadow = Color(0x40142850);
  static const liveGlow = Color(0x387EF0FF);

  static const white8 = Color(0x14FFFFFF);
  static const white18 = Color(0x2EFFFFFF);
  static const white20 = Color(0x33FFFFFF);
  static const white55 = Color(0x8CFFFFFF);
  static const white62 = Color(0x9EFFFFFF);
  static const white72 = Color(0xB8FFFFFF);
  static const white76 = Color(0xC2FFFFFF);
  static const white78 = Color(0xC7FFFFFF);
  static const white80 = Color(0xCCFFFFFF);
  static const white82 = Color(0xD1FFFFFF);
  static const white85 = Color(0xD9FFFFFF);
  static const white86 = Color(0xDBFFFFFF);
  static const white92 = Color(0xEBFFFFFF);

  static const keyBg = Color(0xFFD8DDE6);
  static const keyWide = Color(0xFFC5CCD8);
  static const keyLine = Color(0xFFC1C8D4);
}
