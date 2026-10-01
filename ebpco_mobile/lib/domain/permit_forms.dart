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
/// so a generic reference template stands in and is labelled as one.
library;

/// One bundled blank form.
class PermitForm {
  /// Asset path, resolvable through `rootBundle`.
  final String assetPath;

  /// The document's own title, which is what an applicant looks for at a
  /// counter.
  final String title;

  /// Whether this is the genuine Castilla document. False: a generic
  /// reference template, shown as one.
  final bool isOfficialCastillaForm;

  const PermitForm({required this.assetPath, required this.title, required this.isOfficialCastillaForm});

  /// A file name for saving or sharing: the asset's own.
  String get fileName => assetPath.split('/').last;
}

const String _dir = 'assets/permits';

/// The server's requirement codes (Building Permit, New) and the form each
/// one asks the citizen to fill in.
const Map<String, PermitForm> _formsByRequirement = {
  'bpnc-unified-form': PermitForm(
    assetPath: '$_dir/New-Construction.pdf',
    title: 'Unified Application Form for Building Permit',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-electrical': PermitForm(
    assetPath: '$_dir/Electrical-Permit-Form.pdf',
    title: 'Electrical Permit Application',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-fencing': PermitForm(
    assetPath: '$_dir/Fencing-Permit-Form.pdf',
    title: 'Fencing Permit Application',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-architectural': PermitForm(
    assetPath: '$_dir/Architectural-Permit.pdf',
    title: 'Architectural Permit Application',
    isOfficialCastillaForm: false,
  ),
  'bpnc-ancillary-sanitary-plumbing': PermitForm(
    assetPath: '$_dir/Sanitary-Plumbing-Permit.pdf',
    title: 'Sanitary Permit',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-mechanical': PermitForm(
    assetPath: '$_dir/Mechanical-Permit.pdf',
    title: 'Mechanical Permit Application',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-civil-structural': PermitForm(
    assetPath: '$_dir/Civil-Structural-Permit.pdf',
    title: 'Civil / Structural Permit Application',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-excavation': PermitForm(
    assetPath: '$_dir/Excavation-Permit-Form.pdf',
    title: 'Excavation and Ground Preparation Permit',
    isOfficialCastillaForm: true,
  ),
  'bpnc-ancillary-electronics': PermitForm(
    assetPath: '$_dir/Electronics-Permit.pdf',
    title: 'Electronics Permit Application',
    isOfficialCastillaForm: true,
  ),
};

/// Every form this app bundles.
Iterable<PermitForm> get allBlankForms => _formsByRequirement.values;

/// The blank form the requirement [code] asks the citizen to fill in and
/// upload, or null when it asks for no form (the usual answer).
PermitForm? blankFormFor(String code) => _formsByRequirement[code];
