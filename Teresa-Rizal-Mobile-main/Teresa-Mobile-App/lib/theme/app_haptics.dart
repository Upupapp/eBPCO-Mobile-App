import 'package:flutter/services.dart';

/// Centralized haptic feedback, named by *when it's allowed to fire* rather
/// than by the underlying Flutter API — adapted from the Servana Client
/// App's haptics discipline: every method carries a one-line rule for its
/// use, so callers reach for a meaning ("this is a low-stakes selection")
/// rather than picking [HapticFeedback.selectionClick] vs
/// [HapticFeedback.mediumImpact] ad hoc. House rules, ported as-is because
/// they're sound for any app:
///   - never on keystrokes or passive scrolling
///   - never repeatedly on a failed/retried action
///   - never as the *only* signal a state changed — always paired with a
///     visible change (a chip color, a new screen, a status update)
class AppHaptics {
  AppHaptics._();

  /// Master on/off switch. No Settings UI wires this yet — it exists so one
  /// can be added later without touching every call site.
  static bool enabled = true;

  /// Low-stakes selections: tab taps, filter chips, radio/segmented picks.
  static void selection() => _run(HapticFeedback.selectionClick);

  /// A meaningful action just happened: form submitted, request advanced to
  /// its next milestone, a sheet/menu opened.
  static void medium() => _run(HapticFeedback.mediumImpact);

  /// A clearly positive outcome: request approved, payment confirmed,
  /// verification completed. Use sparingly — reserved for moments the
  /// citizen should notice.
  static void success() => _run(HapticFeedback.heavyImpact);

  /// Destructive or cautionary confirmations only: cancel request, sign
  /// out, discard changes.
  static void warning() => _run(HapticFeedback.vibrate);

  /// A light, secondary confirmation — smaller than [medium], used for
  /// decorative lock-ins (e.g. a step indicator settling) rather than a
  /// real state change.
  static void light() => _run(HapticFeedback.lightImpact);

  static void _run(Future<void> Function() call) {
    if (!enabled) return;
    // Fire-and-forget, errors swallowed — haptics are a nice-to-have and
    // must never surface an error to the citizen or block a UI action.
    call().catchError((_) {});
  }
}
