/// Maps an office name (as stored on `CatalogItem.office`) to its real
/// logo asset under `assets/images/Logo/`, for the Dokyu/Tulong (and
/// shared request-catalog) office-selection cards — replacing the generic
/// blue building placeholder icon.
///
/// Falls back to the Teresa, Rizal municipal seal when an office has no clear
/// specific logo in the project, or when the office string names more than
/// one agency jointly (e.g. "BFP / MDRRMO") — a single logo would misrepresent
/// a joint listing, so those intentionally fall back too rather than guessing
/// which of the two agencies "wins".
library;

import 'teresa_rizal_seal.dart';

const Map<String, String> _officeLogos = {
  // Municipal Social Welfare and Development Office — the project uses
  // MSWD/MSWDO interchangeably for this office, but only one logo file
  // exists (mswd-logo-removebg-preview.png); both spellings map to it.
  'Municipal Social Welfare and Development Office': 'assets/images/Logo/mswd-logo-removebg-preview.png',
  'Municipal Social Welfare & Development Office': 'assets/images/Logo/mswd-logo-removebg-preview.png',

  'Business Permits and Licensing Office': 'assets/images/Logo/BPLO-removebg-preview.png',
  'Municipal Public Employment Service Office': 'assets/images/Logo/logo-peso-removebg-preview.png',
  'Office for Senior Citizens Affairs': 'assets/images/Logo/OSCA-removebg-preview.png',
  'Persons with Disability Affairs Office': 'assets/images/Logo/PDAO-removebg-preview.png',

  // The only disaster-office logo asset in the project is named NDRRMO
  // (not MDRRMO) — used here as the closest match for both the full
  // municipal office name and the short "MDRRMO" form that appears on
  // Sakuna's own incident-type catalog. Reported as an ambiguous
  // filename match, per the task's own instruction, rather than silently
  // assumed correct.
  'Municipal Disaster Risk Reduction and Management Office': 'assets/images/Logo/NDRRMO-removebg-preview.png',
  'MDRRMO': 'assets/images/Logo/NDRRMO-removebg-preview.png',
};

/// Returns the logo asset for [office], or [teresaRizalSealAsset] if none is
/// mapped — including offices with no dedicated asset at all (Civil
/// Registrar, Municipal Agriculture Office, Municipal Planning and
/// Development Office, Treasurer's Office, Office of the Municipal Mayor,
/// Barangay Hall) and joint/compound office strings ("BFP / MDRRMO",
/// "Municipal Health Office / MDRRMO", "MDRRMO / PNP") that name more than
/// one agency at once.
String officeLogoAsset(String office) => _officeLogos[office] ?? teresaRizalSealAsset;
