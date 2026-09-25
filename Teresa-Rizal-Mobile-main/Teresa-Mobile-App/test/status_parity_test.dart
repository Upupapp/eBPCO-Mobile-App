// The status vocabulary is shared with the Web Admin, and drift in either
// direction is a wrong answer to the only question a citizen is asking: what is
// happening to my application.
//
// The canonical set below is transcribed from the web platform's
// `resources/views/components/ui/badge.blade.php` as it stands on **origin/main**,
// measured 2026-08-29. That distinction is the whole point of this file: a web
// clone even a few dozen commits stale still contains `Waiting Requirements` and
// `Ready for Release`, labels since replaced, and comparing against it makes
// mobile look correct when it is not. It is transcribed rather than imported
// because the two projects are separate repositories — so when this test fails,
// re-read `badge.blade.php` on origin/main, do not "fix" the expectation.
//
// Note it lists 17 labels. Both projects' CLAUDE.md prose lists say 15; they
// omit `Verified` and `Unverified`. The component is what renders, so the
// component wins — see feedback in FE04_STATUS_PARITY.md.
import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/access_level.dart';
import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/theme/app_status.dart';

CitizenAccount _accountWith(String status) => CitizenAccount(
      id: 'ESP-TEST-1',
      firstName: 'Test',
      lastName: 'Resident',
      email: 'test@example.com',
      mobile: '0900 000 0000',
      barangay: 'Poblacion',
      purok: 'Purok 1',
      address: 'Purok 1, Brgy. Poblacion',
      birthdate: '—',
      sex: '—',
      civilStatus: '—',
      occupation: '—',
      profileCompleteness: 100,
      status: status,
    );

/// Every key of `$styles` in `badge.blade.php` on the web repo's origin/main.
const _canonical = <String>{
  'Draft',
  'Submitted',
  'Pending Review',
  'Under Verification',
  'Assigned',
  'Processing',
  'Under Review',
  'Resubmitted',
  'Approved',
  'Verified',
  'Unverified',
  'Rejected',
  'Mark to Release',
  'Released',
  'Completed',
  'Cancelled',
  'Archived',
};

/// Labels mobile carries that the web platform does not.
///
/// Every entry needs a written, dated decision naming who agreed it. An entry
/// without one is drift wearing a permission slip.
const _mobileOnlyPendingDecision = <String, String>{
  // 2026-08-29 — NOT YET AGREED. Escalated, not decided: retiring it is a
  // mobile change, adopting it is a request to the web team, and neither is a
  // call this lane can make alone. It is already inert in practice —
  // `requests_service.dart` migrates it to `Under Review` on load, so no live
  // request can carry it — but the enum value still exists and five call sites
  // still reference it. See FE04_STATUS_PARITY.md.
  'Waiting Requirements': 'PENDING OWNER DECISION — see FE04_STATUS_PARITY.md',
};

void main() {
  final mobileLabels = AppStatus.values.map((s) => s.label).toSet();

  test('every canonical web status exists in mobile', () {
    final missing = _canonical.difference(mobileLabels).toList()..sort();
    expect(
      missing,
      isEmpty,
      reason:
          'These statuses render on the Web Admin but have no AppStatus value:\n'
          '  ${missing.join('\n  ')}\n'
          'A citizen would see them degrade to a grey "Draft" via fromLabel.',
    );
  });

  test('mobile invents no status the web platform does not have', () {
    final extra = mobileLabels.difference(_canonical).toList()..sort();
    final undecided = extra.where((l) => !_mobileOnlyPendingDecision.containsKey(l)).toList();
    expect(
      undecided,
      isEmpty,
      reason:
          'Mobile-only status labels with no recorded decision:\n'
          '  ${undecided.join('\n  ')}\n'
          'Both projects state the same rule: never invent a status label.',
    );
  });

  test('the pending-decision list has not gone stale', () {
    // If a label here is no longer in the enum, the decision was made and the
    // entry should go with it — otherwise this file keeps asserting a
    // difference that no longer exists.
    for (final label in _mobileOnlyPendingDecision.keys) {
      expect(
        mobileLabels,
        contains(label),
        reason: '"$label" is listed as pending but is no longer in AppStatus — remove the entry',
      );
    }
  });

  test('no two statuses share a label', () {
    expect(
      mobileLabels.length,
      AppStatus.values.length,
      reason: 'two AppStatus values resolve to the same label, so fromLabel can never return one of them',
    );
  });

  group('fromLabel', () {
    test('round-trips every status', () {
      for (final status in AppStatus.values) {
        expect(AppStatusX.fromLabel(status.label), status, reason: '${status.label} does not round-trip');
      }
    });

    test('Resubmitted no longer silently degrades to Draft', () {
      // The regression this whole command exists for: requests_service writes
      // 'Resubmitted' into statusHistory as a literal, and it used to come back
      // as a grey Draft.
      expect(AppStatusX.fromLabel('Resubmitted'), AppStatus.resubmitted);
      expect(AppStatusX.fromLabel('Resubmitted'), isNot(AppStatus.draft));
    });
  });

  group('access level — the hazard this command actually closes', () {
    // The Web Admin stores `Approved` and DISPLAYS `Verified`, and its own
    // comment says `Verified` grants full Dokyu/Tulong access. Mobile resolves
    // an account through fromLabel, so before `verified` existed here the same
    // word granted access on one surface and denied it on the other.
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<AccessLevel> levelFor(String status) async {
      final session = CitizenSessionService();
      await session.login(_accountWith(status));
      return session.accessLevel;
    }

    test('an Approved account is verified', () async {
      expect(await levelFor('Approved'), AccessLevel.verified);
    });

    test('a Verified account is verified, not locked out of Dokyu', () async {
      expect(await levelFor('Verified'), AccessLevel.verified);
    });

    test('a Pending Review account is still unverified', () async {
      expect(await levelFor('Pending Review'), AccessLevel.unverified);
    });

    test('AccessLevel still has exactly the three levels the app branches on', () {
      expect(AccessLevel.values, hasLength(3));
    });
  });
}
