// Every route to a gated screen must carry its guard — and there must be only
// one route.
//
// `root_shell.dart` wraps DokyuScreen and TulongScreen in
// `AccessGuard(required: AccessLevel.verified)`. Until 2026-08-30 the Home
// screen's "New Dokyu Request" / "New Tulong Request" buttons pushed the very
// same screens **raw**, so an Unverified citizen who used the CTA walked
// straight into the request flow the tab refuses them. One rule, two call
// sites, enforced at one.
//
// Found by signing in as the unverified demo account and tapping the button —
// not by a test. `nav_access_overflow_test.dart` renders the guarded tab and
// passes; nothing exercised the shortcut.
//
// The first fix wrapped those pushes in the same AccessGuard. It closed the
// access hole and it was not enough: `RootShell.openService` also intercepts
// the confirmed-duplicate account before it can reach either screen, and a
// second route bypassed that. The comment on `openService` had *already* stated
// the invariant — "both the launcher's bubbles and Home's own tiles funnel
// through this one gateway" — while two of Home's six call sites did not.
//
// So this asserts two properties, both by construction rather than by listing
// today's call sites:
//
//   1. no gated screen is ever built outside an AccessGuard;
//   2. exactly one file builds them at all, so the gateway cannot be routed
//      around by a future caller that remembers the guard but not the
//      duplicate-account rule.
//
// (2) subsumes (1) today. Both are kept: (1) is the rule a reader expects to
// find, and if the shell is ever legitimately split across files, (2) is the
// one that should be revisited and (1) is the one that must survive.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Screens that must never be constructed without an enclosing AccessGuard.
const _gated = ['DokyuScreen', 'TulongScreen', 'SakunaScreen'];

/// The single file permitted to construct them.
const _gateway = 'lib/screens/home/root_shell.dart';

/// Is this construction lexically inside an `AccessGuard(... child: ...)`?
///
/// A lookback rather than a balanced-paren regex: Dart's formatter splits these
/// calls across many lines, and a regex trying to match the whole thing is the
/// kind of clever that quietly stops matching and turns the test green. The
/// window is generous; requiring `child:` after the `AccessGuard(` is what makes
/// it specific.
bool _insideAccessGuard(String source, int constructionStart) {
  const window = 400;
  final from = constructionStart - window < 0 ? 0 : constructionStart - window;
  final before = source.substring(from, constructionStart);
  final guardAt = before.lastIndexOf('AccessGuard(');
  if (guardAt < 0) return false;
  return before.substring(guardAt).contains('child:');
}

void main() {
  final sources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String posix(File f) => f.path.replaceAll(r'\', '/');

  test('the scan reaches the screens', () {
    expect(sources.length, greaterThan(100), reason: 'only ${sources.length} lib files — the walk is broken');
  });

  for (final screen in _gated) {
    final pattern = RegExp(r'\b' + screen + r'\s*\(\s*\)');

    /// Every construction of [screen] outside its own definition file, as
    /// `path:line` → whether it sits inside an AccessGuard.
    Map<String, bool> constructions() {
      final found = <String, bool>{};
      for (final file in sources) {
        final source = file.readAsStringSync();
        // The screen's own definition file legitimately names it.
        if (source.contains('class $screen ')) continue;
        for (final match in pattern.allMatches(source)) {
          final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
          found['${posix(file)}:$line'] = _insideAccessGuard(source, match.start);
        }
      }
      return found;
    }

    test('$screen is never constructed outside an AccessGuard', () {
      final found = constructions();

      // A scanner that finds no constructions passes for ever.
      expect(
        found,
        isNotEmpty,
        reason: 'found no $screen construction at all — the pattern is broken, not the code',
      );

      final offenders = found.entries.where((e) => !e.value).map((e) => e.key).toList();
      expect(
        offenders,
        isEmpty,
        reason:
            '$screen is reachable without its AccessGuard from:\n  ${offenders.join('\n  ')}\n\n'
            'Wrap it exactly as root_shell.dart does, with the same required level '
            'and featureName. A screen gated on one route and open on another is '
            'not gated.',
      );
    });

    test('$screen is built only by the shell, so openService cannot be bypassed', () {
      final elsewhere = constructions().keys.where((at) => !at.startsWith('$_gateway:')).toList();

      expect(
        elsewhere,
        isEmpty,
        reason:
            '$screen is constructed outside $_gateway:\n  ${elsewhere.join('\n  ')}\n\n'
            'Even wrapped in an AccessGuard, a second route skips '
            'RootShell.openService — which turns the confirmed-duplicate account '
            'away with an explanation instead of the generic restricted notice. '
            'Call RootShell.openService(context, ServiceLauncherTarget.…) as the '
            'other Home call sites do.',
      );
    });
  }

  test('Dokyu and Tulong are entered from Services, not from a Home launcher', () {
    final home = File('lib/screens/home/home_screen.dart').readAsStringSync();
    expect(home.contains('RootShell.openService('), isFalse);
    final hub = File('lib/screens/services/services_hub_screen.dart').readAsStringSync();
    final calls = RegExp(r'RootShell\.openService\(').allMatches(hub).length;
    expect(
      calls,
      greaterThanOrEqualTo(3),
      reason: 'Services hub should open Dokyu, Tulong, and Emergency through RootShell.openService; found $calls',
    );
  });
}
