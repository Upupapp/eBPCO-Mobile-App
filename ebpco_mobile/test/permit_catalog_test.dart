import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/permit_catalog.dart';

void main() {
  test('the catalog offers no FSEC or FSIC: the BFP issues those through BFP-FSIS', () {
    final offered = permitTypeGroups.expand((group) => group.types).toList();
    for (final retired in retiredPermitTypes) {
      expect(offered, isNot(contains(retired)));
    }
    expect(offered, contains('Certificate of Occupancy'));
    expect(bfpFsisUrl, 'https://fsis.e-bfp.com');
  });

  test('every type the catalog offers is a known permit type', () {
    for (final type in permitTypeGroups.expand((group) => group.types)) {
      expect(allPermitTypes, contains(type));
    }
  });
}
