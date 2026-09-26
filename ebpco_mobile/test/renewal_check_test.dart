import 'package:ebpco_mobile/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /applications/renewal-check` — the wizard reads `message` straight
/// into the error under the permit number field, and the matched permit into
/// the "Permit found" line, so both shapes must parse exactly as the server
/// sends them (see the backend's contract/citizen-endpoints.openapi.yaml).
void main() {
  test('a matching permit carries what the citizen can recognise it by', () {
    final check = RenewalCheck.fromJson({
      'valid': true,
      'permit': {
        'permitNumber': 'BP-2025-000042',
        'permitType': 'Building Permit',
        'businessName': 'Veggie Like',
        'issuedDate': '2025-03-03T00:00:00.000Z',
      },
    });

    expect(check.valid, isTrue);
    expect(check.permitNumber, 'BP-2025-000042');
    expect(check.permitType, 'Building Permit');
    expect(check.businessName, 'Veggie Like');
    expect(check.message, isNull);
  });

  test('a refused number carries the reason and the message to show under the field', () {
    final check = RenewalCheck.fromJson({
      'valid': false,
      'reason': 'permit-not-found',
      'message': 'Permit number "BP" does not exist under your account.',
    });

    expect(check.valid, isFalse);
    expect(check.reason, 'permit-not-found');
    expect(check.message, contains('does not exist'));
    expect(check.permitNumber, isNull);
  });
}
