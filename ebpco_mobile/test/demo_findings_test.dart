import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/screens/applications/application_detail_screen.dart';
import 'package:ebpco_mobile/screens/home/dashboard_screen.dart';
import 'package:ebpco_mobile/screens/permits/application_wizard_screen.dart';

/// The demo recording of 5 Nov 2026, on the app's side: Home's count agrees
/// with its verb, and Review & submit counts the documents as the Documents
/// step and the Citizen Portal do.
void main() {
  group('the verb agrees with the count', () {
    test('Home: "1 application needs", "2 applications need"', () {
      expect(awaitingActionTitle(1), '1 application needs your action');
      expect(awaitingActionTitle(2), '2 applications need your action');
      expect(awaitingActionTitle(12), '12 applications need your action');
      expect(awaitingActionBody(1), 'Open it to see what the reviewing office needs from you.');
      expect(awaitingActionBody(3), 'Open them to see what the reviewing offices need from you.');
    });

    test('a replacement: "exif was removed", "exif, xmp were removed"', () {
      expect(strippedMetadataNote(const []), '');
      expect(strippedMetadataNote(const ['exif']), ' exif was removed from the file.');
      expect(strippedMetadataNote(const ['exif', 'xmp']), ' exif, xmp were removed from the file.');
    });
  });

  group('Review & submit: Documents attached', () {
    test('counts required documents only, as the Documents step does', () {
      // It read "10 of 22" with 12 if-applicable documents in the total.
      expect(reviewDocumentsCount(required: 10, attached: 10), '10 of 10 required attached');
      expect(reviewDocumentsCount(required: 3, attached: 1), '1 of 3 required attached');
      expect(reviewDocumentsCount(required: 0, attached: 0), 'None required');
    });

    test('says the if-applicable documents attached apart, and nothing when there are none', () {
      expect(ifApplicableAttachedNote(2), 'and 2 if applicable');
      expect(ifApplicableAttachedNote(1), 'and 1 if applicable');
      expect(ifApplicableAttachedNote(0), isNull);
    });
  });
}
