/// Whether a Digital ID wallet credential currently reads as usable — this
/// project has no real issuance/renewal system, so this is set once at seed
/// time (see MockCatalog) rather than computed from anything live.
enum CredentialStatus { active, inactive, expired }

extension CredentialStatusX on CredentialStatus {
  String get label => switch (this) {
    CredentialStatus.active => 'Active',
    CredentialStatus.inactive => 'Inactive',
    CredentialStatus.expired => 'Expired',
  };
}

/// One credential in a resident's Digital ID wallet (see
/// screens/profile/digital_id_screen.dart) — an *already-issued* official
/// government/LGU ID the resident can view digitally: Barangay Resident ID,
/// PWD ID today, and future ones (National ID, PhilHealth, Senior Citizen,
/// etc.) simply by adding another record here, never by rebuilding the
/// screen. This is a completely different concept from the physical ID a
/// resident *submits* during registration/verification (see
/// utils/government_id.dart's GovernmentIdRecord) — never built from that
/// record, and never shown for an unverified account. FRONTEND SIMULATION
/// ONLY — no real eGovPH/PhilSys/PhilHealth/LGU database integration.
class DigitalCredential {
  final String id;
  final String type;
  final String displayName;
  final String holderName;
  final String frontAsset;
  final String backAsset;
  final CredentialStatus status;

  /// Null when the source ID doesn't print an expiry (both of this
  /// project's seeded credentials — see MockCatalog — genuinely don't; a
  /// resident/PWD ID here isn't invented with a fabricated date just to
  /// fill this field).
  final DateTime? validUntil;
  final String? issuer;
  final Map<String, String> metadata;

  const DigitalCredential({
    required this.id,
    required this.type,
    required this.displayName,
    required this.holderName,
    required this.frontAsset,
    required this.backAsset,
    this.status = CredentialStatus.active,
    this.validUntil,
    this.issuer,
    this.metadata = const {},
  });
}
