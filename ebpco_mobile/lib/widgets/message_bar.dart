import 'package:flutter/material.dart';

/// How long a message stays on screen: long enough to read. Flutter's fixed 4s
/// took a two-sentence one ("You already had … in My Documents, so that copy
/// was used. Next time, …") away before it was read. About a quarter of a
/// second a word, from 4s up to 12s.
Duration readingTime(String message) {
  final words = message.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
  return Duration(milliseconds: (1500 + words * 280).clamp(4000, 12000));
}

/// A message for [text] that stays long enough to read it.
SnackBar messageBar(String text) => SnackBar(content: Text(text), duration: readingTime(text));
