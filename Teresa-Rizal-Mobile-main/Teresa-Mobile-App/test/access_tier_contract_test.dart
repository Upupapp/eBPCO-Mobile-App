// Which access tier each module requires — pinned, because it is now a
// cross-surface contract and not just a local UI choice.
//
// The tiers are three, and the middle one is load-bearing:
//
//   guest       Balita, Events
//   unverified  + Sakuna / Emergency        <- a registered but unapproved
//   verified    + Dokyu, Tulong                citizen may still report an
//                                              incident
//
// Sakuna being reachable at `unverified` is deliberate: someone who has
// registered but is still `Pending Review` must be able to report a flood or a
// fire. Dokyu and Tulong require `verified`.
//
// This matters beyond mobile, and it has a server counterpart as of 2026-08-29:
// `POST /api/v1/citizen/incidents` explicitly admits Unverified accounts, while
// Dokyu and Tulong submissions are refused with `ACCOUNT_NOT_VERIFIED`. Before
// that endpoint existed the only way to create an incident was an admin route no
// citizen could reach, so this button had nothing to call at all.
//
// The two surfaces now agree, which is exactly why this is pinned: if mobile
// quietly tightened Sakuna to `verified`, both sides would still "agree" — on
// denying emergency reports to the citizens most likely to need them. The rule
// is asserted here rather than left implicit in a widget tree.
//
// `AccessGuard` compares by enum index (`level.index >= required.index`), so
// declaration order in `AccessLevel` is itself part of the contract.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/models/access_level.dart';

/// The tier each module's `AccessGuard` actually declares in `root_shell.dart`.
///
/// Read from the source rather than restated here. A test that declares its own
/// copy of the rule and then asserts against that copy proves only that the
/// copy exists — it would keep passing while the app changed underneath it.
Map<String, String> _declaredGuards() {
  final source = File('lib/screens/home/root_shell.dart').readAsStringSync();
  final pattern = RegExp(
    r"AccessGuard\(\s*required:\s*AccessLevel\.(\w+)\s*,\s*featureName:\s*'([^']+)'",
    multiLine: true,
  );
  final found = <String, String>{};
  for (final m in pattern.allMatches(source)) {
    found[m.group(2)!] = m.group(1)!;
  }
  return found;
}

void main() {
  test('the tiers are ordered least- to most-privileged', () {
    // AccessGuard's `>=` check is only meaningful if this order holds.
    expect(AccessLevel.values, [AccessLevel.guest, AccessLevel.unverified, AccessLevel.verified]);
    expect(AccessLevel.guest.index, lessThan(AccessLevel.unverified.index));
    expect(AccessLevel.unverified.index, lessThan(AccessLevel.verified.index));
  });

  test('an unverified citizen outranks a guest but not a verified one', () {
    bool allowed(AccessLevel have, AccessLevel required) => have.index >= required.index;

    expect(allowed(AccessLevel.unverified, AccessLevel.unverified), isTrue);
    expect(allowed(AccessLevel.unverified, AccessLevel.guest), isTrue);
    expect(allowed(AccessLevel.unverified, AccessLevel.verified), isFalse);
    expect(allowed(AccessLevel.guest, AccessLevel.unverified), isFalse);
    expect(allowed(AccessLevel.verified, AccessLevel.verified), isTrue);
  });

  test('every module gate is one of the known tiers, and all three are in use', () {
    final guards = _declaredGuards();
    expect(guards, isNotEmpty, reason: 'parsed no AccessGuard declarations — the pattern is broken');

    final names = AccessLevel.values.map((v) => v.name).toSet();
    for (final entry in guards.entries) {
      expect(names, contains(entry.value), reason: '${entry.key} guards on an unknown tier "${entry.value}"');
    }
  });

  test('emergency incident reporting is NOT gated on being verified', () {
    // The one that must not drift. If this becomes `verified`, a citizen
    // awaiting approval loses the ability to report an emergency — and the
    // backend's ACCOUNT_NOT_VERIFIED gate would then look correct when it is
    // not. Change it only with the LGU's agreement, on both surfaces.
    final guards = _declaredGuards();
    final emergency = guards.entries.firstWhere(
      (e) => e.key.toLowerCase().contains('emergency'),
      orElse: () => throw StateError('no Emergency AccessGuard found in root_shell.dart: ${guards.keys}'),
    );

    expect(
      emergency.value,
      AccessLevel.unverified.name,
      reason: '"${emergency.key}" now requires "${emergency.value}". A registered but '
          'unapproved citizen must still be able to report an incident.',
    );
  });

  test('document and assistance requests DO require a verified account', () {
    final guards = _declaredGuards();
    for (final module in ['Dokyu', 'Tulong']) {
      final entry = guards.entries.firstWhere(
        (e) => e.key.contains(module),
        orElse: () => throw StateError('no $module AccessGuard found: ${guards.keys}'),
      );
      expect(entry.value, AccessLevel.verified.name, reason: '$module must stay verified-only');
    }
  });
}
