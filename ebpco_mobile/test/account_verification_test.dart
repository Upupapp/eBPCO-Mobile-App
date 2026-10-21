import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:ebpco_mobile/core/api/problem.dart';
import 'package:ebpco_mobile/domain/account_verification.dart';
import 'package:ebpco_mobile/domain/models.dart';
import 'package:ebpco_mobile/screens/auth/registration_success_screen.dart';

/// Account verification (ebpco-api 067): the Municipality checks a valid ID
/// before an account can submit applications. Same rules as the portal.
Map<String, dynamic> _me({Object? verification, String? registeredAs}) => {
      'id': 'acc-1',
      'email': 'juan@example.com',
      'emailVerifiedAt': null,
      'mobileVerifiedAt': null,
      'firstName': 'Juan',
      'lastName': 'Dela Cruz',
      'registeredAs': registeredAs,
      'verification': verification,
    };

AccountVerification _v(String status, {String? note}) => AccountVerification(status: status, note: note);

void main() {
  group('GET /me', () {
    test('reads the verification and what the citizen registered as', () {
      final me = MeProfile.fromJson(_me(
        registeredAs: 'both',
        verification: {
          'status': 'rejected',
          'submittedAt': '2026-10-21T01:00:00Z',
          'decidedAt': '2026-10-21T03:00:00Z',
          'note': 'The photo is blurred.',
          'idType': 'Passport',
        },
      ));
      expect(me.registeredAs, 'both');
      expect(me.verification!.status, 'rejected');
      expect(me.verification!.isRejected, isTrue);
      expect(me.verification!.reason, 'The photo is blurred.');
      expect(me.verification!.idType, 'Passport');
      expect(me.verification!.submittedAt, '2026-10-21T01:00:00Z');
    });

    test('an older server sends neither, and nothing is blocked', () {
      final json = _me()..remove('verification')..remove('registeredAs');
      final me = MeProfile.fromJson(json);
      expect(me.registeredAs, isNull);
      expect(me.verification, isNull);
      expect(accountCanSubmit(me.verification), isTrue);
      expect(verificationBanner(me.verification), isNull);
      expect(filingBlockedMessage(me.verification), isNull);
    });
  });

  test('only a verified account may submit', () {
    expect(accountCanSubmit(_v('verified')), isTrue);
    for (final status in ['unsubmitted', 'pending', 'rejected']) {
      expect(accountCanSubmit(_v(status)), isFalse, reason: status);
    }
  });

  test('the status chip reads in plain words', () {
    expect(verificationStatusLabel('unsubmitted'), 'No ID yet');
    expect(verificationStatusLabel('pending'), 'Waiting for verification');
    expect(verificationStatusLabel('verified'), 'Verified');
    expect(verificationStatusLabel('rejected'), 'ID not accepted');
  });

  group('the Home banner', () {
    test('asks for an ID when none was sent', () {
      final banner = verificationBanner(_v('unsubmitted'))!;
      expect(banner.title, 'Verify your account to submit applications');
      expect(banner.action, isNotNull);
    });

    test('says to wait, with nothing to press, while the ID is checked', () {
      final banner = verificationBanner(_v('pending'))!;
      expect(banner.title, 'Your account is being verified.');
      expect(banner.body, 'You can prepare applications now and submit once it is verified.');
      expect(banner.action, isNull);
    });

    test('gives the reason, word for word, when the ID was not accepted', () {
      final banner = verificationBanner(_v('rejected', note: 'The ID has expired.'))!;
      expect(banner.title, 'Your ID was not accepted: The ID has expired.');
      expect(banner.action, 'Upload again');
      expect(notAcceptedMessage(_v('rejected')), 'Your ID was not accepted.');
    });

    test('is gone once verified', () {
      expect(verificationBanner(_v('verified')), isNull);
    });
  });

  test('the wizard says the draft is kept when it cannot be submitted yet', () {
    expect(filingBlockedMessage(_v('verified')), isNull);
    expect(filingBlockedMessage(_v('pending')), contains('still being verified'));
    expect(filingBlockedMessage(_v('unsubmitted')), contains('Profile > Account verification'));
    expect(filingBlockedMessage(_v('rejected', note: 'Blurred.')), startsWith('Your ID was not accepted: Blurred.'));
    for (final status in ['pending', 'unsubmitted', 'rejected']) {
      expect(filingBlockedMessage(_v(status)), contains('Your draft is saved'), reason: status);
    }
  });

  group('the Valid ID form', () {
    test('needs an accepted type, a number and the front', () {
      expect(validIdProblem(idType: null, idNumber: '123', hasFront: true), 'Choose the type of ID.');
      expect(validIdProblem(idType: 'Library card', idNumber: '123', hasFront: true), 'Choose the type of ID.');
      expect(validIdProblem(idType: 'Passport', idNumber: '  ', hasFront: true), 'Enter the ID number.');
      expect(validIdProblem(idType: 'Passport', idNumber: 'P1', hasFront: true), isNotNull);
      expect(validIdProblem(idType: 'Passport', idNumber: 'x' * 41, hasFront: true), isNotNull);
      expect(validIdProblem(idType: 'Passport', idNumber: 'P1234567A', hasFront: false), 'Add a photo of the front of the ID.');
      expect(validIdProblem(idType: 'Passport', idNumber: 'P1234567A', hasFront: true), isNull);
    });

    test('offers exactly the IDs the server accepts', () {
      expect(acceptedIdTypes, hasLength(14));
      expect(acceptedIdTypes.first, 'PhilSys National ID (PhilID / ePhilID)');
      expect(acceptedIdTypes, contains("Voter's ID / Voter's Certification"));
      expect(acceptedIdTypes.last, 'Other government-issued ID with photo');
    });
  });

  group('PUT /me/verification', () {
    test('sends both sides as base64, named for what they are', () {
      final front = (bytes: Uint8List.fromList([1, 2, 3]), fileName: 'valid-id.jpg');
      final back = (bytes: Uint8List.fromList([4, 5]), fileName: 'valid-id.png');
      final body = verificationRequestBody(idType: 'UMID', idNumber: ' 0028-1234567-8 ', front: front, back: back);
      expect(body['idType'], 'UMID');
      expect(body['idNumber'], '0028-1234567-8');
      expect(body['front'], {'fileName': 'id-front.jpg', 'contentBase64': base64Encode([1, 2, 3])});
      expect(body['back'], {'fileName': 'id-back.png', 'contentBase64': base64Encode([4, 5])});
    });

    test('sends no back when there is none', () {
      final front = (bytes: Uint8List.fromList([1]), fileName: 'valid-id.jpg');
      final body = verificationRequestBody(idType: 'Passport', idNumber: 'P123', front: front);
      expect(body.containsKey('back'), isTrue);
      expect(body['back'], isNull);
    });

    test('a refused file says why, from the field error', () {
      final error = problemFrom({
        'title': 'The request did not validate',
        'status': 400,
        'errors': [
          {'pointer': '/front', 'message': 'Upload a photo of the ID (JPEG or PNG), not a PDF.'},
        ],
      }, 400);
      expect(verificationUploadMessage(error), 'Upload a photo of the ID (JPEG or PNG), not a PDF.');
    });

    test('any other refusal uses its detail', () {
      final error = problemFrom({'title': 'A precondition is unmet', 'detail': 'This account is already verified.'}, 409);
      expect(verificationUploadMessage(error), 'This account is already verified.');
    });
  });

  group('an ID photo', () {
    test('keeps enough detail to read and leaves its metadata behind', () {
      final photo = img.Image(width: 3000, height: 1500);
      photo.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(12, 1);
      final prepared = prepareIdPhoto(img.encodeJpg(photo))!;
      final result = img.decodeJpg(prepared.bytes)!;
      expect((result.width, result.height), (2000, 1000));
      expect(result.exif.gpsIfd.isEmpty, isTrue);
      expect(prepared.fileName, 'valid-id.jpg');
    });

    test('bytes that are not an image are refused', () {
      expect(prepareIdPhoto(Uint8List.fromList([1, 2, 3, 4])), isNull);
    });
  });

  group('after Create Account', () {
    test('signed in with the ID sent: waiting for verification', () {
      final message = RegistrationSuccessScreen.messageFor(signedIn: true, idSent: true);
      expect(message, contains('waiting for verification'));
      expect(message, contains('notified'));
    });

    test('otherwise: sign in and upload under Profile, never saying why', () {
      for (final signedIn in [true, false]) {
        final message = RegistrationSuccessScreen.messageFor(signedIn: signedIn, idSent: false);
        expect(message, contains('Profile > Account verification'));
        expect(message.toLowerCase(), isNot(contains('already')));
        expect(message.toLowerCase(), isNot(contains('exist')));
      }
    });
  });
}
