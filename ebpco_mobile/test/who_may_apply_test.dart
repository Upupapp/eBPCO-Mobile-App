import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/domain/applying_as.dart';
import 'package:ebpco_mobile/domain/permit_catalog.dart';
import 'package:ebpco_mobile/domain/who_may_apply.dart';

/// Who may apply for each permit type (ebpco-api 068): open to both by
/// default, the Municipality may restrict one. Same words as the portal.
void main() {
  group('reading GET /permit-types', () {
    test('who may apply, by permit type', () {
      final byType = applicantKindsByType({
        'items': [
          {'permitType': 'Building Permit', 'applicantKinds': ['residential', 'business']},
          {'permitType': 'Sign Permit', 'applicantKinds': ['business']},
          {'permitType': 'Fencing Permit', 'applicantKinds': ['residential']},
        ],
      });
      expect(applicantKindsFor(byType, 'Building Permit'), bothApplicantKinds);
      expect(applicantKindsFor(byType, 'Sign Permit'), [applyingAsBusiness]);
      expect(applicantKindsFor(byType, 'Fencing Permit'), [applyingAsResidential]);
    });

    test('kinds come back in the usual order, without unknown or repeated ones', () {
      expect(parseApplicantKinds(['business', 'residential', 'business']), bothApplicantKinds);
      expect(parseApplicantKinds(['business', 'corporation']), [applyingAsBusiness]);
    });

    test('an older server hides nothing: missing, empty or garbled reads as both', () {
      expect(parseApplicantKinds(null), bothApplicantKinds);
      expect(parseApplicantKinds(const []), bothApplicantKinds);
      expect(parseApplicantKinds('business'), bothApplicantKinds);
      expect(parseApplicantKinds(['corporation']), bothApplicantKinds);
      final byType = applicantKindsByType({
        'items': [
          {'permitType': 'Sign Permit'},
          {'applicantKinds': ['business']},
          'Fencing Permit',
        ],
      });
      expect(applicantKindsFor(byType, 'Sign Permit'), bothApplicantKinds);
      expect(applicantKindsFor(byType, 'Fencing Permit'), bothApplicantKinds);
      expect(applicantKindsByType(null), isEmpty);
      expect(applicantKindsByType({'data': []}), isEmpty);
    });

    test('a type the server did not list is open to both', () {
      expect(applicantKindsFor(const {}, 'Excavation Permit'), bothApplicantKinds);
    });

    test('when the call fails, every type in the catalog is open to both', () {
      final fallback = everyPermitTypeOpenToBoth;
      expect(fallback.length, offeredPermitTypeCount);
      for (final group in permitTypeGroups) {
        for (final type in group.types) {
          expect(fallback[type], bothApplicantKinds);
        }
      }
    });
  });

  test('the chip on each permit type', () {
    expect(applicantKindsChip(bothApplicantKinds), 'Homes & businesses');
    expect(applicantKindsChip([applyingAsBusiness]), 'Business only');
    expect(applicantKindsChip([applyingAsResidential]), 'Private individuals only');
  });

  test('who usually applies, only for the four types where it helps', () {
    expect(usualUseNote('Sign Permit'), 'Usually a business sign; a home-based practice can apply as a private individual.');
    expect(usualUseNote('Fencing Permit'), 'Usually for homes.');
    expect(usualUseNote('Interior Design Permit'), 'Usually shop and office fit-outs.');
    expect(usualUseNote('Certificate of Occupancy'), 'After the building work is done, before the building is used.');
    expect(usualUseNote('Building Permit'), isNull);
    expect(usualUseNote('Excavation Permit'), isNull);
  });

  group('the wizard', () {
    test('a kind not open says why', () {
      expect(
        applicantKindClosedMessage(permitType: 'Sign Permit', kind: applyingAsResidential, kinds: [applyingAsBusiness]),
        'Not open for a Sign Permit: the Municipality accepts it only for businesses.',
      );
      expect(
        applicantKindClosedMessage(permitType: 'Fencing Permit', kind: applyingAsBusiness, kinds: [applyingAsResidential]),
        'Not open for a Fencing Permit: the Municipality accepts it only from private individuals.',
      );
      expect(
        applicantKindClosedMessage(permitType: 'Interior Design Permit', kind: applyingAsResidential, kinds: [applyingAsBusiness]),
        startsWith('Not open for an Interior Design Permit:'),
      );
    });

    test('an open kind has nothing to say', () {
      expect(applicantKindClosedMessage(permitType: 'Sign Permit', kind: applyingAsBusiness, kinds: [applyingAsBusiness]), isNull);
      expect(applicantKindClosedMessage(permitType: 'Sign Permit', kind: applyingAsResidential, kinds: bothApplicantKinds), isNull);
    });

    test('a type open to one kind preselects it; both preselects nothing', () {
      expect(onlyApplicantKind([applyingAsBusiness]), applyingAsBusiness);
      expect(onlyApplicantKind([applyingAsResidential]), applyingAsResidential);
      expect(onlyApplicantKind(bothApplicantKinds), isNull);
    });
  });

  test('the usual-use note gives way when a type is restricted to one kind', () {
    expect(usualUseNote('Sign Permit', [applyingAsBusiness]), isNull);
    expect(usualUseNote('Fencing Permit', [applyingAsResidential]), isNull);
    expect(usualUseNote('Sign Permit', bothApplicantKinds), contains('business sign'));
    expect(usualUseNote('Sign Permit'), contains('business sign'));
  });
}
