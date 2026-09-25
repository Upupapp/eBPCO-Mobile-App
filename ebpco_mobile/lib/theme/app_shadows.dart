import 'package:flutter/material.dart';

/// Shadow tokens, tinted from the web portals' own `--shadow-sm`/`--shadow-md`
/// (`rgba(20, 20, 40, ...)`) rather than a color invented here. [card] and
/// [cardHover] mirror those two directly; [float] is this app's own
/// stronger tier for a raised element (the shell's launcher pill, a sheet),
/// built from the same tint at a higher alpha/blur rather than a different
/// color family — there is no third web token to copy for that role.
class AppShadows {
  AppShadows._();

  static const _tint = Color(0xFF141428); // rgb(20, 20, 40)

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A141428), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> cardHover = [
    BoxShadow(color: Color(0x14141428), blurRadius: 22, offset: Offset(0, 10)),
  ];

  static const List<BoxShadow> float = [
    BoxShadow(color: Color(0x33141428), blurRadius: 32, offset: Offset(0, 12), spreadRadius: -8),
  ];

  static const Color tint = _tint;
}
