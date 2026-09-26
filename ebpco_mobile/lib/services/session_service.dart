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
      _profile = await _api.me();
      _state = SessionState.signedIn;
      unawaited(PushService.instance.registerSignedIn());
    } catch (_) {
      // The stored token no longer works (refresh token also expired/
      // revoked) — same as the web portals' own restore(): fall back to
      // signed-out rather than surfacing an error for something the
      // citizen never actively did this session.
      await TokenStore.instance.clear();
      _state = SessionState.signedOut;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _lastError = null;
    try {
      await _api.login(email, password);
      _profile = await _api.me();
      _state = SessionState.signedIn;
      notifyListeners();
      unawaited(PushService.instance.registerSignedIn());
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
