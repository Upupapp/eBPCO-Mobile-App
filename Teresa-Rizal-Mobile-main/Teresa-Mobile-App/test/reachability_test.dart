// Every file under lib/ must be reachable from main.dart by following imports.
//
// A widget that no user can reach, but that has green tests and is named in the
// spec as the component that ships, is worse than no tests at all: it consumes
// review attention and reports confidence that is not there. That is exactly
// what `attachment_picker.dart` was — imported by three test files and nothing
// else, while the live screens used `RequirementUploader`.
//
// This lives as a test rather than a script in tool/ for one reason: there is no
// CI in this repository, so `flutter test` is the only thing that actually runs.
// A check nobody runs is not a check.
//
// Import-reachability is NOT user-reachability. A widget can be imported by a
// live screen and still sit behind a condition nobody can satisfy. Only the
// device walk (FE 03) catches that. This test proves the weaker property, which
// is still worth proving because it is the one that can be automated.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Files deliberately not reachable from `main.dart`, each with a reason.
///
/// Keep this empty if you can. An entry here is a promise that the file earns
/// its place some other way — never a way to silence the check.
const Map<String, String> _allowedUnreachable = <String, String>{
  // Cluster 5 profile hub stopped mounting these. The status card is still
  // pumped by its own overflow test; the other two have no caller. Re-wire
  // or delete them with that hub — not from the shell pass.
  'lib/screens/profile/edit_profile_screen.dart':
      'unmounted by the Cluster 5 profile hub',
  'lib/widgets/menu_tile.dart': 'unmounted by the Cluster 5 profile hub',
  'lib/widgets/resident_profile_status_card.dart':
      'unmounted by the Cluster 5 profile hub; still unit-tested',
  // Pack E inbox matches the comps: no preferences control on the bell
  // screen. The screen stays in the tree for a later preferences pass.
  'lib/screens/notifications/notification_preferences_screen.dart':
      'Pack E removed the inbox entry; preferences are out of scope',
  // The credential wallet was replaced by the resident Digital ID card.
  // These two files were only reached from that screen.
  'lib/theme/app_shadows.dart':
      'web shadow tokens; the Digital ID card uses SoftShadows',
  'lib/utils/digital_credentials.dart':
      'retired Barangay Resident ID / PWD wallet lookup',
};

/// Resolves the relative `import`/`export`/`part` targets of a Dart file.
///
/// Deliberately ignores `package:` and `dart:` — a `package:teresa_rizal/`
/// self-import would also be reachability, but this codebase uses relative
/// imports inside `lib/`, and pulling in the whole package graph would only add
/// noise. If that convention ever changes, this is the line to revisit.
Set<String> _localTargetsOf(File file) {
  final directive = RegExp(
    r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );
  final dir = file.parent.path.replaceAll(r'\', '/');
  final targets = <String>{};

  for (final match in directive.allMatches(file.readAsStringSync())) {
    final raw = match.group(1)!;
    if (raw.startsWith('package:') || raw.startsWith('dart:')) continue;
    targets.add(_normalise('$dir/$raw'));
  }
  return targets;
}

/// Collapses `a/b/../c` to `a/c` so the same file is never counted twice under
/// two spellings, and normalises Windows separators.
String _normalise(String path) {
  final parts = <String>[];
  for (final segment in path.replaceAll(r'\', '/').split('/')) {
    if (segment == '.' || segment.isEmpty) continue;
    if (segment == '..') {
      if (parts.isNotEmpty) parts.removeLast();
      continue;
    }
    parts.add(segment);
  }
  return parts.join('/');
}

void main() {
  test('every file under lib/ is reachable from main.dart', () {
    final libDir = Directory('lib');
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'run this from the app directory (Teresa-Mobile-App/), not the repo root',
    );

    final allFiles = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => _normalise(f.path))
        .toSet();

    // Guards against the check silently passing over an empty set — the failure
    // mode where a path bug makes "zero unreachable" mean "zero examined".
    expect(
      allFiles.length,
      greaterThan(100),
      reason: 'expected the whole lib/ tree; found ${allFiles.length} files, so the walk is broken',
    );

    final entry = _normalise('lib/main.dart');
    expect(allFiles, contains(entry));

    final reachable = <String>{};
    final queue = <String>[entry];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!reachable.add(current)) continue;
      final file = File(current);
      if (!file.existsSync()) continue;
      for (final target in _localTargetsOf(file)) {
        if (!reachable.contains(target)) queue.add(target);
      }
    }

    final unreachable = allFiles.difference(reachable).toList()..sort();
    final unexplained = unreachable.where((f) => !_allowedUnreachable.containsKey(f)).toList();

    expect(
      unexplained,
      isEmpty,
      reason:
          'These files under lib/ cannot be reached from main.dart:\n'
          '  ${unexplained.join('\n  ')}\n\n'
          'Wire each one where it belongs, or delete it together with its tests. '
          'If it genuinely must stay unreachable, add it to _allowedUnreachable '
          'with a reason — an entry there is a promise, not a silencer.',
    );

    // A stale allowlist is its own defect: it says a file is a known exception
    // when the file is either gone or now perfectly reachable.
    for (final allowed in _allowedUnreachable.keys) {
      expect(
        unreachable,
        contains(allowed),
        reason: '$allowed is in _allowedUnreachable but is no longer unreachable — remove the entry',
      );
    }
  });

  test('every declared asset exists, and every asset file is declared', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    // Only the `assets:` block — `fonts:` declares its files under `asset:`
    // keys with a different shape and is checked separately below.
    final declared = RegExp(r'''^\s*-\s+(assets/[^\s#]+)\s*$''', multiLine: true)
        .allMatches(pubspec)
        .map((m) => m.group(1)!.trim())
        .toSet();

    expect(declared, isNotEmpty, reason: 'no assets parsed from pubspec.yaml — the pattern is wrong');

    final missing = declared.where((a) => !File(a).existsSync()).toList()..sort();
    expect(
      missing,
      isEmpty,
      reason: 'declared in pubspec.yaml but not on disk:\n  ${missing.join('\n  ')}',
    );
  });
}
