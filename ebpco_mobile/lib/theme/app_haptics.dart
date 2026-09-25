import 'package:flutter/services.dart';

/// Centralized haptic feedback, named by *when it's allowed to fire* rather
/// than by the underlying Flutter API. House rules, ported as-is from the
/// design reference (Teresa-Rizal-Mobile) because they're sound for any app:
///   - never on keystrokes or passive scrolling
///   - never repeatedly on a failed/retried action
///   - never as the *only* signal a state changed — always paired with a
///     visible change (a chip color, a new screen, a status update)
class AppHaptics {
  AppHaptics._();

  static bool enabled = true;

  /// Low-stakes selections: tab taps, filter chips, radio/segmented picks.
  static void selection() => _run(HapticFeedback.selectionClick);

  /// A meaningful action just happened: form submitted, application
  /// advanced to its next status, a sheet/menu opened.
  static void medium() => _run(HapticFeedback.mediumImpact);

  /// A clearly positive outcome: application approved, payment confirmed.
  /// Use sparingly — reserved for moments the citizen should notice.
  static void success() => _run(HapticFeedback.heavyImpact);

  /// Destructive or cautionary confirmations only: cancel application,
  /// sign out, discard changes, delete account.
  static void warning() => _run(HapticFeedback.vibrate);

  /// A light, secondary confirmation — smaller than [medium].
  static void light() => _run(HapticFeedback.lightImpact);

  static void _run(Future<void> Function() call) {
    if (!enabled) return;
    call().catchError((_) {});
  }
}
