import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import 'problem.dart';
import 'token_store.dart';

/// One HTTP client for the whole app, wrapping bearer-token auth, RFC7807
/// error parsing, and the access-token-expiring-soon-so-refresh-first check
/// every authenticated call needs — mirrors the web portals'
/// `citizen-api.client.ts` + `citizen-auth.interceptor.ts` combined into
/// one place, since there is no separate HTTP-interceptor layer in this
/// stack.
///
/// A 401 still reachable after that proactive refresh (the refresh token
/// itself finally expired/was revoked) is surfaced as a normal [ApiError];
/// it is [SessionService]'s job to notice that and sign the citizen out —
/// this class never navigates, same separation of concerns as the web
/// interceptor deferring to `AuthService`.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  final _uuid = const Uuid();

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      // Proactive refresh before the call, not reactive-after-401: the
      // Documents step of the wizard can be mid-upload for several
      // seconds, and refreshing only after a 401 would mean re-sending a
      // multi-hundred-KB body a second time. Same trade-off the web
      // portals' `scheduleRefresh` background timer makes.
      if (await TokenStore.instance.isExpiringWithin(const Duration(seconds: 30))) {
        await _tryRefresh();
      }
      final token = await TokenStore.instance.accessToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<void>? _refreshInFlight;

  /// Coalesces concurrent refresh attempts into one in-flight call, so two
  /// requests racing the same expiring token don't both spend the (single-
  /// use) refresh token.
  Future<void> _tryRefresh() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<void> _doRefresh() async {
    final refreshToken = await TokenStore.instance.refreshToken();
    if (refreshToken == null) return;
    try {
      final response = await _http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/token/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        await TokenStore.instance.save(
          accessToken: body['accessToken'] as String,
          refreshToken: body['refreshToken'] as String?,
          expiresInSeconds: body['expiresIn'] as int?,
        );
      }
      // A refused refresh is not thrown here: the caller's own request goes
      // on to use whatever token is stored (now stale) and gets a normal
      // 401 back, which is the signal SessionService already watches for.
    } catch (_) {
      // Network failure refreshing: same reasoning — let the real request
      // surface its own error rather than doubling up on one here.
    }
  }

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  dynamic _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  dynamic _handle(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decode(response);
    }
    throw problemFrom(_decode(response), response.statusCode);
  }

  /// A fresh Idempotency-Key — required on every write this app makes,
  /// same rule as the web portals (the mobile client is the one this
  /// header exists for: it queues writes offline and replays them, so a
  /// missing key is a duplicate filing waiting for a dropped connection).
  String newIdempotencyKey() => _uuid.v4();

  Future<T> get<T>(String path, {bool auth = true}) async {
    try {
      final response = await _http.get(_uri(path), headers: await _headers(auth: auth));
      return _handle(response) as T;
    } on http.ClientException {
      throw const ApiError(0, null, true);
    }
  }

  Future<T> post<T>(String path, {Map<String, dynamic>? body, bool auth = true, String? idempotencyKey}) async {
    try {
      final headers = await _headers(auth: auth);
      if (idempotencyKey != null) headers['Idempotency-Key'] = idempotencyKey;
      final response = await _http.post(_uri(path), headers: headers, body: body == null ? null : jsonEncode(body));
      return _handle(response) as T;
    } on http.ClientException {
      throw const ApiError(0, null, true);
    }
  }

  Future<T> patch<T>(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    try {
      final response = await _http.patch(_uri(path), headers: await _headers(auth: auth), body: body == null ? null : jsonEncode(body));
      return _handle(response) as T;
    } on http.ClientException {
      throw const ApiError(0, null, true);
    }
  }

  Future<T> delete<T>(String path, {bool auth = true}) async {
    try {
      final response = await _http.delete(_uri(path), headers: await _headers(auth: auth));
      return _handle(response) as T;
    } on http.ClientException {
      throw const ApiError(0, null, true);
    }
  }
}
