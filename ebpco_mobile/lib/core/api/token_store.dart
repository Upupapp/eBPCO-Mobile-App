import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/refresh tokens, kept in the platform keystore/keychain rather
/// than plain `SharedPreferences` — a bearer token is a credential, not
/// app state. Mirrors the web portals' own token handling
/// (`auth.service.ts`): `expiresAt` is stored as an absolute instant
/// (computed from the server's `expiresIn` the moment tokens are issued),
/// not "seconds left", so it stays correct however long the app sits in
/// the background.
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  final _storage = const FlutterSecureStorage();

  static const _accessKey = 'ebpco_access_token';
  static const _refreshKey = 'ebpco_refresh_token';
  static const _expiresAtKey = 'ebpco_access_token_expires_at';

  Future<void> save({required String accessToken, String? refreshToken, int? expiresInSeconds}) async {
    await _storage.write(key: _accessKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
    if (expiresInSeconds != null) {
      final expiresAt = DateTime.now().toUtc().add(Duration(seconds: expiresInSeconds));
      await _storage.write(key: _expiresAtKey, value: expiresAt.toIso8601String());
    }
  }

  Future<String?> accessToken() => _storage.read(key: _accessKey);
  Future<String?> refreshToken() => _storage.read(key: _refreshKey);

  Future<DateTime?> expiresAt() async {
    final raw = await _storage.read(key: _expiresAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// True once the access token is within [within] of expiring (or already
  /// has) — the same "refresh proactively before it lapses" margin the web
  /// portals' `scheduleRefresh` uses, so a citizen mid-task never gets
  /// bounced to a sign-in screen just because a request landed a few
  /// seconds late.
  Future<bool> isExpiringWithin(Duration within) async {
    final expiry = await expiresAt();
    if (expiry == null) return false;
    return DateTime.now().toUtc().add(within).isAfter(expiry);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiresAtKey);
  }
}
