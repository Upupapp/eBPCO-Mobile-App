/// The office that reviews, and so heads the documents of, each permit type
/// — the portal's `requirements-catalog.ts` reviewing offices, which pick a
/// document's header (`agencyHeaderFor`): the Bureau of Fire Protection's for
/// the BFP certificates, the Municipality's for everything else.
String reviewingOfficeFor(String permitType) {
  switch (permitType) {
    case 'Zoning / Locational Clearance':
      return 'Municipal Planning and Development Office (MPDO / Zoning)';
    case 'FSEC for Building Permit (BFP)':
    case 'FSIC for Occupancy Permit (BFP)':
      return 'Bureau of Fire Protection — Castilla Fire Station';
    case 'Certificate of Occupancy':
      return 'Office of the Building Official (OBO) / BFP';
    default:
      return 'Office of the Building Official (OBO)';
  }
}
