import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/widgets/requirement_heading.dart';

/// The Documents step (LGU, 4 Nov 2026; ebpco-api 071): "If applicable"
/// instead of "Optional", said by the group; "online only" said once above
/// the list, and a "Hard copies: n" chip only on a document that needs paper
/// (design review I13). The same words as the citizen portal's wizard and
/// Requirements window.
const _bfpNote = 'The BFP requires a hard copy. Submit it at the Castilla Fire Station.';

Future<void> _pump(WidgetTester tester, RequirementDoc doc) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RequirementHeading(doc: doc, attached: false)),
      ),
    );

void main() {
  group('reading the checklist', () {
    test('hardCopies and hardCopyNote, from the catalog and from the application\'s own checklist', () {
      final json = {
        'code': 'fsec',
        'label': 'Fire Safety Evaluation Clearance (FSEC)',
        'description': '',
        'required': true,
        'hardCopies': 1,
        'hardCopyNote': _bfpNote,
      };
      for (final doc in [RequirementDoc.fromCatalogJson(json), RequirementDoc.fromJson(json)]) {
        expect(doc.hardCopies, 1);
        expect(doc.hardCopyNote, _bfpNote);
      }
    });

    test('an older server that sends neither reads as online only, with no note', () {
      final doc = RequirementDoc.fromCatalogJson({'code': 'road-clearance', 'label': 'Road Clearance', 'required': false});
      expect(doc.hardCopies, 0);
      expect(doc.hardCopyNote, isNull);
      final odd = RequirementDoc.fromJson({'code': 'x', 'label': 'X', 'hardCopies': -2, 'hardCopyNote': '  '});
      expect(odd.hardCopies, 0);
      expect(odd.hardCopyNote, isNull);
    });

    test('the words: online only once above the list, a chip only where paper is needed', () {
      expect(onlineOnlyNote, 'Upload everything online. Paper copies only where marked.');
      expect(hardCopiesText(0), isNull);
      expect(hardCopiesText(1), 'Hard copies: 1');
      expect(hardCopiesText(3), 'Hard copies: 3');
      expect(requirementTag(required: true), 'Required');
      expect(requirementTag(required: false), 'If applicable');
    });

    test('a leading "Only if applicable:" is left off: the section already says it', () {
      expect(withoutIfApplicablePrefix('Only if applicable: when the added load needs structural computations.'),
          'When the added load needs structural computations.');
      expect(withoutIfApplicablePrefix('only if applicable — for a hotel'), 'For a hotel');
      expect(withoutIfApplicablePrefix('Issued by DPWH. Only if applicable: along a national road.'),
          'Issued by DPWH. Only if applicable: along a national road.');
      expect(withoutIfApplicablePrefix(null), '');
      final doc = RequirementDoc.fromCatalogJson(
          {'code': 'x', 'label': 'X', 'description': 'Only if applicable: for structures over two storeys.'});
      expect(doc.description, 'For structures over two storeys.');
    });

    test('a row for business applications only says so; one for everyone does not', () {
      expect(RequirementDoc.fromCatalogJson({'code': 'auth', 'label': 'Authority', 'applicantKind': 'business'}).isBusinessOnly,
          isTrue);
      expect(RequirementDoc.fromJson({'code': 'x', 'label': 'X', 'applicantKind': 'robot'}).applicantKind, isNull);
      expect(RequirementDoc.fromCatalogJson({'code': 'x', 'label': 'X'}).isBusinessOnly, isFalse);
    });
  });

  group('one document\'s card', () {
    testWidgets('a document sent online only carries no paper line and no tag of its own', (tester) async {
      await _pump(
        tester,
        RequirementDoc.fromCatalogJson({
          'code': 'road-clearance',
          'label': 'Road Clearance',
          'description': 'Issued by DPWH or the Provincial Engineering Office. Only if the project is along, or opens '
              'onto, a national or provincial road.',
          'required': false,
          'hardCopies': 0,
          'hardCopyNote': null,
        }),
      );

      expect(find.text('Road Clearance'), findsOneWidget);
      expect(find.text('Optional'), findsNothing);
      expect(find.text('Required'), findsNothing);
      expect(find.textContaining('national or provincial road'), findsOneWidget);
      expect(find.textContaining('Online only'), findsNothing);
      expect(find.textContaining('Hard copies'), findsNothing);
    });

    testWidgets('a BFP document says how many paper copies, with the note under it', (tester) async {
      await _pump(
        tester,
        RequirementDoc.fromCatalogJson({
          'code': 'fsec',
          'label': 'Fire Safety Evaluation Clearance (FSEC)',
          'description': '',
          'required': true,
          'hardCopies': 1,
          'hardCopyNote': _bfpNote,
        }),
      );

      expect(find.text('Hard copies: 1'), findsOneWidget);
      expect(find.text(_bfpNote), findsOneWidget);
      expect(find.textContaining('Online only'), findsNothing);
      // The note sits under the count.
      expect(tester.getTopLeft(find.text(_bfpNote)).dy, greaterThan(tester.getTopLeft(find.text('Hard copies: 1')).dy));
    });
  });
}
