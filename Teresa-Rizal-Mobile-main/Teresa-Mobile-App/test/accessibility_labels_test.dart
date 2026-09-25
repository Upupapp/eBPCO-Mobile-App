// An icon-only control that announces nothing is invisible to a screen reader.
//
// This is a municipal service app with dedicated OSCA (senior citizen) and PDAO
// (persons with disability) flows — the population most likely to need a screen
// reader is the population it was built for.
//
// `IconButton`'s `tooltip` is what Flutter turns into the semantic label, so a
// tooltip is not decoration here: it is the accessible name. An `IconButton`
// with neither a tooltip nor an enclosing `Semantics` announces only "button".
//
// This is a **source-level** check, and that is a real limitation: it proves
// every icon button *has* a name, not that the name is a good one, and it
// cannot see icon-only controls built from `GestureDetector` or `InkWell`.
// Only a VoiceOver/TalkBack walk on a device settles those (FE 03/FE 05).
// It is still worth having, because it is the half that can be automated and it
// fails the moment someone adds an unnamed icon button.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `IconButton(` — including `const IconButton(` and `? IconButton(`.
final _iconButton = RegExp(r'\bIconButton\s*\(');

/// The window after an `IconButton(` in which its own `tooltip:` must appear.
/// Generous enough to cover a multi-line constructor, tight enough that it
/// cannot borrow a tooltip from an unrelated widget further down the file.
const _lookaheadChars = 420;

void main() {
  test('every IconButton has a tooltip, which is its screen-reader name', () {
    final offenders = <String>[];
    var examined = 0;

    for (final file in Directory('lib').listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final source = file.readAsStringSync();

      for (final match in _iconButton.allMatches(source)) {
        examined++;
        final end = (match.end + _lookaheadChars).clamp(0, source.length);
        final window = source.substring(match.end, end);
        if (window.contains('tooltip:')) continue;

        final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
        offenders.add('${file.path.replaceAll(r'\', '/')}:$line');
      }
    }

    // Never pass over an empty scan: if the pattern stops matching, this test
    // would go green while checking nothing at all.
    // 9 after the request-list menu moved onto SoftCircleButton, which
    // carries its own tooltip. The floor only proves the scan still sees
    // real IconButton( call sites.
    expect(
      examined,
      greaterThanOrEqualTo(9),
      reason: 'found only $examined IconButton call sites — the pattern is broken, not the code',
    );

    expect(
      offenders,
      isEmpty,
      reason:
          'IconButtons with no tooltip, so a screen reader announces only "button":\n'
          '  ${offenders.join('\n  ')}\n\n'
          'Add `tooltip:` — Flutter uses it as the semantic label. If the control genuinely '
          'needs no name, wrap it in ExcludeSemantics deliberately and say why.',
    );
  });
}
