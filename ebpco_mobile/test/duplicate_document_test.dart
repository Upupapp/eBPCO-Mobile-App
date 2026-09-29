import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/core/api/problem.dart';
import 'package:ebpco_mobile/domain/models.dart';

/// The same file twice (ebpco-api 061): the server refuses a second upload of
/// a file the citizen already has, names their copy, and lists each file once.
void main() {
  final duplicate = ApiError(
    409,
    Problem.fromJson({
      'type': '/problems/conflict',
      'title': 'You already have this file',
      'status': 409,
      'detail': 'You already uploaded this file ("valid-id.pdf"). Reuse it from My Documents instead of uploading it again.',
      'reason': 'duplicate-document',
      'existingDocument': {'id': 'doc-1', 'fileName': 'valid-id.pdf', 'label': 'Valid ID', 'applicationReference': null},
    }),
    false,
  );

  test('names the copy the citizen already has', () {
    expect(duplicateOf(duplicate)?.id, 'doc-1');
    expect(duplicateOf(duplicate)?.fileName, 'valid-id.pdf');
  });

  test('is null for any other refusal', () {
    expect(duplicateOf(ApiError(409, Problem.fromJson({'detail': 'Already decided.'}), false)), isNull);
    expect(duplicateOf(ApiError(404, null, true)), isNull);
    expect(duplicateOf(Exception('offline')), isNull);
  });

  DocumentEntry entry(Map<String, dynamic> extra) => DocumentEntry.fromJson({
        'id': 'doc-1',
        'label': 'Valid ID',
        'fileName': 'valid-id.pdf',
        'contentType': 'application/pdf',
        'uploadedAt': '2026-09-28T00:00:00.000Z',
        'applicationId': null,
        'applicationReference': null,
        ...extra,
      });

  test('one file used on several applications names them all', () {
    final doc = entry({
      'applications': [
        {'id': 'a1', 'referenceNumber': 'E-BPCO-2026-000001'},
        {'id': 'a2', 'referenceNumber': 'E-BPCO-2026-000002'},
      ],
      'copies': 3,
    });
    expect(doc.usedOnLabel, 'E-BPCO-2026-000001, E-BPCO-2026-000002');
  });

  test('an older server, or a file on nothing, still reads', () {
    expect(entry({'applicationReference': 'E-BPCO-2026-000009'}).usedOnLabel, 'E-BPCO-2026-000009');
    expect(entry({}).usedOnLabel, isNull);
  });
}
