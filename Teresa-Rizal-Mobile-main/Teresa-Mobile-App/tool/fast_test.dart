// The fast tier: every test file that pumps no widgets.
//
// `flutter test` takes ~40s on the Windows lane and ~33 minutes on the macOS
// one. A gate that costs half an hour is a gate that gets skipped, and a skipped
// gate is not a gate. This runs the subset a developer can afford on every save.
//
// Run it with:
//
//     dart run tool/fast_test.dart
//
// A Dart script rather than a shell script on purpose: this repository is worked
// from two machines (macOS and Windows) and this runs identically on both with
// no shell dependency.
//
// **Selection is discovered, never listed.** A file qualifies if it contains no
// `testWidgets(`. Writing out the member files by hand would rot the moment
// someone adds a pure-logic test and forgets to register it — the same failure
// as an allowlist that silently stops covering what it names. The tradeoff is
// that a file mixing one widget test in with twenty logic tests drops out
// entirely; that is the honest, conservative direction to fail in.
//
// This tier is deliberately NOT a substitute for `flutter test`. It is currently
// a small fraction of the suite, because most of this codebase's model and
// service behaviour is asserted through widget tests. Push the full suite before
// pushing anything.
import 'dart:io';

/// Matches `testWidgets(` even when wrapped or preceded by an annotation.
final _widgetTest = RegExp(r'\btestWidgets\s*\(');

/// Matches a top-level `test(` call — the plain, non-widget kind.
final _plainTest = RegExp(r'(^|\s)test\s*\(', multiLine: true);

Future<int> main(List<String> args) async {
  final testDir = Directory('test');
  if (!testDir.existsSync()) {
    stderr.writeln('No test/ directory here. Run this from Teresa-Mobile-App/, not the repo root.');
    return 2;
  }

  final fast = <String>[];
  final skipped = <String>[];

  for (final file in testDir.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('_test.dart')) continue;
    final source = file.readAsStringSync();
    if (!_plainTest.hasMatch(source)) continue;
    final path = file.path.replaceAll(r'\', '/');
    if (_widgetTest.hasMatch(source)) {
      skipped.add(path);
    } else {
      fast.add(path);
    }
  }
  fast.sort();

  if (fast.isEmpty) {
    // Never report success over an empty selection: `Executed 0 of 0` reads as
    // a pass and is not one.
    stderr.writeln('Selected no test files. That is a bug in this script, not a green run.');
    return 2;
  }

  stdout.writeln('Fast tier: ${fast.length} file(s) with no widget pumping.');
  for (final f in fast) {
    stdout.writeln('  $f');
  }
  stdout.writeln('(${skipped.length} widget-test file(s) deferred to the full suite.)\n');

  final started = DateTime.now();
  final result = await Process.start(
    Platform.isWindows ? 'flutter.bat' : 'flutter',
    ['test', ...fast, ...args],
    mode: ProcessStartMode.inheritStdio,
  );
  final code = await result.exitCode;
  final elapsed = DateTime.now().difference(started);

  stdout.writeln('\nFast tier finished in ${elapsed.inMilliseconds / 1000}s (exit $code).');
  stdout.writeln('This is NOT the gate. Run `flutter test` before pushing.');
  return code;
}
