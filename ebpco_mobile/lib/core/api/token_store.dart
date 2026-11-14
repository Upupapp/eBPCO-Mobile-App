import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/refresh tokens, kept in the platform keystore/keychain rather
/// than plain `SharedPreferences` — a bearer token is a credential, not
/// app state. Mirrors the web portals' own token handling
/// (`auth.service.ts`): `expiresAt` is stored as an absolute instant
/// (computed from the server's `expiresIn` the moment tokens are issued),
/// not "seconds left", so it stays correct however long the app sits in
/// the background.
///
/// The access token and its expiry are also kept in memory once read, so
/// the live-updates check (`LiveUpdates`, about once a second) does not read
/// the keychain twice a second. Safe because every write goes through
/// [save] and [clear], which update the memory copy first; nothing else
/// (no other isolate, no app extension) writes these keys.
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  final _storage = const FlutterSecureStorage();

  static const _accessKey = 'ebpco_access_token';
  static const _refreshKey = 'ebpco_refresh_token';
  static const _expiresAtKey = 'ebpco_access_token_expires_at';

  String? _access;
  bool _accessKnown = false;
  DateTime? _expiresAt;
  bool _expiresAtKnown = false;

  /// Bumped by [clear], so a token refresh that was already out when the
  /// citizen signed out can tell, and does not store its answer.
  int get epoch => _epoch;
  int _epoch = 0;

  Future<void> save({required String accessToken, String? refreshToken, int? expiresInSeconds}) async {
    _access = accessToken;
    _accessKnown = true;
    DateTime? expiresAt;
    if (expiresInSeconds != null) {
      expiresAt = DateTime.now().toUtc().add(Duration(seconds: expiresInSeconds));
      _expiresAt = expiresAt;
      _expiresAtKnown = true;
    }
    await _storage.write(key: _accessKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshKey, value: refreshToken);
    }
    if (expiresAt != null) {
      await _storage.write(key: _expiresAtKey, value: expiresAt.toIso8601String());
    }
  }

  Future<String?> accessToken() async {
    if (_accessKnown) return _access;
    final stored = await _storage.read(key: _accessKey);
    // A save or clear that landed while this read was out is newer.
    if (!_accessKnown) {
      _access = stored;
      _accessKnown = true;
    }
    return _access;
  }

  Future<String?> refreshToken() => _storage.read(key: _refreshKey);

  Future<DateTime?> expiresAt() async {
    if (_expiresAtKnown) return _expiresAt;
    final raw = await _storage.read(key: _expiresAtKey);
    if (!_expiresAtKnown) {
      _expiresAt = raw == null ? null : DateTime.tryParse(raw);
      _expiresAtKnown = true;
    }
    return _expiresAt;
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
    _epoch++;
    _access = null;
    _accessKnown = true;
    _expiresAt = null;
    _expiresAtKnown = true;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiresAtKey);
  }
}
