import 'citizen_session_service.dart';
import 'master_file_service.dart';
import 'notifications_service.dart';
import 'requests_service.dart';
import 'resident_profile_service.dart';

/// The one place that knows what signing out has to erase.
///
/// `CitizenSessionService.logout()` clears the session and the guest flag — two
/// of the app's ten preference keys. On its own that leaves the citizen's
/// resident profile (birthdate, address, household, family and the base64
/// profile photo), their whole request history, their uploaded Master File
/// documents and their notification bookkeeping sitting on the device, in
/// plaintext, after they have signed out.
///
/// That matters here more than it would elsewhere: this is a municipal app for
/// a whole municipality, and it will be used on shared and family handsets. The
/// next person to sign in would not *see* the previous citizen's data — every
/// service keys by account id — but it is still on disk and still recoverable.
///
/// This exists as a single coordinator rather than as logic inside each caller
/// because there are two sign-out entry points (the profile screen and the
/// drawer). Two copies of a rule is how they end up disagreeing.
///
/// It is deliberately **not** inside `CitizenSessionService`: that service owns
/// the session, not the other five services, and giving it references to them
/// would invert the dependency direction the whole app is built on.
class SignOut {
  SignOut._();

  /// Signs [session] out and erases everything that belonged to that account.
  ///
  /// Order matters: the data is erased *first*, then the session is cleared.
  /// Clearing the session first would leave nothing to identify which account's
  /// data to erase if any step after it failed.
  ///
  /// Deliberately **not** erased:
  /// - `teresa_rizal_onboarding_complete` — a device-level preference about
  ///   whether the welcome flow has been seen, not personal data. Re-showing
  ///   onboarding to whoever picks the phone up next would be noise.
  /// - Balita announcements — public municipal content, identical for everyone.
  static Future<void> signOut(
    CitizenSessionService session, {
    required RequestsService requests,
    required ResidentProfileService profiles,
    required MasterFileService masterFile,
    required NotificationsService notifications,
  }) async {
    final accountId = session.account?.id;

    if (accountId != null) {
      await requests.forgetAccount(accountId);
      await profiles.forgetAccount(accountId);
      await masterFile.forgetAccount(accountId);
      await notifications.forgetAccount(accountId);
    }

    await session.logout();
  }
}
