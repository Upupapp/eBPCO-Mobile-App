/// Who an application is for (ebpco-api migration 067, owner request
/// 2026-10-21): a business is not needed to apply. Each application asks
/// again, whatever the citizen chose at sign-up, so one account files both:
///
///   - 'residential': a private individual, for their own home or other
///     private property (or a family member's). No business; the form says
///     whether the applicant owns the property or names the owner.
///   - 'business': for a registered business or commercial establishment.
///
/// Kept in the application's `form` (`form.applyingAs`, `form.propertyOwner`),
/// the same keys the citizen portal writes.
library;

const applyingAsResidential = 'residential';
const applyingAsBusiness = 'business';

/// What the wizard's "Applying as" starts on, from what the citizen chose at
/// sign-up. Both, or nothing chosen, starts on neither: the citizen picks.
String? defaultApplyingAs(String? registeredAs) => switch (registeredAs) {
      'residential' => applyingAsResidential,
      'business' => applyingAsBusiness,
      _ => null,
    };

/// The server's reading (`applyingAsOf`): what the form says, else a business
/// on the application means 'business'. An application filed before this
/// existed always named a business.
String applyingAsOf(Map<String, dynamic> form, String? businessId) {
  final value = form['applyingAs'];
  if (value == applyingAsResidential || value == applyingAsBusiness) return value as String;
  return businessId == null ? applyingAsResidential : applyingAsBusiness;
}

/// What a draft said when it was saved, for the wizard to reopen on: the
/// form's own answer, else a business already chosen means 'business'. A
/// draft that says neither asks again.
String? savedApplyingAs(Map<String, dynamic> form, String? businessId) {
  final value = form['applyingAs'];
  if (value == applyingAsResidential || value == applyingAsBusiness) return value as String;
  return businessId == null ? null : applyingAsBusiness;
}

/// Who owns the property on a residential application.
class PropertyOwner {
  /// True when the applicant owns it; otherwise [name] is the owner.
  final bool isApplicant;
  final String? name;
  final String? relationship;

  const PropertyOwner({required this.isApplicant, this.name, this.relationship});

  /// `{isApplicant: true}`, or `{isApplicant: false, name, relationship?}`.
  Map<String, dynamic> toJson() {
    if (isApplicant) return const {'isApplicant': true};
    final owner = name?.trim() ?? '';
    final relation = relationship?.trim() ?? '';
    return {
      'isApplicant': false,
      'name': owner,
      if (relation.isNotEmpty) 'relationship': relation,
    };
  }

  /// The owner a saved form names, or null when it says nothing yet.
  static PropertyOwner? fromForm(Map<String, dynamic> form) {
    final raw = form['propertyOwner'];
    if (raw is! Map) return null;
    final isApplicant = raw['isApplicant'];
    if (isApplicant == true) return const PropertyOwner(isApplicant: true);
    if (isApplicant != false) return null;
    return PropertyOwner(
      isApplicant: false,
      name: raw['name'] is String ? raw['name'] as String : null,
      relationship: raw['relationship'] is String ? raw['relationship'] as String : null,
    );
  }
}

/// The owner a residential application names when the applicant is not the
/// owner; null otherwise.
String? propertyOwnerNameOf(Map<String, dynamic> form) {
  final owner = PropertyOwner.fromForm(form);
  if (owner == null || owner.isApplicant) return null;
  final name = owner.name?.trim() ?? '';
  return name.isEmpty ? null : name;
}

/// What is still unanswered in "Applying as", worded for the citizen, or null.
/// [ownsProperty] is null until the citizen answers "Do you own the property?".
String? applyingAsProblem({
  required String? applyingAs,
  required String? businessId,
  required bool? ownsProperty,
  required String ownerName,
}) {
  if (applyingAs == null) {
    return 'Choose whether you are applying as Residential / Private Individual or as a Business.';
  }
  if (applyingAs == applyingAsBusiness) {
    return businessId == null ? 'Please select a business.' : null;
  }
  if (ownsProperty == null) return 'Please answer whether you own the property.';
  if (!ownsProperty && ownerName.trim().isEmpty) return "Enter the property owner's full name.";
  return null;
}

/// The whole `form` to save: PATCH replaces it, so every key goes every time.
/// [previous] is the form as last loaded, so keys this app does not edit
/// (the portal may write more) are kept. Empty text is saved as null, as before.
Map<String, dynamic> applicationForm({
  Map<String, dynamic> previous = const {},
  required String? applyingAs,
  PropertyOwner? propertyOwner,
  required String scopeOfWork,
  required String professionalName,
  required String prcNumber,
}) {
  String? text(String value) => value.trim().isEmpty ? null : value.trim();
  return {
    ...previous,
    'applyingAs': applyingAs,
    'propertyOwner': applyingAs == applyingAsResidential ? propertyOwner?.toJson() : null,
    'scopeOfWork': text(scopeOfWork),
    'professionalName': text(professionalName),
    'prcNumber': text(prcNumber),
  };
}

/// What "Applying as" reads on a review or summary.
String applyingAsLabel(String? applyingAs) => switch (applyingAs) {
      applyingAsResidential => 'Residential / Private Individual',
      applyingAsBusiness => 'Business',
      _ => 'Not chosen',
    };
