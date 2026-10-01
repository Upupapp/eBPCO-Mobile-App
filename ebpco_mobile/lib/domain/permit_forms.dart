/// The blank forms a citizen is asked to upload filled in, keyed by the
/// requirement that asks for them.
///
/// Only the Building Permit asks for one (2026-10-01, the server's own
/// requirement lists): the Unified Building Permit Form, which the applicant,
/// the lot owner and the engineer or architect sign and a notary notarises,
/// and the ancillary permit forms, signed and sealed by licensed professionals.
/// Neither can be signed online, so the citizen needs the blank one to print.
/// Every other permit is filed entirely online, so it gets no form: the link
/// sits on the document card that asks for the form, and nowhere else.
///
/// The files are byte for byte the admin portal's `public/assets/permits/`,
/// first brought over from eBPCOMobile. [PermitForm.isOfficialCastillaForm]
/// is false for the Architectural form: Castilla has not published its own,
/// and the file is another city's (Puerto Princesa's), so it stands in as a
/// reference template and is labelled as one. Every other form's printed
/// heading names the Municipality of Castilla.
library;

/// One bundled blank form.
class PermitForm {
  /// Asset path, resolvable through `rootBundle`.
  final String assetPath;

  /// The form's own heading and NBC form number, as printed on it (read off
  /// each PDF's first page, 2026-10-01): what an applicant looks for at a
  /// counter.
  final String title;

  /// The name it is saved and shared under: the form's, not the bundle's
  /// ("New-Construction.pdf" said nothing about what it was).
  final String downloadName;

  /// Whether this is the genuine Castilla document. False: a generic
  /// reference template, shown as one.
  final bool isOfficialCastillaForm;

  const PermitForm({
    required this.assetPath,
    required this.title,
    required this.downloadName,
    required this.isOfficialCastillaForm,
  });

  /// The bundled file's name, for checks against the bundle.
  String get fileName => assetPath.split('/').last;
}

const String _dir = 'assets/permits';

/// The server's requirement codes (Building Permit, New) and the form each
/// one asks the citizen to fill in.
const Map<String, PermitForm> _formsByRequirement = {
  'bpnc-unified-form': PermitForm(
    assetPath: '$_dir/New-Construction.pdf',
    title: 'Unified Application Form for Building Permit',
    downloadName: 'Unified Application Form for Building Permit.pdf',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-electrical': PermitForm(
    assetPath: '$_dir/Electrical-Permit-Form.pdf',
    title: 'Electrical Permit Form (NBC Form No. A-03)',
    downloadName: 'Electrical Permit Form (NBC A-03).pdf',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-fencing': PermitForm(
    assetPath: '$_dir/Fencing-Permit-Form.pdf',
    title: 'Fencing Permit Form (NBC Form No. B-03)',
    downloadName: 'Fencing Permit Form (NBC B-03).pdf',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-architectural': PermitForm(
    assetPath: '$_dir/Architectural-Permit.pdf',
    title: 'Architectural Permit Form (reference template)',
    downloadName: 'Architectural Permit Form (reference template).pdf',
    isOfficialCastillaForm: false,
  ),
  'bpnc-ancillary-sanitary-plumbing': PermitForm(
    assetPath: '$_dir/Sanitary-Plumbing-Permit.pdf',
    title: 'Sanitary Permit Form (NBC Form No. A-05)',
    downloadName: 'Sanitary Permit Form (NBC A-05).pdf',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-mechanical': PermitForm(
    assetPath: '$_dir/Mechanical-Permit.pdf',
    title: 'Mechanical Permit Form (NBC Form No. A-04)',
    downloadName: 'Mechanical Permit Form (NBC A-04).pdf',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-civil-structural': PermitForm(
    assetPath: '$_dir/Civil-Structural-Permit.pdf',
    title: 'Civil/Structural Permit Form (NBC Form No. A-02)',
    downloadName: 'Civil-Structural Permit Form (NBC A-02).pdf',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-excavation': PermitForm(
    assetPath: '$_dir/Excavation-Permit-Form.pdf',
    title: 'Excavation and Ground Preparation Permit Form (NBC Form No. B-02)',
    downloadName: 'Excavation and Ground Preparation Permit Form (NBC B-02).pdf',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-electronics': PermitForm(
    assetPath: '$_dir/Electronics-Permit.pdf',
    title: 'Electronics Permit Form (NBC Form No. A-07)',
    downloadName: 'Electronics Permit Form (NBC A-07).pdf',
    isOfficialCastillaForm: true,
  ),
};

/// Every form this app bundles.
Iterable<PermitForm> get allBlankForms => _formsByRequirement.values;

/// The blank form the requirement [code] asks the citizen to fill in and
/// upload, or null when it asks for no form (the usual answer).
PermitForm? blankFormFor(String code) => _formsByRequirement[code];
