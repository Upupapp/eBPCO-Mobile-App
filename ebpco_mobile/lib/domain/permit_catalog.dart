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
  // Not the FSEC or the FSIC: see [retiredPermitTypes].
  PermitTypeGroup('Certificates', ['Certificate of Occupancy']),
];

/// Still recognised on old records, no longer filed through eBPCO (ebpco-api
/// migration 060 refuses them). The Bureau of Fire Protection issues the FSEC
/// and the FSIC itself, through its own online system BFP-FSIS (BFP
/// Memorandum Circular 2024-024). The citizen gets it there and uploads it
/// with their Building Permit or Certificate of Occupancy, where the Fire
/// Safety stage verifies it. Mirrors the portal's `RETIRED_PERMIT_TYPES`.
const Set<String> retiredPermitTypes = {
  'FSEC for Building Permit (BFP)',
  'FSIC for Occupancy Permit (BFP)',
};

/// How many permit types a citizen can apply for today: every one the
/// catalog groups offer (the retired BFP types are not among them).
int get offeredPermitTypeCount => permitTypeGroups.fold(0, (sum, group) => sum + group.types.length);

/// Where the BFP's own online system is, for every notice that sends a
/// citizen there.
const String bfpFsisUrl = 'https://fsis.e-bfp.com';

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
