/// The blank official application forms, per permit type.
///
/// Merged from eBPCOMobile's `core/contract/permit_forms.dart` (2026-10-01),
/// keyed here by this app's own permit-type names (`permit_catalog.dart`). The
/// files under `assets/permits/` are byte for byte the admin portal's
/// `public/assets/permits/`, so the counter and the app hand an applicant the
/// same paper.
///
/// [PermitForm.isOfficialCastillaForm] carries what the admin's template file
/// only says in a comment: five of the forms are generic reference templates
/// standing in for a form Castilla has not published (Architectural, Interior
/// Design, Sign, Demolition, Certificate of Occupancy). Such a form still shows
/// an applicant what will be asked, but the screen must never present it as
/// the LGU's own.
///
/// The BFP's FSEC and FSIC forms are not bundled: the Bureau of Fire
/// Protection issues both through BFP-FSIS ([retiredPermitTypes]).
library;

/// Which office hands out, and takes back, the blank form.
enum FormIssuingOffice {
  /// Office of the Building Official, which in Castilla sits with the
  /// Office of the Municipal Engineer.
  obo('Office of the Building Official'),

  /// Municipal Planning and Development Office (Zoning).
  mpdo('Municipal Planning and Development Office');

  const FormIssuingOffice(this.label);
  final String label;
}

/// One bundled blank form.
class PermitForm {
  /// Asset path, resolvable through `rootBundle`.
  final String assetPath;

  /// The document's own title, which is what an applicant looks for at a
  /// counter; it differs from the permit type's name for some forms.
  final String title;

  final FormIssuingOffice office;

  /// Whether this is the genuine Castilla document. False: a generic
  /// reference template, shown as one.
  final bool isOfficialCastillaForm;

  const PermitForm({
    required this.assetPath,
    required this.title,
    required this.office,
    required this.isOfficialCastillaForm,
  });

  /// A file name for saving or sharing: the asset's own.
  String get fileName => assetPath.split('/').last;
}

const String _dir = 'assets/permits';

/// Castilla's Unified Application Form for Building Permit. Its own Scope of
/// Work checkboxes cover new construction, renovation and addition.
const PermitForm _unifiedBuildingForm = PermitForm(
  assetPath: '$_dir/New-Construction.pdf',
  title: 'Unified Application Form for Building Permit',
  office: FormIssuingOffice.obo,
  isOfficialCastillaForm: true,
);

const Map<String, PermitForm> _forms = {
  'Building Permit': _unifiedBuildingForm,
  'Zoning / Locational Clearance': PermitForm(
    assetPath: '$_dir/Zoning-Locational-Clearance-Form.pdf',
    title: 'Application for Locational Clearance / Zoning Compliance',
    office: FormIssuingOffice.mpdo,
    isOfficialCastillaForm: true,
  ),
  'Civil / Structural Permit': PermitForm(
    assetPath: '$_dir/Civil-Structural-Permit.pdf',
    title: 'Civil / Structural Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  'Electrical Permit': PermitForm(
    assetPath: '$_dir/Electrical-Permit-Form.pdf',
    title: 'Electrical Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  'Electronics Permit': PermitForm(
    assetPath: '$_dir/Electronics-Permit.pdf',
    title: 'Electronics Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  'Mechanical Permit': PermitForm(
    assetPath: '$_dir/Mechanical-Permit.pdf',
    title: 'Mechanical Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  'Plumbing Permit': PermitForm(
    assetPath: '$_dir/Plumbing-Permit.pdf',
    title: 'Plumbing Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  'Sanitary Permit': PermitForm(
    assetPath: '$_dir/Sanitary-Plumbing-Permit.pdf',
    title: 'Sanitary Permit',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  'Fencing Permit': PermitForm(
    assetPath: '$_dir/Fencing-Permit-Form.pdf',
    title: 'Fencing Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  'Excavation Permit': PermitForm(
    assetPath: '$_dir/Excavation-Permit-Form.pdf',
    title: 'Excavation and Ground Preparation Permit',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: true,
  ),
  // Reference templates: Castilla has not published its own form for these.
  'Architectural Permit': PermitForm(
    assetPath: '$_dir/Architectural-Permit.pdf',
    title: 'Architectural Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: false,
  ),
  'Interior Design Permit': PermitForm(
    assetPath: '$_dir/Interior-Design-Permit.pdf',
    title: 'Interior Design Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: false,
  ),
  'Sign Permit': PermitForm(
    assetPath: '$_dir/Sign-Permit-Form.pdf',
    title: 'Sign Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: false,
  ),
  'Demolition Permit': PermitForm(
    assetPath: '$_dir/Demolition-Permit.pdf',
    title: 'Demolition Permit Application',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: false,
  ),
  'Certificate of Occupancy': PermitForm(
    assetPath: '$_dir/Application-for-Certificate-of-Occupancy.pdf',
    title: 'Application for Certificate of Occupancy',
    office: FormIssuingOffice.obo,
    isOfficialCastillaForm: false,
  ),
};

/// The Office of the Municipal Engineer's own documentary-requirements
/// checklist, covering the Building Permit and the Certificate of Occupancy.
/// Supplementary to each type's blank form, not a replacement for it.
const PermitForm oboChecklist = PermitForm(
  assetPath: '$_dir/Building-Permit-and-Occupancy-Checklist.pdf',
  title: 'Building Permit and Occupancy — Documentary Requirements Checklist',
  office: FormIssuingOffice.obo,
  isOfficialCastillaForm: true,
);

const Set<String> _checklistTypes = {'Building Permit', 'Certificate of Occupancy'};

/// The blank application form for [permitType], or null where none is bundled
/// (a retired BFP type, or a name this app does not know). Callers render
/// null as no entry point, never one that opens nothing.
PermitForm? permitFormFor(String permitType) => _forms[permitType];

/// Every document worth handing an applicant for [permitType]: its form,
/// then the OBO checklist where it applies.
List<PermitForm> permitDocumentsFor(String permitType) => [
      ?_forms[permitType],
      if (_checklistTypes.contains(permitType)) oboChecklist,
    ];
