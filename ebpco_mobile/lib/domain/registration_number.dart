/// A business's DTI / SEC / CDA registration number, checked the way the
/// server checks it (`businesses/registration-number.ts`) and the citizen
/// portal does (QA finding TC-24, 2026-10-03: "x" was accepted, printed on
/// the business and shown to staff, and could never be corrected).
///
/// Loose on purpose: the three registries number differently, and this app
/// is not the registry. It refuses what cannot be one. Null when acceptable.
library;

import 'models.dart';

String? registrationNumberProblem(String value) {
  final number = value.trim();
  if (number.length < 5 || number.length > 40) {
    return 'Enter the DTI, SEC or CDA registration number exactly as it appears on the certificate (5 to 40 characters).';
  }
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9 ./-]*$').hasMatch(number)) {
    return 'A registration number has only letters, numbers, spaces, hyphens, slashes and periods.';
  }
  if (RegExp(r'\d').allMatches(number).length < 4) {
    return 'A registration number has at least 4 digits. Copy it from the DTI, SEC or CDA certificate.';
  }
  return null;
}

/// Whether an application filed under [businessId] has reached the office —
/// the server's cut-off, after which the office corrects the registration.
bool registrationLockedBy(Iterable<ApplicationSummary> applications, String businessId) =>
    applications.any((a) => a.businessId == businessId && a.lifecycleStatus != 'Draft');
