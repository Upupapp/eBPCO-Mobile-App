import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/models.dart';

ApplicationSummary _app(String lifecycleStatus, String applicantStatus) => ApplicationSummary.fromJson({
      'id': 'a1',
      'referenceNumber': 'E-BPCO-2026-000001',
      'permitType': 'Sign Permit',
      'applicationAction': 'New',
      'lifecycleStatus': lifecycleStatus,
      'applicantStatus': applicantStatus,
    });

void main() {
  test("the citizen's own withdrawal reads Cancelled, not Rejected", () {
    expect(_app('Cancelled', 'Rejected').statusLabel, 'Cancelled');
  });

  test('every other status shows the server projection', () {
    expect(_app('Rejected', 'Rejected').statusLabel, 'Rejected');
    expect(_app('Expired', 'Rejected').statusLabel, 'Rejected');
    expect(_app('Under Evaluation', 'Under Review').statusLabel, 'Under Review');
  });
}
