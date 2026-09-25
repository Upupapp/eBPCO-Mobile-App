import 'package:flutter/material.dart';

import '../../../theme/g6_tokens.dart';
import '../../../theme/soft_widget.dart';
import 'resident_id.dart';

enum G6Verify { verified, unverified, pending }

enum G6AvatarTone { blue, cyan, gold, lilac }

/// One person on the Pack F sample household. Frontend simulation only.
class G6Member {
  final String id;
  final String name;
  final String initials;
  final String relationship;
  final String relationshipToYou;
  final int age;
  final G6Verify verify;
  final G6AvatarTone tone;
  final String birthLabel;
  final String ageLabel;
  final String sex;
  final String? civilStatus;
  final String? mobile;
  final String? documentLabel;
  final bool minor;

  const G6Member({
    required this.id,
    required this.name,
    required this.initials,
    required this.relationship,
    required this.relationshipToYou,
    required this.age,
    required this.verify,
    required this.tone,
    required this.birthLabel,
    required this.ageLabel,
    required this.sex,
    this.civilStatus,
    this.mobile,
    this.documentLabel,
    this.minor = false,
  });

  String get firstName => name.split(' ').first;

  bool get verified => verify == G6Verify.verified;

  String get verifyLabel => switch (verify) {
    G6Verify.verified => 'Verified',
    G6Verify.unverified => 'Unverified',
    G6Verify.pending => 'Pending',
  };
}

/// Pack F sample household. The signed-in demo's older Family Information
/// form is a different screen; this list is the G6 prototype.
class G6Sample {
  G6Sample._();

  static const headName = 'Maria Santos Reyes';
  static const headInitials = 'MR';
  static const householdName = 'Reyes household';
  static const barangay = 'Dalig';
  static const purok = 'Purok 3 · Sitio Mabuhay';
  static const address = 'Purok 3, Dalig, Teresa, Rizal';
  static const validUntil = 'Sep 2027';
  static const issued = '25 Sep 2026';
  static const bloodType = 'O+';

  static const jose = G6Member(
    id: 'g6-jose',
    name: 'Jose Reyes',
    initials: 'JR',
    relationship: 'Spouse',
    relationshipToYou: 'Spouse',
    age: 36,
    verify: G6Verify.verified,
    tone: G6AvatarTone.blue,
    birthLabel: '08 Jan 1990',
    ageLabel: '36 yrs',
    sex: 'Male',
    civilStatus: 'Married',
    mobile: '09XX XXX 1180',
  );

  static const lorna = G6Member(
    id: 'g6-lorna',
    name: 'Lorna Santos',
    initials: 'LS',
    relationship: 'Mother',
    relationshipToYou: 'Parent',
    age: 64,
    verify: G6Verify.verified,
    tone: G6AvatarTone.cyan,
    birthLabel: '12 May 1962',
    ageLabel: '64 yrs',
    sex: 'Female',
    civilStatus: 'Widowed',
    mobile: '09XX XXX 2204',
  );

  static const andrea = G6Member(
    id: 'g6-andrea',
    name: 'Andrea Reyes',
    initials: 'AR',
    relationship: 'Daughter',
    relationshipToYou: 'Child',
    age: 12,
    verify: G6Verify.unverified,
    tone: G6AvatarTone.lilac,
    birthLabel: '19 Aug 2014',
    ageLabel: '12 yrs · minor',
    sex: 'Female',
    minor: true,
  );

  static const paolo = G6Member(
    id: 'g6-paolo',
    name: 'Paolo Santos Reyes',
    initials: 'PR',
    relationship: 'Son',
    relationshipToYou: 'Child',
    age: 8,
    verify: G6Verify.pending,
    tone: G6AvatarTone.gold,
    birthLabel: '03 Mar 2018',
    ageLabel: '8 yrs · minor',
    sex: 'Male',
    documentLabel: 'Birth certificate',
    minor: true,
  );

  static const members = <G6Member>[jose, lorna, andrea, paolo];

  static List<G6Member> freshMembers() => List<G6Member>.of(members);
}

/// Face of the resident Digital ID. Shots use [pack]. A signed-in account
/// uses [forAccount] so the number matches the Profile hub row.
class DigitalIdData {
  final String holderName;
  final String barangay;
  final String residentId;
  final bool sampleTagged;
  final String address;
  final String emergencyName;
  final String emergencyRole;
  final String emergencyPhone;
  final String emergencyInitials;

  const DigitalIdData({
    required this.holderName,
    required this.barangay,
    required this.residentId,
    required this.sampleTagged,
    required this.address,
    required this.emergencyName,
    required this.emergencyRole,
    required this.emergencyPhone,
    required this.emergencyInitials,
  });

  static const pack = DigitalIdData(
    holderName: G6Sample.headName,
    barangay: G6Sample.barangay,
    residentId: ResidentId.verifiedSample,
    sampleTagged: true,
    address: G6Sample.address,
    emergencyName: 'Jose Reyes',
    emergencyRole: 'Spouse',
    emergencyPhone: '09XX XXX 1180',
    emergencyInitials: 'JR',
  );

  factory DigitalIdData.forAccount({
    required String holderName,
    required String barangay,
    required String address,
    required bool verified,
  }) {
    return DigitalIdData(
      holderName: holderName,
      barangay: barangay,
      residentId: verified ? ResidentId.verifiedSample : ResidentId.blank,
      sampleTagged: verified,
      address: address,
      emergencyName: G6Sample.jose.name,
      emergencyRole: 'Spouse',
      emergencyPhone: '09XX XXX 1180',
      emergencyInitials: 'JR',
    );
  }
}

LinearGradient g6AvatarGradient(G6AvatarTone tone) {
  const end = Alignment(0.8, 1);
  const begin = Alignment(-0.8, -1);
  return switch (tone) {
    G6AvatarTone.blue => const LinearGradient(
      begin: begin,
      end: end,
      colors: [SoftColors.avatarStart, SoftColors.blue],
    ),
    G6AvatarTone.cyan => const LinearGradient(
      begin: begin,
      end: end,
      colors: [G6Palette.ice, SoftColors.cyan],
    ),
    G6AvatarTone.gold => const LinearGradient(
      begin: begin,
      end: end,
      colors: [G6Palette.lightGold, SoftColors.gold],
    ),
    G6AvatarTone.lilac => const LinearGradient(
      begin: begin,
      end: end,
      colors: [G6Palette.lilac, SoftColors.tulongInk],
    ),
  };
}
