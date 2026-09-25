import '../models/citizen_account.dart';
import '../models/digital_credential.dart';
import '../services/mock_catalog.dart';

/// Every account id with a seeded Digital ID wallet — deliberately just
/// verified Perlita Quiambao for this milestone (see
/// MockCatalog.verifiedDemoDigitalCredentials's own doc comment for why). Adding
/// a wallet for another resident, or another credential to an existing
/// wallet, only ever touches this map/MockCatalog — never
/// screens/profile/digital_id_screen.dart itself.
const _walletsByAccountId = <String, List<DigitalCredential>>{
  'ESP-RES-2024-9002': MockCatalog.verifiedDemoDigitalCredentials,
};

/// The Digital ID wallet for [account] — empty for every account without a
/// seeded wallet (including Nicanor, both Anacleto accounts, and any
/// unverified account, though the screen itself never calls this for an
/// unverified one in the first place).
List<DigitalCredential> digitalCredentialsFor(CitizenAccount? account) {
  if (account == null) return const [];
  return _walletsByAccountId[account.id] ?? const [];
}
