import 'package:flutter/material.dart';

/// Shadow tokens translated from the Web Admin's `--shadow-card`,
/// `--shadow-card-hover`, and `--shadow-float` CSS variables.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 8, offset: Offset(0, 1), spreadRadius: -2),
  ];

  static const List<BoxShadow> cardHover = [
    BoxShadow(color: Color(0x1F0F172A), blurRadius: 16, offset: Offset(0, 4), spreadRadius: -4),
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 6, offset: Offset(0, 2), spreadRadius: -2),
  ];

  static const List<BoxShadow> float = [
    BoxShadow(color: Color(0x2E0F172A), blurRadius: 32, offset: Offset(0, 12), spreadRadius: -8),
  ];
}
