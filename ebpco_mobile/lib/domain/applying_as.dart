/// Who an application is for (ebpco-api migration 067, owner request
/// 2026-10-21): a business is not needed to apply. Each application asks
/// again, whatever the citizen chose at sign-up, so one account files both:
///
///   - 'residential': a private individual, for their own home or private
///     property. No business. Owner ruling 2026-10-28: a citizen applies only
///     for themselves, so nothing is asked about the property's owner; the
///     server refuses an application for someone else's property.
///   - 'business': for a registered business or commercial establishment.
///
/// Kept in the application's `form` (`form.applyingAs`), the same key the
/// citizen portal writes. `form.propertyOwner` survives only on applications
/// filed before the ruling, and is only ever read back for display.
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

/// The owner a residential application filed before the 2026-10-28 ruling
/// named, when the applicant was not the owner; null otherwise. History only:
/// the application detail shows it, nothing asks for it any more.
String? propertyOwnerNameOf(Map<String, dynamic> form) {
  final raw = form['propertyOwner'];
  if (raw is! Map || raw['isApplicant'] != false) return null;
  final name = raw['name'] is String ? (raw['name'] as String).trim() : '';
  return name.isEmpty ? null : name;
}

/// What is still unanswered in "Applying as", worded for the citizen, or null.
/// Residential needs nothing more: the citizen applies for their own property.
String? applyingAsProblem({required String? applyingAs, required String? businessId}) {
  if (applyingAs == null) {
    return 'Choose whether you are applying as Residential / Private Individual or as a Business.';
  }
  if (applyingAs == applyingAsBusiness) {
    return businessId == null ? 'Please select a business.' : null;
  }
  return null;
}

/// The whole `form` to save: PATCH replaces it, so every key goes every time.
/// [previous] is the form as last loaded, so keys this app does not edit
/// (the portal may write more) are kept. Empty text is saved as null, as before.
/// Never `propertyOwner`: a draft saved before the 2026-10-28 ruling may still
/// carry one, and the server refuses a filing for someone else's property.
Map<String, dynamic> applicationForm({
  Map<String, dynamic> previous = const {},
  required String? applyingAs,
  required String scopeOfWork,
  required String professionalName,
  required String prcNumber,
}) {
  String? text(String value) => value.trim().isEmpty ? null : value.trim();
  return {
    for (final MapEntry(:key, :value) in previous.entries)
      if (key != 'propertyOwner') key: value,
    'applyingAs': applyingAs,
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
