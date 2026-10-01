import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/permit_forms.dart';

/// A blank form is offered only where a requirement asks the citizen to fill
/// one in and upload it (2026-10-01): the Building Permit's Unified Building
/// Permit Form and its ancillary forms. Every other permit is filed online.
void main() {
  test('the Unified Building Permit Form and each ancillary form have their blank form', () {
    for (final code in [
      'bpnc-unified-form', 'bpnc-ancillary-electrical', 'bpnc-ancillary-fencing', 'bpnc-ancillary-architectural',
      'bpnc-ancillary-sanitary-plumbing', 'bpnc-ancillary-mechanical', 'bpnc-ancillary-civil-structural',
      'bpnc-ancillary-excavation', 'bpnc-ancillary-electronics',
    ]) {
      expect(blankFormFor(code), isNotNull, reason: code);
    }
  });

  test('a requirement that is not a form gets no form', () {
    for (final code in ['bpnc-valid-id', 'bpnc-survey-plan', 'fsec', '']) {
      expect(blankFormFor(code), isNull, reason: code);
    }
  });

  test('every form is bundled, and nothing bundled goes unused', () {
    final bundled = Directory('assets/permits').listSync().map((f) => f.uri.pathSegments.last).toSet();
    final used = allBlankForms.map((f) => f.fileName).toSet();
    expect(bundled, used);
  });

  test('the Architectural form is a reference template, never presented as Castilla\'s', () {
    expect(blankFormFor('bpnc-ancillary-architectural')!.isOfficialCastillaForm, isFalse);
    expect(blankFormFor('bpnc-unified-form')!.isOfficialCastillaForm, isTrue);
  });
}
