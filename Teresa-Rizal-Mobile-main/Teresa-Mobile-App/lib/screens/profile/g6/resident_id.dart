import '../../../models/citizen_account.dart';
import '../../../theme/app_status.dart';

/// The resident ID shown on the Profile hub row and on the Digital ID card.
///
/// One constant, two surfaces. A verified demo account shows the sample
/// number. Every other account, including Guest and Unverified, shows an
/// em dash until a real ID exists.
class ResidentId {
  ResidentId._();

  /// Sample number for the verified demo. Not an issued credential.
  static const verifiedSample = 'TR-SAMPLE-000412';

  static const blank = '—';

  static bool isVerified(CitizenAccount? account) {
    if (account == null) return false;
    final status = AppStatusX.fromLabel(account.status);
    return status == AppStatus.approved || status == AppStatus.verified;
  }

  static String displayFor(CitizenAccount? account) =>
      isVerified(account) ? verifiedSample : blank;
}
