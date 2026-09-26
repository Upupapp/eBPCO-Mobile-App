import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/screens/documents/my_documents_screen.dart';

DocumentEntry _doc({required String label, required String fileName, String? reference, String? review}) =>
    DocumentEntry.fromJson({
      'id': 'd1',
      'label': label,
      'fileName': fileName,
      'contentType': 'application/pdf',
      'uploadedAt': '2026-09-26T07:20:00Z',
      'applicationReference': reference,
      'reviewStatus': review,
    });

void main() {
  final fire = _doc(
    label: 'Fire Safety Evaluation Clearance',
    fileName: 'fsec-scan.pdf',
    reference: 'E-BPCO-2026-000031',
    review: 'Accepted',
  );

  test('an empty search shows everything', () {
    expect(matchesDocumentSearch(fire, ''), isTrue);
    expect(matchesDocumentSearch(fire, '   '), isTrue);
  });

  test('matches the name, the file name, the reference and the review status, ignoring case', () {
    expect(matchesDocumentSearch(fire, 'fire safety'), isTrue);
    expect(matchesDocumentSearch(fire, 'FSEC-SCAN'), isTrue);
    expect(matchesDocumentSearch(fire, '000031'), isTrue);
    expect(matchesDocumentSearch(fire, 'accepted'), isTrue);
  });

  test('every word typed has to match, in any field and any order', () {
    expect(matchesDocumentSearch(fire, 'accepted fire'), isTrue);
    expect(matchesDocumentSearch(fire, 'fire road'), isFalse);
  });

  test('a document not yet on an application or reviewed still searches by name', () {
    final loose = _doc(label: 'Barangay Clearance', fileName: 'brgy.jpg');
    expect(matchesDocumentSearch(loose, 'barangay'), isTrue);
    expect(matchesDocumentSearch(loose, 'accepted'), isFalse);
  });
}
