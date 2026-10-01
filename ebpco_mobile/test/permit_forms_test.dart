import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/permit_catalog.dart';
import 'package:ebpco_mobile/domain/permit_forms.dart';

void main() {
  test('every permit a citizen can file has a blank form, and the file is bundled', () {
    for (final group in permitTypeGroups) {
      for (final type in group.types) {
        final form = permitFormFor(type);
        expect(form, isNotNull, reason: '$type has no form');
        expect(File(form!.assetPath).existsSync(), isTrue, reason: '${form.assetPath} is missing');
      }
    }
    expect(File(oboChecklist.assetPath).existsSync(), isTrue);
  });

  test('the BFP clearances are not offered as forms: the BFP issues them on BFP-FSIS', () {
    for (final type in retiredPermitTypes) {
      expect(permitFormFor(type), isNull);
      expect(permitDocumentsFor(type), isEmpty);
    }
    expect(Directory('assets/permits').listSync().map((f) => f.path).where((p) => p.contains('FSEC') || p.contains('FSIC')), isEmpty);
  });

  test('the five reference templates are never presented as Castilla forms', () {
    const references = {
      'Architectural Permit', 'Interior Design Permit', 'Sign Permit', 'Demolition Permit', 'Certificate of Occupancy',
    };
    for (final group in permitTypeGroups) {
      for (final type in group.types) {
        expect(permitFormFor(type)!.isOfficialCastillaForm, !references.contains(type), reason: type);
      }
    }
  });

  test('the OBO checklist comes with the Building Permit and the Certificate of Occupancy only', () {
    expect(permitDocumentsFor('Building Permit'), contains(oboChecklist));
    expect(permitDocumentsFor('Certificate of Occupancy'), contains(oboChecklist));
    expect(permitDocumentsFor('Fencing Permit'), isNot(contains(oboChecklist)));
  });
}
