/// Data-driven description of a Dokyu/Tulong service's citizen-facing
/// fields, sourced from the real Teresa, Rizal forms audited in
/// docs/DOKYU_TULONG_FORM_AUDIT.md. A [CatalogItem] with a non-null
/// [ServiceFormSpec] is rendered through `ServiceRequestWizardScreen`
/// (Applicant Info -> each spec step -> Requirements & Attachments ->
/// Review & Submit) instead of the older single-step `NewRequestScreen`,
/// so the step count/names adapt per service rather than a fixed template.
/// A `null` formSpec means "no reliable citizen-fillable source was found
/// for this pre-existing item" — it keeps using the generic Purpose +
/// Attachments flow rather than inventing fields.
library;

enum ServiceFieldType {
  text,
  textarea,
  number,
  date,
  select,
  multiselect,
  checkbox,

  /// A read-only "N years old" display computed from another field's
  /// [ServiceFormField.derivedFromKey] (that field must be `date`-typed).
  /// If a source form asks for both Date of Birth and Age, the mobile
  /// field list should use a `date` field plus one of these instead of two
  /// independently-typed values — see docs/DOKYU_TULONG_FORM_AUDIT.md's
  /// global birthdate/age rule. Never independently required/editable.
  derivedAge,
}

class ServiceFormField {
  final String key;
  final String label;
  final ServiceFieldType type;
  final bool required;
  final String? hint;
  final List<String>? options; // select / multiselect

  /// For [ServiceFieldType.derivedAge] only — the key of the `date` field
  /// this age is computed from.
  final String? derivedFromKey;

  /// Optional conditional-visibility gate — when set, this field is only
  /// shown (and only enforced if [required]) while the field keyed
  /// [visibleWhenKey] currently holds one of [visibleWhenValueIn]. Null
  /// (the default, and every pre-existing field's behavior) means always
  /// visible. Kept deliberately minimal — a single-field value-in-list
  /// check, not a general expression engine — since that's the only shape
  /// any sourced form has actually needed so far (e.g. a "specify if
  /// multiple delivery" field that only applies when Type of Delivery
  /// isn't Single).
  final String? visibleWhenKey;
  final List<String>? visibleWhenValueIn;

  const ServiceFormField({
    required this.key,
    required this.label,
    required this.type,
    this.required = true,
    this.hint,
    this.options,
    this.derivedFromKey,
    this.visibleWhenKey,
    this.visibleWhenValueIn,
  });
}

class ServiceFormStep {
  final String label;
  final String? description;
  final List<ServiceFormField> fields;

  const ServiceFormStep({required this.label, this.description, required this.fields});
}

class ServiceFormSpec {
  final List<ServiceFormStep> steps;
  const ServiceFormSpec({required this.steps});
}
