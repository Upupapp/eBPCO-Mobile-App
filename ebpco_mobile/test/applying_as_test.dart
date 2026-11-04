import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/applying_as.dart';
import 'package:ebpco_mobile/domain/models.dart';

/// "Applying as" on every application (ebpco-api 067): a business is not
/// needed to apply. Same keys and rules as the server and the portal.
ApplicationSummary _app({String? businessId, String? businessName, Object? applyingAs, Map<String, dynamic>? form}) =>
    ApplicationSummary.fromJson({
      'id': 'a-1',
      'referenceNumber': 'E-BPCO-2026-000001',
      'permitType': 'Building Permit',
      'applicationAction': 'New',
      'businessId': businessId,
      'businessName': businessName,
      'lifecycleStatus': 'Submitted',
      'applicantStatus': 'Submitted',
      'applyingAs': ?applyingAs,
      'form': ?form,
    });

void main() {
  test('starts on Residential for a citizen with no active business; with businesses, or no list, it asks', () {
    expect(startingApplyingAs(listLoaded: true, activeBusinesses: 0), applyingAsResidential);
    expect(startingApplyingAs(listLoaded: true, activeBusinesses: 2), isNull);
    expect(startingApplyingAs(listLoaded: false, activeBusinesses: 0), isNull);
  });

  group('what an application is for', () {
    test('the server says so', () {
      final app = _app(applyingAs: 'residential');
      expect(app.isResidential, isTrue);
      expect(app.applicantLabel, 'Private individual');
      expect(app.businessNameOnDocument, isNull);
    });

    test('an older server: the form, else a business means Business', () {
      expect(_app(form: {'applyingAs': 'residential'}).isResidential, isTrue);
      final business = _app(businessId: 'b-1', businessName: 'Sari-Sari ni Aling Nena');
      expect(business.applyingAs, applyingAsBusiness);
      expect(business.applicantLabel, 'Sari-Sari ni Aling Nena');
      expect(_app().applyingAs, applyingAsResidential);
    });

    test('an older residential application still shows the owner it named', () {
      // Filed before the 2026-10-28 ruling, when the app still asked "Do you own the property?".
      final forOwner = _app(applyingAs: 'residential', form: {
        'applyingAs': 'residential',
        'propertyOwner': {'isApplicant': false, 'name': ' Maria Santos ', 'relationship': 'Mother'},
      });
      expect(forOwner.propertyOwnerName, 'Maria Santos');
      final own = _app(applyingAs: 'residential', form: {
        'applyingAs': 'residential',
        'propertyOwner': {'isApplicant': true},
      });
      expect(own.propertyOwnerName, isNull);
      expect(_app(applyingAs: 'residential', form: {'applyingAs': 'residential'}).propertyOwnerName, isNull);
      expect(propertyOwnerNameOf({'propertyOwner': {'isApplicant': false, 'name': '  '}}), isNull);
    });
  });

  group('a draft reopens on what it said', () {
    test('its own answer', () {
      expect(savedApplyingAs({'applyingAs': 'residential'}, null), applyingAsResidential);
      expect(savedApplyingAs({'applyingAs': 'business'}, null), applyingAsBusiness);
    });

    test('a business already chosen on a draft from before means Business', () {
      expect(savedApplyingAs(const {}, 'b-1'), applyingAsBusiness);
    });

    test('neither asks again', () {
      expect(savedApplyingAs(const {}, null), isNull);
    });
  });

  group('Continue on step 1', () {
    String? problem({String? applyingAs, String? businessId}) =>
        applyingAsProblem(applyingAs: applyingAs, businessId: businessId);

    test('needs a choice', () {
      expect(problem(), 'Please choose whether you are applying as a private individual or as a business.');
    });

    test('Business needs a business', () {
      expect(problem(applyingAs: 'business'), 'Please select a business.');
      expect(problem(applyingAs: 'business', businessId: 'b-1'), isNull);
    });

    test('Residential needs nothing more: the citizen applies for their own property', () {
      expect(problem(applyingAs: 'residential'), isNull);
    });
  });

  group('the form saved with the application', () {
    test('Residential carries the details as before, and no property owner', () {
      final form = applicationForm(
        applyingAs: applyingAsResidential,
        scopeOfWork: 'Two-storey house',
        professionalName: '',
        prcNumber: ' 0012345 ',
      );
      expect(form, {
        'applyingAs': 'residential',
        'scopeOfWork': 'Two-storey house',
        'professionalName': null,
        'prcNumber': '0012345',
      });
    });

    test('an older draft that named another owner is saved without it, and other keys are kept', () {
      // The server now refuses a residential filing for someone else's property.
      final form = applicationForm(
        previous: {
          'lotArea': '120',
          'propertyOwner': {'isApplicant': false, 'name': 'Maria Santos', 'relationship': 'Mother'},
        },
        applyingAs: applyingAsResidential,
        scopeOfWork: '',
        professionalName: '',
        prcNumber: '',
      );
      expect(form.containsKey('propertyOwner'), isFalse);
      expect(form['lotArea'], '120');
      expect(form['scopeOfWork'], isNull);
    });

    test('Business carries no owner, and keys this app does not edit are kept', () {
      final form = applicationForm(
        previous: {
          'lotArea': '120',
          'propertyOwner': {'isApplicant': true},
        },
        applyingAs: applyingAsBusiness,
        scopeOfWork: 'Store front',
        professionalName: 'Engr. Reyes',
        prcNumber: '',
      );
      expect(form['applyingAs'], 'business');
      expect(form.containsKey('propertyOwner'), isFalse);
      expect(form['lotArea'], '120');
      expect(form['professionalName'], 'Engr. Reyes');
    });
  });

  test('the review reads in plain words', () {
    expect(applyingAsLabel(applyingAsResidential), 'Private individual');
    expect(applyingAsLabel(applyingAsBusiness), 'Business');
    expect(applyingAsLabel(null), 'Not chosen');
  });
}
