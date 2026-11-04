/// Who may apply for each permit type (ebpco-api migration 068). By law every
/// type is open to both a private individual and a business (PD 1096 Sec. 301:
/// "any person, firm or corporation"), so both is the default; the
/// Municipality may restrict a type where its own ordinance does, and the
/// server refuses the other kind at filing. Same words as the citizen portal.
library;

import 'applying_as.dart';
import 'permit_catalog.dart';

/// Every kind: the default for a permit type, and the reading whenever the
/// server says nothing usable (an older server, or no connection).
const List<String> bothApplicantKinds = [applyingAsResidential, applyingAsBusiness];

/// An `applicantKinds` value as the server sent it: only the two known kinds,
/// in their usual order. Missing, empty or garbled reads as both, so an older
/// server hides nothing.
List<String> parseApplicantKinds(Object? raw) {
  if (raw is! List) return bothApplicantKinds;
  final kinds = [
    for (final kind in bothApplicantKinds)
      if (raw.contains(kind)) kind,
  ];
  return kinds.isEmpty ? bothApplicantKinds : kinds;
}

/// `GET /permit-types`'s body (`{items: [{permitType, applicantKinds}]}`) as
/// permit type -> who may apply. Rows it cannot read are skipped, and
/// [applicantKindsFor] reads a type that is not here as both.
Map<String, List<String>> applicantKindsByType(Object? body) {
  final items = body is Map ? body['items'] : null;
  if (items is! List) return const {};
  return {
    for (final item in items)
      if (item is Map && item['permitType'] is String)
        item['permitType'] as String: parseApplicantKinds(item['applicantKinds']),
  };
}

/// What the app uses when `GET /permit-types` fails: every type open to both.
Map<String, List<String>> get everyPermitTypeOpenToBoth => {
      for (final group in permitTypeGroups)
        for (final type in group.types) type: bothApplicantKinds,
    };

/// Who may apply for [permitType]; both when the server did not say.
List<String> applicantKindsFor(Map<String, List<String>> byType, String permitType) =>
    byType[permitType] ?? bothApplicantKinds;

/// The chip on each permit type in the catalog.
String applicantKindsChip(List<String> kinds) {
  final residential = kinds.contains(applyingAsResidential);
  final business = kinds.contains(applyingAsBusiness);
  if (business && !residential) return 'Business only';
  // One name for the applicant kind (design review I6): who applies, not what the building is for.
  if (residential && !business) return 'Private individuals only';
  return 'Homes & businesses';
}

/// The chip on a catalog card: only on a type the Municipality opened to homes
/// OR businesses, not both ("Homes & businesses" on every card said nothing;
/// the portal's `restricted`). Null for a type open to both.
String? restrictedKindsChip(List<String> kinds) =>
    kinds.contains(applyingAsResidential) && kinds.contains(applyingAsBusiness) ? null : applicantKindsChip(kinds);

/// Who usually applies, for the few types where that is worth saying. Never
/// a rule: a doctor's home clinic sign is filed by the doctor.
/// A type restricted to one kind ([kinds]) gets none: its chip says who may
/// apply, and a note about who USUALLY applies would only contradict it.
String? usualUseNote(String permitType, [List<String>? kinds]) => kinds != null && kinds.length < 2
    ? null
    : switch (permitType) {
        'Sign Permit' => 'Usually a business sign; a home-based practice can apply as a private individual.',
        'Fencing Permit' => 'Usually for homes.',
        'Interior Design Permit' => 'Usually shop and office fit-outs.',
        'Certificate of Occupancy' => 'After the building work is done, before the building is used.',
        _ => null,
      };

/// Why "Applying as" [kind] is not open for [permitType], or null when it is.
String? applicantKindClosedMessage({
  required String permitType,
  required String kind,
  required List<String> kinds,
}) {
  if (kinds.contains(kind)) return null;
  final article = RegExp(r'^[AEIOU]').hasMatch(permitType) ? 'an' : 'a';
  return kinds.contains(applyingAsBusiness)
      ? 'Not open for $article $permitType: the Municipality accepts it only for businesses.'
      : 'Not open for $article $permitType: the Municipality accepts it only from private individuals.';
}

/// The one kind open for a type that takes only one, for the wizard to
/// preselect; null when both are open.
String? onlyApplicantKind(List<String> kinds) => kinds.length == 1 ? kinds.single : null;
