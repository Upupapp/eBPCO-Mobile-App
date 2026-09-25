/// A citizen's seeded government-issued ID document, submitted at
/// registration/verification time — FRONTEND SIMULATION ONLY, no real ID
/// verification service. One record per resident, read by Profile >
/// Personal Information's Submitted Government ID section — see
/// utils/government_id.dart's [governmentIdFor]. This is a different
/// concept from the Teresa, Rizal Digital ID (screens/profile/
/// digital_id_screen.dart), which is never built from this record.
class GovernmentIdRecord {
  final String accountId;
  final String idType;
  final String assetPath;
  final String idNumber;
  final String issuingOffice;

  const GovernmentIdRecord({
    required this.accountId,
    required this.idType,
    required this.assetPath,
    required this.idNumber,
    required this.issuingOffice,
  });
}
