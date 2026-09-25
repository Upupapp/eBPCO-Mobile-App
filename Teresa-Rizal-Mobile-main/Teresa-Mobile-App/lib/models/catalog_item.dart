import 'service_form_spec.dart';

/// A selectable document type (Dokyu) or assistance program (Tulong),
/// copied from the exact catalogs defined inline in the Web Admin's
/// `resources/views/citizen/document-requests.blade.php` and
/// `assistance-requests.blade.php` ($documentTypes / $assistanceTypes),
/// plus `config/teresa_rizal_municipal_documents.php` and
/// `config/teresa_rizal_barangay_documents.php`. Kept as static Dart data in
/// `MockCatalog` (see services/mock_catalog.dart) rather than re-typed
/// inline per screen.
class CatalogItem {
  final String key;
  final String name;
  final String office;
  final String fee;
  final String days;
  final List<String> requirements;
  final List<String> process;
  final String? amount; // Tulong only
  final String? icon; // lucide-style icon name, mapped to Material in UI

  /// Sourced, service-specific citizen-input fields — see
  /// docs/DOKYU_TULONG_FORM_AUDIT.md for where each one came from. Null
  /// means no reliable source was found for this item, so it keeps the
  /// generic Purpose + Attachments request flow instead of invented fields.
  final ServiceFormSpec? formSpec;

  /// Realistic, service-specific demo answers for [formSpec] fields that
  /// aren't already covered by the Resident Master Profile prefill (see
  /// ServiceRequestWizardScreen's own prefill block) — e.g. a select's
  /// option value, a checkbox's bool, free text. Applied only when the
  /// signed-in resident is the primary demo resident (Perlita Quiambao),
  /// so a live client demo opens every form already realistically filled
  /// in rather than blank (see the Mobile <-> Web Admin final alignment
  /// pass). Keyed by [ServiceFormField.key], same as [formSpec] itself.
  /// Empty for a service with no formSpec, or one already fully covered by
  /// Master Profile fields. Still a plain starting value in an editable
  /// field — never locked, and editing it only affects that one
  /// application, exactly like every other prefilled field in this wizard.
  final Map<String, dynamic> demoDefaults;

  /// A realistic default for the Requirements step's own free-text Purpose
  /// / Additional Notes field (see ServiceRequestWizardScreen/
  /// NewRequestScreen), applied under the same "Perlita only" condition as
  /// [demoDefaults]. Null leaves that field blank, as before.
  final String? demoPurpose;

  /// A service-specific, realistic rejection reason used by
  /// RequestDetailScreen's "Reject (Demo)" simulation control instead of
  /// that screen's generic ID-mismatch fallback — e.g. a missing/expired
  /// requirement document, an eligibility mismatch, or an incomplete form
  /// detail plausible for this exact service. Null keeps the existing
  /// generic reason (still realistic, just not service-specific).
  final String? demoRejectionReason;

  const CatalogItem({
    required this.key,
    required this.name,
    required this.office,
    required this.fee,
    required this.days,
    required this.requirements,
    required this.process,
    this.amount,
    this.icon,
    this.formSpec,
    this.demoDefaults = const {},
    this.demoPurpose,
    this.demoRejectionReason,
  });
}
