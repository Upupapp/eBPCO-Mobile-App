/// Account verification (ebpco-api migration 067, owner request 2026-10-21):
/// anyone can sign up and sign in, but the Municipality checks a valid
/// government ID before an account can submit applications. Until then the
/// citizen can still prepare drafts, register businesses and edit the
/// profile. Same rules and words as the citizen portal.
library;

import 'dart:convert';
import 'dart:typed_data';

import '../core/api/problem.dart';
import 'profile_photo.dart';

/// The valid IDs the Municipality accepts, word for word what the server
/// takes as `idType` (`ACCEPTED_IDS` in citizen-verification.service.ts).
const acceptedIdTypes = <String>[
  'PhilSys National ID (PhilID / ePhilID)',
  'Passport',
  "Driver's License",
  'UMID',
  'SSS ID',
  'GSIS eCard',
  'PRC ID',
  'Postal ID',
  "Voter's ID / Voter's Certification",
  'PhilHealth ID',
  'TIN ID',
  'Senior Citizen ID',
  'PWD ID',
  'Other government-issued ID with photo',
];

/// The server's cap on each ID photo.
const maxIdPhotoBytes = 8 * 1024 * 1024;

/// What the citizen said at sign-up they will mainly apply for. Only a
/// starting point: every application asks again.
const registeredAsResidential = 'residential';
const registeredAsBusiness = 'business';
const registeredAsBoth = 'both';

/// Where the account stands: `unsubmitted`, `pending`, `verified` or
/// `rejected`. [note] is the reason when rejected, shown word for word.
class AccountVerification {
  final String status;
  final String? submittedAt;
  final String? decidedAt;
  final String? note;
  final String? idType;

  const AccountVerification({
    required this.status,
    this.submittedAt,
    this.decidedAt,
    this.note,
    this.idType,
  });

  factory AccountVerification.fromJson(Map<String, dynamic> json) => AccountVerification(
        status: json['status'] as String? ?? 'unsubmitted',
        submittedAt: json['submittedAt'] as String?,
        decidedAt: json['decidedAt'] as String?,
        note: json['note'] as String?,
        idType: json['idType'] as String?,
      );

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';

  /// The reason the ID was returned, or null when none was given.
  String? get reason => isRejected && (note?.trim().isNotEmpty ?? false) ? note!.trim() : null;
}

/// Whether this account may submit applications. No verification record at
/// all (an older server) never blocks: the server is the one that refuses.
bool accountCanSubmit(AccountVerification? verification) => verification == null || verification.isVerified;

/// The status chip's words.
String verificationStatusLabel(String status) => switch (status) {
      'verified' => 'Verified',
      'pending' => 'Waiting for verification',
      'rejected' => 'ID not accepted',
      _ => 'No ID yet',
    };

/// "Your ID was not accepted: [reason]." — the officer's reason word for word,
/// with a full stop only when it has none; without the reason when none was
/// given. The portal's `rejectedHeadline`.
String notAcceptedMessage(AccountVerification verification) {
  final reason = verification.reason;
  if (reason == null) return 'Your ID was not accepted.';
  return 'Your ID was not accepted: $reason${RegExp(r'[.!?]$').hasMatch(reason) ? '' : '.'}';
}

/// The banner on Home, Permit Services and the application wizard while the
/// account is not verified; null once it is (or when the server sent no
/// verification at all). The portal's `VerificationBannerComponent`, word for
/// word. [action] is the button's label, or null when there is nothing to do
/// but wait.
({String title, String? body, String? action})? verificationBanner(AccountVerification? verification) {
  if (verification == null || verification.isVerified) return null;
  if (verification.isPending) {
    return (
      title: 'Your account is being verified.',
      body: 'You can prepare applications now and submit once it is verified.',
      action: null,
    );
  }
  if (verification.isRejected) {
    return (title: notAcceptedMessage(verification), body: null, action: 'Upload again');
  }
  return (
    title: 'Verify your account to submit applications.',
    body: 'Send a photo of a valid government ID. You can prepare applications while the Municipality checks it.',
    action: 'Verify my account',
  );
}

/// Why the wizard's Review step offers Save as Draft instead of Submit; null
/// when the account may submit. The portal's `submitBlockedMessage`.
String? filingBlockedMessage(AccountVerification? verification) {
  if (verification == null || verification.isVerified) return null;
  if (verification.isPending) {
    return 'Your account is being verified. You can prepare applications now and submit once it is verified.';
  }
  if (verification.isRejected) {
    return '${notAcceptedMessage(verification)} Upload your ID again under Profile > Account verification.';
  }
  return 'Verify your account to submit applications: upload a valid government ID under Profile > Account verification.';
}

/// What is still missing from the Valid ID form, worded for the citizen, or
/// null when it can be sent.
String? validIdProblem({required String? idType, required String idNumber, required bool hasFront}) {
  if (idType == null || !acceptedIdTypes.contains(idType)) return 'Choose the type of ID.';
  final number = idNumber.trim();
  if (number.isEmpty) return 'Enter the ID number.';
  if (number.length < 3 || number.length > 40) return 'Enter the ID number exactly as printed on the ID.';
  if (!hasFront) return 'Add a photo of the front of the ID.';
  return null;
}

/// A picked ID photo made ready to send: upright, no metadata, large enough
/// for the officer to read the small print. JPEG, or PNG when it has
/// transparency. Null when the bytes are not an image.
PreparedPhoto? prepareIdPhoto(Uint8List original) {
  final prepared = prepareProfilePhoto(original, maxSide: 2000);
  if (prepared == null) return null;
  final extension = prepared.fileName.endsWith('.png') ? 'png' : 'jpg';
  return (bytes: prepared.bytes, fileName: 'valid-id.$extension');
}

/// The `PUT /me/verification` body. Each side is named for what it is, keeping
/// the extension that matches its bytes (the server compares the two).
Map<String, dynamic> verificationRequestBody({
  required String idType,
  required String idNumber,
  required PreparedPhoto front,
  PreparedPhoto? back,
}) {
  Map<String, String> image(PreparedPhoto photo, String side) {
    final extension = photo.fileName.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
    return {'fileName': 'id-$side.$extension', 'contentBase64': base64Encode(photo.bytes)};
  }

  return {
    'idType': idType,
    'idNumber': idNumber.trim(),
    'front': image(front, 'front'),
    'back': back == null ? null : image(back, 'back'),
  };
}

/// What to tell the citizen when an ID upload is refused. A bad file comes
/// back as a 400 whose reason is in `errors[].message`, not in `detail`.
String verificationUploadMessage(ApiError error) {
  if (error.status == 400) {
    final messages = error.problem?.fieldErrors.map((e) => e.message).where((m) => m.trim().isNotEmpty);
    if (messages != null && messages.isNotEmpty) return messages.first;
  }
  return error.citizenMessage;
}
