// WCAG AA contrast for every status chip.
//
// This is a municipal service app whose users include senior citizens and
// persons with disability — it ships dedicated OSCA and PDAO flows. Status text
// is the thing a citizen reads to learn what is happening to their application,
// so it has to be legible.
//
// Status chips render at 12px regular, which is "normal text" under WCAG 2.1,
// so the threshold is **4.5:1** (the relaxed 3:1 applies only to text at 18pt+,
// or 14pt+ bold).
//
// Contrast is computed here rather than eyeballed: it is exactly defined, so
// asserting it is strictly better than a reviewer's judgement.
//
// IMPORTANT — the palette is shared. `app_colors.dart` is a verified 1:1 port of
// the Web Admin's `app.css`, so a failure here is a **cross-surface** finding
// affecting both projects' badges. Do NOT fix one by re-colouring the token:
// that silently breaks parity and leaves the web platform failing anyway. Raise
// it, and record it in `_knownSharedPaletteFailures` below until it is resolved.
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/theme/app_status.dart';

/// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double channel(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Minimum for normal-size text under WCAG 2.1 AA.
const _aaNormalText = 4.5;

/// Statuses that fail AA using colours inherited from the shared web palette.
///
/// These are **not** tolerated defects, they are escalations with a paper trail.
/// Each records the measured ratio so a change in either direction is visible.
/// Do not add to this map to make a new failure go away — a newly introduced
/// colour that fails is a mobile-side mistake, not a shared-palette problem.
const _knownSharedPaletteFailures = <AppStatus, String>{
  // 4.34:1 — marginal, and slate-500 on slate-100 comes straight from the Web
  // Admin's own `Cancelled` badge. Raised 2026-08-29 (FE 05).
  AppStatus.cancelled: '4.34:1 — shared palette, raised with the web platform',
  // 2.34:1 — roughly half the requirement. slate-400 on slate-100 is grey on
  // grey. Both surfaces deliberately de-emphasise Archived, but WCAG grants no
  // exemption for text that is *meant* to recede. Raised 2026-08-29 (FE 05).
  AppStatus.archived: '2.34:1 — shared palette, raised with the web platform',
};

void main() {
  test('every status chip meets WCAG AA for normal text, or is a recorded escalation', () {
    final unexpected = <String>[];

    for (final status in AppStatus.values) {
      final style = status.style;
      final ratio = _contrast(style.background, style.foreground);
      final known = _knownSharedPaletteFailures.containsKey(status);

      if (ratio < _aaNormalText && !known) {
        unexpected.add('${status.label}: ${ratio.toStringAsFixed(2)}:1 (needs $_aaNormalText:1)');
      }
    }

    expect(
      unexpected,
      isEmpty,
      reason:
          'Status chips below WCAG AA with no recorded escalation:\n'
          '  ${unexpected.join('\n  ')}\n\n'
          'If the colour came from the shared web palette, RAISE it with the web '
          'platform and record it in _knownSharedPaletteFailures — do not re-colour '
          'the token here, which breaks 1:1 parity and leaves the web failing too. '
          'If the colour is new and mobile-only, it is simply wrong: pick another.',
    );
  });

  test('the recorded escalations have not silently been fixed', () {
    // If the web platform resolves one, this fails and the entry comes out —
    // otherwise the map keeps claiming a problem that no longer exists, and the
    // next person trusts a stale escalation.
    for (final entry in _knownSharedPaletteFailures.entries) {
      final style = entry.key.style;
      final ratio = _contrast(style.background, style.foreground);
      expect(
        ratio,
        lessThan(_aaNormalText),
        reason:
            '${entry.key.label} now measures ${ratio.toStringAsFixed(2)}:1 and passes AA. '
            'Remove it from _knownSharedPaletteFailures.',
      );
    }
  });

  test('the dot colour is not the only thing distinguishing a status', () {
    // Colour must never be the sole carrier of meaning (WCAG 1.4.1). Every chip
    // prints its own label, so this holds by construction — asserted anyway so
    // that a future "icon-only" or "dot-only" compact chip cannot quietly break
    // it without a test going red.
    for (final status in AppStatus.values) {
      expect(status.label.trim(), isNotEmpty, reason: '${status.name} renders no text');
    }
  });
}
