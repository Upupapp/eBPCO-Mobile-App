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

  test('says what happened once it is released or completed, as the citizen portal does', () {
    expect(_app('Released', 'Ready for Release').statusLabel, 'Released');
    expect(_app('Completed', 'Ready for Release').statusLabel, 'Completed');
    expect(_app('For Approval', 'Payment Verification').statusLabel, 'Payment Verified');
  });

  test('says when the application is waiting on the citizen', () {
    expect(_app('Revision Required', 'Under Review').statusLabel, 'Revision Required');
    expect(_app('Assessed', 'Payment Verification').statusLabel, 'Awaiting Payment');
  });

  test('every other status shows the server projection', () {
    expect(_app('Rejected', 'Rejected').statusLabel, 'Rejected');
    expect(_app('Expired', 'Rejected').statusLabel, 'Rejected');
    expect(_app('Under Evaluation', 'Under Review').statusLabel, 'Under Review');
  });
}
