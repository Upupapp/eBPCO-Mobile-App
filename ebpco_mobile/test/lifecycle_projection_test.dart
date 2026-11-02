import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/theme/app_status.dart';

/// The mobile side of eBPCOBackend's `lifecycle-engine.spec.ts` contract
/// block: the app's own status model held to `test/contract/
/// lifecycle-projection.json`, a verbatim copy of the server's NORMATIVE
/// `apps/ebpco-api/test/contract/lifecycle-projection.json` (last copied at
/// ebpco-api 1f98bc8, migration 070: Out for Delivery). When the server adds a
/// status, copy the file again; this test then names what the app is missing.
void main() {
  final contract = jsonDecode(File('test/contract/lifecycle-projection.json').readAsStringSync()) as Map<String, dynamic>;
  final projection = (contract['projection'] as Map<String, dynamic>).map(
    (status, row) => MapEntry(status, row as Map<String, dynamic>),
  );

  test('is the fixture this test was written against', () {
    expect(contract['contractVersion'], '0.1.0');
    expect(projection, hasLength(20));
  });

  test('the app knows exactly the statuses the server has', () {
    expect(LifecycleStatus.values.map((status) => status.label).toSet(), projection.keys.toSet());
  });

  test('each status projects onto the applicant status the contract says', () {
    for (final MapEntry(key: label, value: row) in projection.entries) {
      final status = LifecycleStatusX.tryFromLabel(label);
      expect(status, isNotNull, reason: label);
      expect(ApplicantStatusX.fromLifecycle(status!).label, row['applicantStatus'], reason: label);
    }
  });

  test('the seven applicant statuses are the app\'s own', () {
    final applicantStatuses = (contract['applicantStatuses'] as List<dynamic>).cast<String>().toSet();
    expect(ApplicantStatus.values.map((status) => status.label).toSet(), applicantStatuses);
  });

  test('what the app calls closed is what the contract calls terminal', () {
    final terminal = {
      for (final MapEntry(key: label, value: row) in projection.entries)
        if (row['terminal'] == true) label,
    };
    expect(closedStatuses, terminal);
  });

  test('Out for Delivery is the release step, waiting on nobody', () {
    final row = projection['Out for Delivery']!;
    expect(row['applicantStatus'], 'Ready for Release');
    expect(row['requiresApplicantAction'], isFalse);
    expect(row['terminal'], isFalse);
    expect(journeySteps[LifecycleStatus.outForDelivery.journeyStep!], 'Release');
  });
}
