import 'lgu_contact.dart';

/// The office that reviews, and so heads the documents of, each permit type
/// — the portal's `requirements-catalog.ts` reviewing offices and its
/// `issuingOfficeFor`, all read from [Offices] (design review I5, 4 Nov
/// 2026). It picks a document's header (`PaperHeader`): the Bureau of Fire
/// Protection's for the BFP certificates, the Municipality's for everything
/// else. The BFP types are retired (the BFP issues them through BFP-FSIS) but
/// stay here so an application filed before that still heads its documents
/// correctly. The Building Official for anything else, as the backend does.
String reviewingOfficeFor(String permitType) {
  switch (permitType) {
    case 'Zoning / Locational Clearance':
      return Offices.zoning.name;
    case 'FSEC for Building Permit (BFP)':
    case 'FSIC for Occupancy Permit (BFP)':
      return Offices.fireStation.name;
    default:
      return Offices.buildingOfficial.name;
  }
}
