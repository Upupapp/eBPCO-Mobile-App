import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/legal_copy.dart';
import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/domain/registration_number.dart';
import 'package:ebpco_mobile/screens/applications/my_applications_screen.dart';
import 'package:ebpco_mobile/screens/permits/application_wizard_screen.dart';

/// The QA run of 2026-10-03, on the app's side: the same rules the citizen
/// portal now follows, so the two never disagree.
ApplicationSummary _app(String lifecycleStatus, {String reference = 'E-BPCO-2026-000001', String? businessId}) =>
    ApplicationSummary.fromJson({
      'id': 'a-$lifecycleStatus',
      'referenceNumber': reference,
      'permitType': 'Sign Permit',
      'applicationAction': 'New',
      'businessId': businessId,
      'lifecycleStatus': lifecycleStatus,
      'applicantStatus': 'Ready for Release',
    });

void main() {
  group('TC-37: a draft has no official number', () {
    test('shows a DRAFT- placeholder as "no number yet"', () {
      final draft = _app('Draft', reference: 'DRAFT-1A2B3C4D5E');
      expect(draft.hasOfficialReference, isFalse);
      expect(draft.displayReference, 'Draft (no number yet)');
    });

    test('shows a filed number as it is', () {
      expect(_app('Submitted').displayReference, 'E-BPCO-2026-000001');
    });
  });

  group('TC-33 / TC-35: what is active, and the filter chips', () {
    test('a completed, withdrawn, rejected or expired application is closed', () {
      for (final status in ['Completed', 'Cancelled', 'Rejected', 'Expired']) {
        expect(_app(status).isClosed, isTrue, reason: status);
      }
      expect(_app('Released').isClosed, isFalse);
      expect(_app('Under Evaluation').isClosed, isFalse);
    });

    test('Completed, Cancelled and Revision Required each list only their own', () {
      expect(inApplicationFilter(_app('Completed'), 'Completed'), isTrue);
      expect(inApplicationFilter(_app('Released'), 'Completed'), isFalse);
      expect(inApplicationFilter(_app('Cancelled'), 'Cancelled'), isTrue);
      expect(inApplicationFilter(_app('Revision Required'), 'Revision Required'), isTrue);
      expect(inApplicationFilter(_app('Revision Required'), 'Under Review'), isFalse);
      expect(inApplicationFilter(_app('Completed'), 'All'), isTrue);
    });
  });

  group('TC-24: the business registration number', () {
    test('refuses what cannot be one', () {
      for (final bad in ['x', 'abcd', 'ABC-12', '#1234-5678']) {
        expect(registrationNumberProblem(bad), isNotNull, reason: bad);
      }
    });

    test('accepts DTI, SEC and CDA style numbers', () {
      for (final good in ['3456789', 'CS201912345', 'DTI-2024-000123', '9520-12345678']) {
        expect(registrationNumberProblem(good), isNull, reason: good);
      }
    });

    test('is the owner\'s to correct only until an application reaches the office', () {
      expect(registrationLockedBy([_app('Draft', businessId: 'b1')], 'b1'), isFalse);
      expect(registrationLockedBy([_app('Submitted', businessId: 'b1')], 'b1'), isTrue);
      expect(registrationLockedBy([_app('Submitted', businessId: 'b2')], 'b1'), isFalse);
    });
  });

  group('TC-32 / TC-21: the wizard', () {
    test('a PRC licence number is seven digits, and optional', () {
      expect(prcNumberProblem(''), isNull);
      expect(prcNumberProblem('0012345'), isNull);
      expect(prcNumberProblem('abc'), isNotNull);
      expect(prcNumberProblem('12345678'), isNotNull);
    });

    test('names where the same file is already attached', () {
      expect(sameFileMessage('title.pdf', 'Land Title', 'Survey Plan'),
          '"title.pdf" is already attached as "Land Title". Attach the right file for "Survey Plan".');
    });
  });

  test('TC-04: the permit carries its validity and who approved it', () {
    final permit = PermitInfo.fromJson({
      'permitNumber': 'BP-2026-000001',
      'issuedDate': '2026-10-03T00:00:00.000Z',
      'scope': null,
      'conditions': <String>[],
      'release': null,
      'expiresOn': '2027-10-03',
      'approvingOfficial': 'Engr. Juan Dela Cruz',
      'approvingOffice': 'Office of the Building Official',
    });
    expect(permit.expiresOn, '2027-10-03');
    expect(permit.approvingOfficial, 'Engr. Juan Dela Cruz');
    expect(permit.approvingOffice, 'Office of the Building Official');
  });

  test('TC-36: the terms are more than one sentence, and invent no fee or deadline', () {
    final headings = termsSections.map((s) => s.heading).toList();
    for (final heading in ['Your account', 'What you submit', 'Fees and payment', 'Your permit', 'Your data']) {
      expect(headings, contains(heading));
    }
    final text = termsSections.expand((s) => s.paragraphs).join('\n');
    expect(text, isNot(contains('₱')));
    expect(privacyPolicySections.expand((s) => s.paragraphs).join('\n'), isNot(contains('does not yet check')));
  });
}
