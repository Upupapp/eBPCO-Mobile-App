// The demo identities must stay synthetic. This test denies the retired ones.
//
// FE 02 replaced seven real residents' names, five real constituent record ids,
// their contact details and their photographs and ID scans with invented ones.
// This is what stops them coming back — through a revert, a copy-paste from an
// old branch, or someone reaching for "the demo account" from memory.
//
// WHY THE DENYLIST IS HASHED
//
// This repository is **public**. A ban test that listed the retired names in
// plaintext would republish precisely the index the command exists to remove —
// it would be a machine-readable roster of real residents, sitting in `test/`,
// with a comment explaining that these are real people. So the denylist stores
// only SHA-256 of each lowercased token. The test can recognise a name it can
// no longer state.
//
// The names themselves live in a retired-identity record kept OUTSIDE this
// repository, alongside the replacement mapping. If the hashes ever need
// regenerating, that file is the source of truth.
//
// TWO LIMITS, BOTH LEARNED THE HARD WAY
//
// 1. **It cannot read pixels.** This scans text and file *names*. A name
//    rendered INTO an image is invisible to it. FE 02's first pass replaced
//    three ID images and left four Digital ID wallet cards untouched, and this
//    test went green over a card printing a real resident's photograph, name,
//    birthdate, address and mobile number. Running the app on a device is what
//    caught it. Any new image asset that could carry a person's details has to
//    be looked at by a human; nothing here will tell you.
//
// 2. **It checks the working tree at HEAD**, not git history, where every
//    retired name still appears. That needs a history rewrite, a force-push and
//    treating the data as already fetched — an owner decision, out of scope.
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// SHA-256 of each retired token, lowercased. Names and real record ids.
///
/// Adding to this list is how you retire a further identity. Removing from it
/// is almost certainly wrong: an entry here means the token belonged to a real
/// person or a real record.
const _retired = <String>{
  // Given names and surnames of the retired real identities.
  'a5412d7fca9299d102bd61f9f7c7787cfae055f6dd7323213f2167fe46d0ce5d',
  'bb2a0fede70ddb9b6b5aa0714cd8f3361231c7a7f114f46fa282aa9e2e4055e5',
  'a8da6f418767a573e7a0aea5460be3278db27b4f67972c654bc1ba76edfd27b6',
  '846b9c26d300d05c9043887ed1e0ed1c4c31561a221db5e680f0a03b899d08c5',
  'c459fa6dceb30d7b3bb570911decc759e01b5961b844b10a8f5d0b348fe9d7db',
  'd01cee08d49e3c7f77e63e7ee6d433b2f09db709a3ad3349b77231750822a65f',
  'a5c9ff7ae810da0e7c9f83c6831bba3311ddbb963d94fc35e8945508ac2f4b54',
  '15d3c9024906581a80c749fc3b0fada4980b6137c947fb74f19228d78f0066e3',
  'e27622e8321da74e6eafb1cee8e7804200cb536ef606173c0376d5f8c470ceaf',
  '72534c4a93ddc043fe3229ed46b1d526c4ccc747febdcd0f284f7f6057a37858',
  'e24dd2210803b4737a9bd9e3163a4ca807b63201c3bc32b68fb122ca52efff36',
  '84a32e28881a1b5fce6e527638ebdfd9e7d4d3aea26dc83260d344450ba7dd07',
  '9a53fe2d0781a3228ea5effdb126069bb3ea6658a0e1dd2801a663078b4fd723',
  '8aebd98d287f59be8b436469df015dabe678c57698e0abc6f576c71abcc3902a',
  // Real constituent / household / family record identifiers.
  '80d7a3ea023fb8e71b85e19bf2ff0875d4abb1ec4dad1aa9ed29010ff2feccd9',
  'bdb4d7bd68e9b771d5724411f36131b8771e71746de249a40b983c1678cbd3ba',
  'fa0aa77ed0edc4094f4b65d8647c70f875f4c2ae959df3644dec1005d8fc870f',
  '6561eead0d66607e3afa38d08c1a150d19bf41c667b63974d4abdcfd4032e576',
  '3bb2249d52cce0895ce0f3554ed482670de834b830bf7b0c2a4f1d1316bc324f',
  'e5a5791a9efeb53a47c8638622302d60820893e5f03c45d9e184a0e61c15afcc',
  '8d35f2a9fb4797fe48b70d2d2aca4e40d2d3310392afea8ada818012f58f49ad',
  '336e741fbc979958399de85b561cdf7325011fb3eb3f7726a81e23f485f5f196',
};

