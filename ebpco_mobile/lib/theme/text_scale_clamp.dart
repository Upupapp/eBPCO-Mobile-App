import 'package:flutter/material.dart';

/// Bounds the phone's text-size setting for the whole app (merged from
/// eBPCOMobile, 2026-10-01).
///
/// Unbounded, iOS's largest accessibility sizes (around 3x) overflow fixed
/// layouts, and a phone shrunk below 0.9x makes labels unreadable. Between
/// [minScale] and [maxScale] the setting is honoured as it is: a citizen who
/// needs 200% gets 200%, which is the most Android's own font size setting
/// offers.
class TextScaleClamp extends StatelessWidget {
  static const double minScale = 0.9;
  static const double maxScale = 2.0;

  final Widget child;

  const TextScaleClamp({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context).clamp(minScaleFactor: minScale, maxScaleFactor: maxScale);
    return MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: scaler), child: child);
  }
}
