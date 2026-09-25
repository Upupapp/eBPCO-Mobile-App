/// The 17 real permit types, grouped for the catalog screen — ported
/// verbatim from `ebpco-user-portal/src/app/core/domain/permit.model.ts`'s
/// `PERMIT_TYPE_GROUPS`, whose own comment says this grouping "mirrors
/// ebpco-mobile's applications_screen.dart grouping" — this app is that
/// mirror, kept identical rather than re-invented.
class PermitTypeGroup {
  final String label;
  final List<String> types;
  const PermitTypeGroup(this.label, this.types);
}

const List<PermitTypeGroup> permitTypeGroups = [
  PermitTypeGroup('Building Permit', ['Building Permit', 'Demolition Permit', 'Zoning / Locational Clearance']),
  PermitTypeGroup('Ancillary Permits', [
    'Architectural Permit',
    'Civil / Structural Permit',
    'Electrical Permit',
    'Mechanical Permit',
    'Sanitary Permit',
    'Plumbing Permit',
    'Electronics Permit',
    'Interior Design Permit',
  ]),
  PermitTypeGroup('Other Permits', ['Fencing Permit', 'Sign Permit', 'Excavation Permit']),
  PermitTypeGroup('Certificates', [
    'FSEC for Building Permit (BFP)',
    'Certificate of Occupancy',
    'FSIC for Occupancy Permit (BFP)',
  ]),
];

const List<String> allPermitTypes = [
  'Building Permit',
  'Demolition Permit',
  'Zoning / Locational Clearance',
  'Architectural Permit',
  'Civil / Structural Permit',
  'Electrical Permit',
  'Mechanical Permit',
  'Sanitary Permit',
  'Plumbing Permit',
  'Electronics Permit',
  'Interior Design Permit',
  'Fencing Permit',
  'Sign Permit',
  'Excavation Permit',
  'FSEC for Building Permit (BFP)',
  'Certificate of Occupancy',
  'FSIC for Occupancy Permit (BFP)',
];
