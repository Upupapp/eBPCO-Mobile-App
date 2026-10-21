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
  test('starts on what the citizen chose at sign-up; Both or nothing asks', () {
    expect(defaultApplyingAs('residential'), applyingAsResidential);
    expect(defaultApplyingAs('business'), applyingAsBusiness);
    expect(defaultApplyingAs('both'), isNull);
    expect(defaultApplyingAs(null), isNull);
  });

  group('what an application is for', () {
    test('the server says so', () {
      final app = _app(applyingAs: 'residential');
      expect(app.isResidential, isTrue);
      expect(app.applicantLabel, 'Residential');
    });

    test('an older server: the form, else a business means Business', () {
      expect(_app(form: {'applyingAs': 'residential'}).isResidential, isTrue);
      final business = _app(businessId: 'b-1', businessName: 'Sari-Sari ni Aling Nena');
      expect(business.applyingAs, applyingAsBusiness);
      expect(business.applicantLabel, 'Sari-Sari ni Aling Nena');
      expect(_app().applyingAs, applyingAsResidential);
    });

    test('a residential application names the owner when the applicant is not the owner', () {
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

    test('the property owner comes back as saved', () {
      final owner = PropertyOwner.fromForm({
        'propertyOwner': {'isApplicant': false, 'name': 'Maria Santos', 'relationship': 'Mother'},
      })!;
      expect(owner.isApplicant, isFalse);
      expect(owner.name, 'Maria Santos');
      expect(owner.relationship, 'Mother');
      expect(PropertyOwner.fromForm({'propertyOwner': {'isApplicant': true}})!.isApplicant, isTrue);
      expect(PropertyOwner.fromForm(const {}), isNull);
    });
  });

  group('Continue on step 1', () {
    String? problem({String? applyingAs, String? businessId, bool? ownsProperty, String ownerName = ''}) =>
        applyingAsProblem(applyingAs: applyingAs, businessId: businessId, ownsProperty: ownsProperty, ownerName: ownerName);

    test('needs a choice', () {
      expect(problem(), contains('Residential / Private Individual'));
    });

    test('Business needs a business', () {
      expect(problem(applyingAs: 'business'), 'Please select a business.');
      expect(problem(applyingAs: 'business', businessId: 'b-1'), isNull);
    });

    test('Residential needs no business, only who owns the property', () {
      expect(problem(applyingAs: 'residential'), 'Please answer whether you own the property.');
      expect(problem(applyingAs: 'residential', ownsProperty: true), isNull);
      expect(problem(applyingAs: 'residential', ownsProperty: false), "Enter the property owner's full name.");
      expect(problem(applyingAs: 'residential', ownsProperty: false, ownerName: 'Maria Santos'), isNull);
    });
  });

  group('the form saved with the application', () {
    test('Residential carries the owner, with the details as before', () {
      final form = applicationForm(
        applyingAs: applyingAsResidential,
        propertyOwner: const PropertyOwner(isApplicant: false, name: ' Maria Santos ', relationship: ''),
        scopeOfWork: 'Two-storey house',
        professionalName: '',
        prcNumber: ' 0012345 ',
      );
      expect(form, {
        'applyingAs': 'residential',
        'propertyOwner': {'isApplicant': false, 'name': 'Maria Santos'},
        'scopeOfWork': 'Two-storey house',
        'professionalName': null,
        'prcNumber': '0012345',
      });
    });

    test('the applicant as owner is just that', () {
      final form = applicationForm(
        applyingAs: applyingAsResidential,
        propertyOwner: const PropertyOwner(isApplicant: true, name: 'ignored'),
        scopeOfWork: '',
        professionalName: '',
        prcNumber: '',
      );
      expect(form['propertyOwner'], {'isApplicant': true});
      expect(form['scopeOfWork'], isNull);
    });

    test('Business carries no owner, and keys this app does not edit are kept', () {
      final form = applicationForm(
        previous: {
          'lotArea': '120',
          'propertyOwner': {'isApplicant': true},
        },
        applyingAs: applyingAsBusiness,
        propertyOwner: const PropertyOwner(isApplicant: true),
        scopeOfWork: 'Store front',
        professionalName: 'Engr. Reyes',
        prcNumber: '',
      );
      expect(form['applyingAs'], 'business');
      expect(form['propertyOwner'], isNull);
      expect(form['lotArea'], '120');
      expect(form['professionalName'], 'Engr. Reyes');
    });
  });

  test('a residential Sign Permit gets a hint, never a rule', () {
    expect(applyingAsHint(permitType: 'Sign Permit', applyingAs: applyingAsResidential), contains('Choose Business'));
    expect(applyingAsHint(permitType: 'Sign Permit', applyingAs: applyingAsBusiness), isNull);
    expect(applyingAsHint(permitType: 'Building Permit', applyingAs: applyingAsResidential), isNull);
  });

  test('the review reads in plain words', () {
    expect(applyingAsLabel(applyingAsResidential), 'Residential / Private Individual');
    expect(applyingAsLabel(applyingAsBusiness), 'Business');
    expect(applyingAsLabel(null), 'Not chosen');
  });
}
