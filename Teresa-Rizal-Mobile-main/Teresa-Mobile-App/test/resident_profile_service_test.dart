// Unit coverage for the Resident Profile completion math and status flow —
// the highest-risk part of this feature (weighted percentage calculation,
// section-status derivation, submit/verify/needs-correction transitions).
// Pure Dart, no widget pump needed.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/models/resident_profile.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';

CitizenAccount _demoAccount() => CitizenAccount(
      id: 'ESP-RES-TEST-0001',
      firstName: 'Test',
      lastName: 'Resident',
      email: 'test@example.com',
      mobile: '09171234567',
      barangay: 'Agoho',
      purok: 'Purok 1',
      address: 'Purok 1, Barangay Agoho, Teresa, Rizal',
      birthdate: '—',
      sex: '—',
      civilStatus: '—',
      occupation: '—',
      profileCompleteness: 40,
      status: 'Approved',
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a freshly seeded profile is pre-filled from the account but not yet saved/complete', () {
    final profile = ResidentProfile.seedFrom(_demoAccount());
    // Seeding pre-fills what the account already knows (name, mobile,
    // barangay, purok, address) — 6/10 personal fields, family name
    // defaulted, 3/8 household fields — so this is a specific, meaningful
    // number, not 0 and not 100.
    expect(profile.overallCompletionPercent, 65);
    expect(profile.personalStatus, SectionStatus.inProgress); // filled, but never explicitly Saved
    expect(profile.familyStatus, SectionStatus.inProgress); // familyName is pre-filled ("Resident Family")
    expect(profile.householdStatus, SectionStatus.inProgress); // barangay/address pre-filled from account
    expect(profile.readyToSubmit, isFalse); // none of the three sections have been explicitly saved yet
  });

  test('overallCompletionPercent uses the documented 40/30/30 weighting, not just the household term', () {
    // Regression guard for an operator-precedence bug caught during
    // review: `a + b + c * 100` only scales `c`, not the whole sum.
    final profile = ResidentProfile.seedFrom(_demoAccount());
    // Fill every personal-required field (10/10 -> 100% personal).
    profile.personal
      ..firstName = 'Test'
      ..lastName = 'Resident'
      ..sex = 'Male'
      ..birthdate = DateTime(1990, 1, 1)
      ..civilStatus = 'Single'
      ..mobile = '09171234567'
      ..barangay = 'Agoho'
      ..sitioPurok = 'Purok 1'
      ..completeAddress = 'Purok 1, Agoho'
      ..occupation = 'Fisherman';
    // Family: familyName already non-empty from seeding -> 100% family.
    // Household: leave completely blank -> 0% household.
    profile.household
      ..barangay = ''
      ..sitioPurok = ''
      ..completeAddress = ''
      ..housingOwnership = ''
      ..housingType = ''
      ..waterSource = ''
      ..toiletFacility = ''
      ..electricitySource = '';

    // Expected: 100%*0.4 + 100%*0.3 + 0%*0.3 = 70%, NOT 30% (the bug's
    // output when only the household term was multiplied by 100).
    expect(profile.personalCompletion, 1.0);
    expect(profile.familyCompletion, 1.0);
    expect(profile.householdCompletion, 0.0);
    expect(profile.overallCompletionPercent, 70);
  });

  test('service persists across restore and keeps profiles isolated per citizen account', () async {
    final accountA = _demoAccount();
    final accountB = CitizenAccount(
      id: 'ESP-RES-TEST-0002',
      firstName: 'Second',
      lastName: 'Resident',
      email: 'second@example.com',
      mobile: '09171234568',
      barangay: 'Labangtaytay',
      purok: 'Purok 2',
      address: 'Purok 2, Barangay Labangtaytay, Teresa, Rizal',
      birthdate: '—',
      sex: '—',
      civilStatus: '—',
      occupation: '—',
      profileCompleteness: 40,
      status: 'Approved',
    );

    final service1 = ResidentProfileService();
    await Future<void>.delayed(const Duration(milliseconds: 50)); // let async _restore() finish
    await service1.savePersonal(accountA.id, service1.profileFor(accountA).personal..firstName = 'Edited', markComplete: false);
    // accountB never touched -> should remain at its freshly-seeded state.
    final bProfile = service1.profileFor(accountB);
    expect(bProfile.personal.firstName, 'Second');

    // A brand-new service instance (simulating app restart) should restore
    // account A's edit from SharedPreferences.
    final service2 = ResidentProfileService();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(service2.profileFor(accountA).personal.firstName, 'Edited');
  });

  test('submit -> simulateVerify / simulateNeedsCorrection status flow', () async {
    final account = _demoAccount();
    final service = ResidentProfileService();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    service.profileFor(account); // every real screen reads this before any button can call submit()

    await service.submit(account.id);
    expect(service.profileFor(account).status, VerificationStatus.pendingVerification);

    await service.simulateNeedsCorrection(account.id, 'Please provide your complete Sitio / Purok.');
    expect(service.profileFor(account).status, VerificationStatus.needsCorrection);
    expect(service.profileFor(account).correctionMessage, isNotNull);

    await service.simulateVerify(account.id);
    expect(service.profileFor(account).status, VerificationStatus.verified);
    expect(service.profileFor(account).correctionMessage, isNull);
  });

  test('adding/removing family members updates householdResidentCount without duplicating the head', () async {
    final account = _demoAccount();
    final service = ResidentProfileService();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(service.profileFor(account).householdResidentCount, 1); // just the head

    final child = Individual(individualId: 'IND-1', firstName: 'Juan', relationshipToHead: 'Son', hasTeresaRizalAccount: false);
    await service.addFamilyMember(account.id, child);
    expect(service.profileFor(account).householdResidentCount, 2);
    expect(service.profileFor(account).allFamilyIndividuals.map((i) => i.individualId), contains('IND-1'));
    // The head must appear exactly once, not duplicated across
    // personal + familyMembers (Section 20's "don't duplicate" rule).
    expect(service.profileFor(account).allFamilyIndividuals.where((i) => i.individualId == account.id).length, 1);

    await service.removeFamilyMember(account.id, 'IND-1');
    expect(service.profileFor(account).householdResidentCount, 1);
  });
}
