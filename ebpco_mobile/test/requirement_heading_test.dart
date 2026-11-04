import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/widgets/requirement_heading.dart';

/// The Documents step (LGU, 4 Nov 2026; ebpco-api 071): "If applicable"
/// instead of "Optional", and per document whether paper copies are needed
/// too. The same words as the citizen portal's wizard and requirements window.
const _bfpNote = 'The BFP requires a hard copy. Submit it at the Castilla Fire Station.';

Future<void> _pump(WidgetTester tester, RequirementDoc doc, {required bool required}) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RequirementHeading(doc: doc, required: required, attached: false)),
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

    test('the words', () {
      expect(hardCopiesText(0), 'Online only, no hard copy');
      expect(hardCopiesText(1), 'Hard copies: 1');
      expect(hardCopiesText(3), 'Hard copies: 3');
      expect(requirementTag(required: true), 'Required');
      expect(requirementTag(required: false), 'If applicable');
    });
  });

  group('one document\'s card', () {
    testWidgets('a document needed only for some projects says If applicable, never Optional', (tester) async {
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
        required: false,
      );

      expect(find.text('Road Clearance'), findsOneWidget);
      expect(find.text('If applicable'), findsOneWidget);
      expect(find.text('Optional'), findsNothing);
      expect(find.text('Required'), findsNothing);
      expect(find.textContaining('national or provincial road'), findsOneWidget);
      expect(find.text('Online only, no hard copy'), findsOneWidget);
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
        required: true,
      );

      expect(find.text('Required'), findsOneWidget);
      expect(find.text('Hard copies: 1'), findsOneWidget);
      expect(find.text(_bfpNote), findsOneWidget);
      expect(find.text('Online only, no hard copy'), findsNothing);
      // The note sits under the count.
      expect(tester.getTopLeft(find.text(_bfpNote)).dy, greaterThan(tester.getTopLeft(find.text('Hard copies: 1')).dy));
    });
  });
}
