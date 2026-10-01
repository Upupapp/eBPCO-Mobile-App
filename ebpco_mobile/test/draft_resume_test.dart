import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/draft_resume.dart';

/// Continue on a Draft (2026-10-01) reopens it where the citizen stopped,
/// the same as the portal's `draft-resume.ts`.
void main() {
  test('opens on the first step when the business or permit reference is not settled', () {
    expect(resumeStep(applicantDone: false, detailsDone: true, documentsDone: true), 1);
  });

  test('opens on Details when only the first step is done', () {
    expect(resumeStep(applicantDone: true, detailsDone: false, documentsDone: false), 2);
  });

  test('opens on Documents while a required document is missing', () {
    expect(resumeStep(applicantDone: true, detailsDone: true, documentsDone: false), 3);
  });

  test('opens on Review & Submit once everything is done', () {
    expect(resumeStep(applicantDone: true, detailsDone: true, documentsDone: true), 4);
  });
}