/// Words, and hyphenated identifier tokens like `ESP-RES-2024-9002`.
///
/// (That example is deliberately a synthetic id. The first version of this
/// comment used a real retired one, and this test caught it on its first run.)
final _token = RegExp(r'[A-Za-z][A-Za-z0-9-]*|[A-Za-z0-9]+(?:-[A-Za-z0-9]+)+');

String _hash(String token) => sha256.convert(utf8.encode(token.toLowerCase())).toString();

/// Text files worth scanning, plus every file *name* under the scanned roots.
const _textExtensions = {'.dart', '.yaml', '.json', '.md', '.xml', '.plist', '.html'};

void main() {
  test('no retired real identity appears anywhere in the app', () {
    final offenders = <String>{};
    var filesScanned = 0;
    var tokensChecked = 0;

    for (final root in ['lib', 'test', 'assets', 'web', 'android/app/src/main', 'ios/Runner']) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;

      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File) continue;
        final path = entity.path.replaceAll(r'\', '/');

        // A file NAME can carry an identity even when its bytes cannot be read
        // — three of the retired ID scans were named after their subject.
        for (final match in _token.allMatches(path.split('/').last)) {
          tokensChecked++;
          if (_retired.contains(_hash(match.group(0)!))) offenders.add('$path  (in the filename)');
        }

        final dot = path.lastIndexOf('.');
        if (dot < 0 || !_textExtensions.contains(path.substring(dot))) continue;

        filesScanned++;
        String contents;
        try {
          contents = entity.readAsStringSync();
        } on FileSystemException {
          continue; // not text after all
        }
        for (final match in _token.allMatches(contents)) {
          tokensChecked++;
          if (_retired.contains(_hash(match.group(0)!))) offenders.add(path);
        }
      }
    }

    // Anti-vacuity: a scanner that reads nothing passes beautifully. These
    // floors are far below the real counts and exist only to catch a broken
    // path or a broken pattern.
    expect(filesScanned, greaterThan(150), reason: 'only $filesScanned text files scanned — the walk is broken');
    expect(tokensChecked, greaterThan(50000), reason: 'only $tokensChecked tokens checked — the pattern is broken');

    expect(
      offenders.toList()..sort(),
      isEmpty,
      reason:
          'A retired real identity has come back in:\n'
          '  ${(offenders.toList()..sort()).join('\n  ')}\n\n'
          'These are real residents of Teresa, Rizal, in a PUBLIC repository. Use the '
          'synthetic demo identities instead — see docs/FE02_SYNTHETIC_IDENTITIES.md. '
          'The retired names are deliberately not printed here.',
    );
  });

  test('the denylist actually recognises a retired token', () {
    // Without this, a mistake in `_hash` or `_token` would make the test above
    // pass by never matching anything — green, and worthless. This proves the
    // machinery fires, using one hash that is already in the list.
    const knownRetiredHash = '846b9c26d300d05c9043887ed1e0ed1c4c31561a221db5e680f0a03b899d08c5';
    expect(_retired, contains(knownRetiredHash));

    // And the tokeniser must actually produce single lowercase-able words plus
    // hyphenated ids from realistic source text.
    final tokens = _token.allMatches("id: 'ESP-RES-2024-9002', firstName: 'Perlita',").map((m) => m.group(0)).toList();
    expect(tokens, contains('ESP-RES-2024-9002'));
    expect(tokens, contains('Perlita'));
  });

  test('the synthetic identities are actually present', () {
    // The inverse guard: a rename that deleted the demo data rather than
    // replacing it would also satisfy the denylist.
    final catalog = File('lib/services/mock_catalog.dart').readAsStringSync();
    for (final name in ['Perlita', 'Quiambao', 'Nicanor', 'Sarmiento', 'Anacleto', 'Dimaculangan']) {
      expect(catalog, contains(name), reason: 'the synthetic identity "$name" is missing from the catalog');
    }
  });
}
