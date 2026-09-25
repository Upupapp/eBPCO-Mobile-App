// Colours and type sizes belong to the theme, not to screens.
//
// `lib/theme/app_colors.dart` is a verified 1:1 port of the web platform's
// `app.css`, so every colour written outside `lib/theme/` is a place the two
// surfaces can drift apart with nothing to notice. That is not hypothetical:
// `teresa_rizal_curved_navbar.dart` carried `Color(0x1A0B1B4A)` commented
// "navy900 @ 10%" for who knows how long, and `0B1B4A` is not navy900.
//
// TWO DIFFERENT RULES, DELIBERATELY
//
// * **Raw hex is banned outright.** A hex literal is a colour that can drift
//   from the palette, and it is the exact shape the bug above took.
//
// * **`Colors.white` / `Colors.black` / `Colors.transparent` are allowed.**
//   They are held to a *ratchet* instead. They cannot drift — white is white on
//   both surfaces — so banning them buys ceremony, not parity. What is worth
//   preventing is their spread, so the count may fall and never rise.
//
// Hardcoded `fontSize:` is a ratchet for the same reason it exists at all:
// there are 412 of them, and the honest fix is migration screen by screen, not
// a flag day. See docs/FE06_DESIGN_TOKEN_DISCIPLINE.md.
//
// LOWERING A CEILING IS THE POINT. When you migrate a screen, run this test,
// take the number it reports, and put it here. A ceiling that is never lowered
// is a ceiling nobody is working under.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Hardcoded `fontSize: 14` / `fontSize: 12.5` outside `lib/theme/`.
///
/// 2026-08-29: 412 at the start of FE 06; 400 after migrating
/// `request_detail_screen.dart`, the densest single file. 398 on 2026-08-30,
/// when the onboarding redesign replaced its inline sizes with the type scale —
/// the two new tokens it needed (`hero`, `wordmark`) were added to
/// `app_typography.dart` rather than written as numbers, which is what this
/// file's own failure message asks for.
/// 375 after Pack B moved shell chrome onto SoftType / SoftColors and
/// Pack C detail screens added their own inline sizes.
const _fontSizeCeiling = 375;

/// `Colors.white`, `Colors.black26`, `Colors.transparent` outside `lib/theme/`.
///
/// 2026-08-29: 141 at the start of FE 06. 128 on 2026-08-30: the retired
/// onboarding artwork needed a dozen `Colors.white`/`Colors.black38` values to
/// keep overlay text legible against three unknown photographs. The redesign
/// draws its own surfaces, so it can use palette tokens instead.
/// 106 after Pack B replaced new `Colors.transparent` shell fills with
/// `SoftColors.clear`. Pack C detail chrome accounts for the rest.
/// 81 once Packs E, F, G and the L9 relabel landed together: each branch
/// alone stayed inside the old margin, the combination fell below it.
const _materialColorCeiling = 81;

final _fontSizeLiteral = RegExp(r'fontSize:\s*[0-9]');

/// `Colors.foo`, but never `AppColors.foo` — the leading boundary matters, and
/// getting it wrong reports 842 instead of 141.
final _materialColor = RegExp(r'(^|[^A-Za-z])Colors\.[a-zA-Z0-9]+');

/// Any raw ARGB literal.
final _rawHex = RegExp(r'Color\(0x');

List<File> _libFilesOutsideTheme() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .where(
        (f) =>
            !f.path.replaceAll(r'\', '/').contains('/lib/theme/') &&
            !f.path.replaceAll(r'\', '/').startsWith('lib/theme/'),
      )
      .toList();
  return files;
}

int _countAcross(
  List<File> files,
  RegExp pattern, {
  List<String>? collectInto,
}) {
  var total = 0;
  for (final f in files) {
    final matches = pattern.allMatches(f.readAsStringSync()).length;
    if (matches > 0) {
      total += matches;
      collectInto?.add('${f.path.replaceAll(r'\', '/')}  ($matches)');
    }
  }
  return total;
}

void main() {
  final files = _libFilesOutsideTheme();

  test('the scan actually reaches the screens', () {
    // A ratchet that counts nothing passes for ever. Every threshold below is
    // worthless without this.
    expect(
      files.length,
      greaterThan(100),
      reason:
          'only ${files.length} files outside lib/theme/ — the walk is broken',
    );
  });

  test('no raw hex colour outside lib/theme/', () {
    final offenders = <String>[];
    final count = _countAcross(files, _rawHex, collectInto: offenders);
    expect(
      count,
      0,
      reason:
          'Raw ARGB literals outside the theme:\n  ${offenders.join('\n  ')}\n\n'
          'A hex here can drift from the shared palette — one already had. Use an '
          'AppColors token. If it is genuinely not an Teresa, Rizal colour (a '
          'third-party brand mark, say), it still belongs in lib/theme/ where this '
          'gate can see it — see ThirdPartyBrandColors.',
    );
  });

  test('Material colour constants do not spread', () {
    final count = _countAcross(files, _materialColor);
    expect(
      count,
      lessThanOrEqualTo(_materialColorCeiling),
      reason:
          'Colors.* outside lib/theme/ rose to $count, ceiling $_materialColorCeiling. '
          'These are allowed but not encouraged: prefer an AppColors token so the '
          'palette stays the single source.',
    );
    // Ratchet down when it drops, so the ceiling keeps meaning something.
    expect(
      count,
      greaterThan(_materialColorCeiling - 25),
      reason:
          'Colors.* fell to $count — lower _materialColorCeiling to $count.',
    );
  });

  test('hardcoded font sizes do not spread', () {
    final count = _countAcross(files, _fontSizeLiteral);
    expect(
      count,
      lessThanOrEqualTo(_fontSizeCeiling),
      reason:
          'Hardcoded fontSize: outside lib/theme/ rose to $count, ceiling $_fontSizeCeiling.\n'
          'Use an AppTypography style. If none fits, that is the finding — the token '
          'set was too small, which is why 177 half-point sizes existed with no token '
          'at all. Add the style, do not add the number.',
    );
    expect(
      count,
      greaterThan(_fontSizeCeiling - 40),
      reason:
          'fontSize literals fell to $count — lower _fontSizeCeiling to $count.',
    );
  });

  test('the extended type scale covers the sizes the app actually uses', () {
    // The half-point sizes were 177 of the 412 literals and had no token at
    // all. If one of these disappears, the bypass it was added to prevent
    // comes straight back.
    final typography = File('lib/theme/app_typography.dart').readAsStringSync();
    for (final size in ['12.5', '13.5', '11.5', '10.5']) {
      expect(
        typography,
        contains('fontSize: $size'),
        reason: 'the type scale lost its $size style',
      );
    }
  });
}
