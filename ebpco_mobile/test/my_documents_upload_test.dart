import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/screens/documents/my_documents_screen.dart';

DocumentEntry _doc(String fileName) => DocumentEntry.fromJson({
      'id': 'd1',
      'label': fileName,
      'fileName': fileName,
      'contentType': 'application/pdf',
      'uploadedAt': '2026-10-01T02:00:00Z',
    });

/// Upload on My Documents (2026-10-01), the portal's "+ Upload Document".
void main() {
  final library = [_doc('Barangay Clearance.pdf'), _doc('valid-id.jpg')];

  test('a file named like one already in My Documents is caught, whatever the case', () {
    expect(sameNameIn(library, 'barangay clearance.pdf'), 'Barangay Clearance.pdf');
    expect(sameNameIn(library, '  VALID-ID.JPG '), 'valid-id.jpg');
  });

  test('a new name goes through', () {
    expect(sameNameIn(library, 'Barangay Clearance (2).pdf'), isNull);
    expect(sameNameIn(const [], 'anything.pdf'), isNull);
  });

  test('a photo taken in the app is named for when it was taken', () {
    expect(cameraPhotoName(DateTime(2026, 10, 1, 9, 5, 7)), 'Photo 2026-10-01 09.05.07.jpg');
  });
}
