import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/models.dart';

DocumentEntry _doc({String? review, String? supersededBy}) => DocumentEntry.fromJson({
      'id': 'd1',
      'label': 'Valid ID of Applicant and Owner of Lot',
      'fileName': 'valid-id.pdf',
      'contentType': 'application/pdf',
      'uploadedAt': '2026-09-30T07:20:00Z',
      'reviewStatus': review,
      'supersededByDocumentId': supersededBy,
    });

void main() {
  test('Replace is offered where the office asked, never on an accepted or replaced one', () {
    expect(_doc(review: 'Revision Required').canReplaceWhile(returned: false), isTrue);
    expect(_doc(review: 'Rejected').canReplaceWhile(returned: false), isTrue);
    expect(_doc().canReplaceWhile(returned: false), isFalse);
    expect(_doc(review: 'Accepted').canReplaceWhile(returned: false), isFalse);
  });

  test('while the application is returned, any document not yet accepted can be replaced', () {
    // The office's remark can name a document it never flagged ("the Valid ID
    // is expired"); the server accepts a replacement for it.
    expect(_doc().canReplaceWhile(returned: true), isTrue);
    expect(_doc(review: 'Under Review').canReplaceWhile(returned: true), isTrue);
    // Still never where the server would refuse it.
    expect(_doc(review: 'Accepted').canReplaceWhile(returned: true), isFalse);
    expect(_doc(supersededBy: 'd2').canReplaceWhile(returned: true), isFalse);
  });
}
