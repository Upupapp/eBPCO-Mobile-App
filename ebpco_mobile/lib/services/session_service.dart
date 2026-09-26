import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/api/citizen_api.dart';
import '../core/api/problem.dart';
import '../core/api/token_store.dart';
import '../domain/models.dart';
import 'push_service.dart';

enum SessionState { loading, signedOut, signedIn }

/// The citizen's own session — real, HTTP-backed (unlike the design
/// reference's `CitizenSessionService`, which is a frontend-only mock over
/// `shared_preferences`). [AuthGate] in main.dart watches [state] the same
/// way that mock's own `AuthGate` watches `isSignedIn`.
class SessionService extends ChangeNotifier {
  final _api = CitizenApi.instance;

  SessionState _state = SessionState.loading;
  MeProfile? _profile;
  String? _lastError;

  SessionState get state => _state;
  MeProfile? get profile => _profile;
  String? get lastError => _lastError;
  bool get isSignedIn => _state == SessionState.signedIn;

  /// Called once at app start: a stored access token (even if just
  /// expired — [ApiClient] refreshes proactively) means try to restore the
  /// session rather than showing Login first and flashing to Dashboard.
  Future<void> restore() async {
    final token = await TokenStore.instance.accessToken();
    if (token == null) {
      _state = SessionState.signedOut;
      notifyListeners();
      return;
    }
    try {
      _profile = await _meWhenReachable();
      _state = SessionState.signedIn;
      unawaited(PushService.instance.registerSignedIn());
    } on ApiError catch (e) {
      // Only the server refusing the session ends it. No signal, a timeout
      // or a 5xx keeps the stored tokens — like the web portals' own
      // restore() — so the next launch tries again instead of the citizen
      // being signed out for opening the app in a dead zone.
      if (e.status == 401 || e.status == 403) await TokenStore.instance.clear();
      _state = SessionState.signedOut;
    } catch (_) {
      _state = SessionState.signedOut;
    }
    notifyListeners();
  }

  /// `/me`, retried briefly while the server is unreachable: opening the app
  /// right as the phone boots or regains signal is the ordinary case.
  Future<MeProfile> _meWhenReachable() async {
    for (var attempt = 0; ; attempt++) {
      try {
        return await _api.me();
      } on ApiError catch (e) {
        if (e.status != 0 || attempt == 3) rethrow;
        await Future<void>.delayed(Duration(seconds: 1 << attempt));
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _lastError = null;
    try {
      await _api.login(email, password);
      _profile = await _api.me();
      _state = SessionState.signedIn;
      notifyListeners();
      unawaited(PushService.instance.registerAfterSignIn());
      return true;
    } on ApiError catch (e) {
      _lastError = e.citizenMessage;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    // Signed-out first, so a 401 while unregistering is not mistaken for an
    // expired session mid-use; the stored token is still sent until revoked.
    _state = SessionState.signedOut;
    await PushService.instance.unregister();
    await _api.logout();
    _profile = null;
    notifyListeners();
  }

  /// The server no longer accepts this session — nothing to revoke, just
  /// forget it locally.
  Future<void> dropSession() async {
    await TokenStore.instance.clear();
    await PushService.instance.forgetLocally();
    _profile = null;
    _state = SessionState.signedOut;
    notifyListeners();
  }

  /// Re-fetches `/me` — call after any profile edit so every screen reading
  /// [profile] sees the same, current record.
  Future<void> refreshProfile() async {
    if (!isSignedIn) return;
    _profile = await _api.me();
    notifyListeners();
  }
}
