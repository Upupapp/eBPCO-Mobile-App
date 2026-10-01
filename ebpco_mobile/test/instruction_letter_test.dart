import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/models.dart';

void main() {
  test('a Letter of Instruction reads the office\'s own remark, as the server sends it', () {
    // Recorded from the live API (E-BPCO-2026-000074, 2026-10-01).
    final letter = InstructionLetter.fromJson({
      'letterId': 'ab137281-3c18-43bc-99eb-a9e37bc93e26',
      'issuedAt': '2026-09-30T09:26:49.386Z',
      'items': [
        {
          'id': 'ac24a4e1-5f41-4bce-94ad-05a949d02fc5',
          'subject': 'What the office needs',
          'remark': 'The Valid ID is expired. Please upload a current government-issued ID.',
          'resolvedAt': null,
        },
      ],
    });
    expect(letter.items.single.remark, contains('Valid ID is expired'));
    expect(letter.items.single.resolvedAt, isNull);
  });

  test('a letter with no items is read as empty, not an error', () {
    expect(InstructionLetter.fromJson({'letterId': 'x', 'issuedAt': '2026-10-01T00:00:00Z'}).items, isEmpty);
  });
}
