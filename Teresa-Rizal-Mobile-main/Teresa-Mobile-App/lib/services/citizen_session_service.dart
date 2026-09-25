import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/access_level.dart';
import '../models/citizen_account.dart';
import '../theme/app_status.dart';
import 'mock_catalog.dart';
import 'persistence_recovery.dart';

/// Frontend-only session simulation — the mobile equivalent of the Web
/// Admin's `Alpine.store('citizenSession')` in resources/js/app.js. No real
/// backend call is made; the signed-in account is just persisted locally
/// via SharedPreferences (the mobile analogue of the Web Admin's
/// localStorage-based session). Registration here creates a local
/// CitizenAccount the same shape a real backend's `residents` table would
/// need — see TERESA_RIZAL_MOBILE_WEB_ALIGNMENT.md Section 8.
///
/// This is also the single source of truth for [accessLevel] — the only
/// place in the app that decides Guest vs Authenticated/unverified vs
/// Verified, so individual screens never need to re-derive that logic
/// themselves (see widgets/access_guard.dart).
class CitizenSessionService extends ChangeNotifier {
  static const _key = 'teresa_rizal_citizen_session';
  static const _guestKey = 'teresa_rizal_guest_mode';

  CitizenAccount? _account;
  bool _loading = true;
  bool _isGuest = false;

  CitizenAccount? get account => _account;
  bool get isSignedIn => _account != null;
  bool get isGuest => _isGuest;
  bool get loading => _loading;

  /// Guest (not signed in, browsing public content) < Authenticated but
  /// unverified (has an account, `status` isn't yet 'Approved') <
  /// Verified (`status == 'Approved'`) — reuses the same universal status
  /// vocabulary as service requests (see theme/app_status.dart) rather
  /// than inventing a parallel one.
  AccessLevel get accessLevel {
    final acc = _account;
    if (acc == null) return AccessLevel.guest;
    final status = AppStatusX.fromLabel(acc.status);
    // `Approved` and `Verified` are the same state under two names. The Web
    // Admin stores `Approved` and *displays* `Verified`
    // (constituents.blade.php: `$acct['status'] === 'Approved' ? 'Verified'`),
    // and its own comment says `Verified` grants full Dokyu/Tulong access.
    // Mobile writes only `Approved` today, so this is additive — but before
    // `verified` existed in AppStatus, a status arriving as `Verified` resolved
    // to `draft` and locked the citizen OUT of Dokyu, meaning the identical
    // word granted access on one surface and denied it on the other.
    final isVerified = status == AppStatus.approved || status == AppStatus.verified;
    return isVerified ? AccessLevel.verified : AccessLevel.unverified;
  }

  CitizenSessionService() {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw != null) {
        _account = CitizenAccount.fromJson(jsonDecode(raw));
        final migrated = _migrateStaleDemoIdentity(_account!);
        if (migrated != null) {
          _account = migrated;
          await prefs.setString(_key, jsonEncode(migrated.toJson()));
        }
      } else {
        _isGuest = prefs.getBool(_guestKey) ?? false;
      }
    } catch (error) {
      // A payload persisted by an earlier build can fail to decode after a
      // model or enum changes shape. Before this guard that throw escaped an
      // un-awaited future started in the constructor, so notifyListeners()
      // never fired and AuthGate spun on the splash forever - recoverable
      // only by clearing app data. Discard the unreadable state instead; the
      // migrations here already exist for exactly this class of change.
      _account = null;
      _isGuest = false;
      // Only the session key — the guest flag is a separate, still-readable key.
      await PersistenceRecovery.discardUnreadable(
        service: 'CitizenSessionService',
        keys: const [_key],
        error: error,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }


  /// A browser signed in before the Perlita-Quiambao-to-Perlita-Quiambao demo
  /// identity correction has that exact stale [CitizenAccount] snapshot
  /// persisted (see [login]'s full-object jsonEncode) — a source-code fix
  /// alone never reaches it, since this only ever reads back whatever was
  /// saved. Remaps a stale snapshot to the current, correct demo account
  /// object (by matching its old id) rather than forcing a manual re-login;
  /// returns null for every other account, which is left untouched.
  CitizenAccount? _migrateStaleDemoIdentity(CitizenAccount stale) {
    if (stale.id == 'ESP-RES-2024-1203') return MockCatalog.demoAccounts.last;
    if (stale.id == 'ESP-RES-2024-1203-DUP') return MockCatalog.duplicateVerifiedDemoAccount;
    return null;
  }

  Future<void> login(CitizenAccount account) async {
    _account = account;
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(account.toJson()));
    await prefs.remove(_guestKey);
    notifyListeners();
  }

  /// Section 5/6 — enters the app without an account. Guests get Home +
  /// public Balita only; everything else routes through [AccessGuard].
  Future<void> continueAsGuest() async {
    _account = null;
    _isGuest = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.setBool(_guestKey, true);
    notifyListeners();
  }

  /// Ends a guest session so Sign In / Create Account start from a clean
  /// slate — called from RestrictedFeatureNotice before navigating away.
  Future<void> endGuestSession() async {
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestKey);
    notifyListeners();
  }

  Future<void> logout() async {
    _account = null;
    _isGuest = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_guestKey);
    notifyListeners();
  }

  Future<void> updateProfile(CitizenAccount updated) async {
    _account = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(updated.toJson()));
    notifyListeners();
  }
}
