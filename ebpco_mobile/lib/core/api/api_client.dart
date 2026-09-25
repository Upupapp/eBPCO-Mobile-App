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
/// itself finally expired/was revoked) is thrown as a normal [ApiError] and
/// also reported through [onSessionExpired]; the app (main.dart) owns what
/// happens next — this class never navigates.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final http.Client _http = http.Client();
  final _uuid = const Uuid();

  /// `Content-Type` only when a JSON body is sent: the server refuses a
  /// JSON-labelled request with an empty body (a bare DELETE included).
  Future<Map<String, String>> _headers({required bool auth, bool json = false}) async {
    final headers = <String, String>{if (json) 'Content-Type': 'application/json'};
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

  /// Called when an authenticated request answers 401 — the token no longer
  /// works (expired, revoked or disabled alike). The app signs out and goes
  /// back to Sign in, like the portal's `citizen-auth.interceptor.ts`.
  void Function()? onSessionExpired;

  dynamic _handle(http.Response response, {required String path, required bool auth}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decode(response);
    }
    // `POST /auth/password/change` answers 401 for a wrong CURRENT password
    // on a perfectly valid session — the one 401 that must not sign out.
    if (auth && response.statusCode == 401 && !path.endsWith('/auth/password/change')) {
      onSessionExpired?.call();
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
      return _handle(response, path: path, auth: auth) as T;
    } on http.ClientException {
      throw const ApiError(0, null, true);
    }
  }

  Future<T> post<T>(String path, {Map<String, dynamic>? body, bool auth = true, String? idempotencyKey}) async {
    try {
      final headers = await _headers(auth: auth, json: true);
      if (idempotencyKey != null) headers['Idempotency-Key'] = idempotencyKey;
      final response = await _http.post(_uri(path), headers: headers, body: jsonEncode(body ?? const <String, dynamic>{}));
      return _handle(response, path: path, auth: auth) as T;
    } on http.ClientException {
      throw const ApiError(0, null, true);
    }
  }

  Future<T> patch<T>(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    try {
      final response = await _http.patch(_uri(path), headers: await _headers(auth: auth, json: true), body: jsonEncode(body ?? const <String, dynamic>{}));
      return _handle(response, path: path, auth: auth) as T;
    } on http.ClientException {
      throw const ApiError(0, null, true);
    }
  }

  Future<T> put<T>(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    try {
      final response = await _http.put(_uri(path), headers: await _headers(auth: auth, json: true), body: jsonEncode(body ?? const <String, dynamic>{}));
      return _handle(response, path: path, auth: auth) as T;
    } on http.ClientException {
      throw const ApiError(0, null, true);
    }
  }

  Future<T> delete<T>(String path, {bool auth = true}) async {
    try {
      final response = await _http.delete(_uri(path), headers: await _headers(auth: auth));
      return _handle(response, path: path, auth: auth) as T;
    } on http.ClientException {
      throw const ApiError(0, null, true);
    }
  }
}
