import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
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

  http.Client _http = http.Client();
  final _uuid = const Uuid();

  /// Tests answer requests with a fake (`MockClient`) instead of the network.
  @visibleForTesting
  set httpClient(http.Client client) => _http = client;

  /// How close to expiry the access token is refreshed before a request.
  static const _refreshMargin = Duration(seconds: 30);

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
      if (await TokenStore.instance.isExpiringWithin(_refreshMargin)) {
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
    final epoch = TokenStore.instance.epoch;
    final refreshToken = await TokenStore.instance.refreshToken();
    if (refreshToken == null) return;
    try {
      final response = await _http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/auth/token/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      // Signed out while this was out (the live-updates check refreshes in
      // the background): storing its tokens would sign the citizen back in.
      if (epoch != TokenStore.instance.epoch) return;
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

  /// When [quietGet] last started a token refresh itself, on a clock that
  /// changing the phone's time does not move.
  final _clock = Stopwatch()..start();
  Duration? _quietRefreshAt;

  /// A background check made about once a second (`LiveUpdates`, `GET
  /// /me/changes`): the decoded body of a 2xx answer, or null for anything
  /// else — no signal, a timeout, a 5xx and a 401 alike. It never throws and
  /// never calls [onSessionExpired]: a failed background check is not the
  /// citizen's session ending (a request the citizen makes still signs them
  /// out on a 401, as before).
  ///
  /// While the access token is about to expire nothing is sent with it: the
  /// usual refresh runs first (the same one any other request would share),
  /// then the check goes out with the new token. A refresh that does not
  /// help (no signal, or the refresh token refused) is tried again from here
  /// at most every 15 seconds, and the checks are skipped until then.
  /// Reads no keychain while the token is fresh: [TokenStore] keeps it in
  /// memory.
  Future<Object?> quietGet(String path, {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      if (await TokenStore.instance.isExpiringWithin(_refreshMargin)) {
        final now = _clock.elapsed;
        final last = _quietRefreshAt;
        if (last != null && now - last < const Duration(seconds: 15)) return null;
        _quietRefreshAt = now;
        await _tryRefresh().timeout(timeout);
        if (await TokenStore.instance.isExpiringWithin(_refreshMargin)) return null;
      }
      final token = await TokenStore.instance.accessToken();
      if (token == null) return null;
      // Aborted rather than abandoned at the timeout, so a stalled check is
      // never still out when the next one goes.
      final abort = Completer<void>();
      final timer = Timer(timeout, abort.complete);
      try {
        final request = http.AbortableRequest('GET', _uri(path), abortTrigger: abort.future)
          ..headers['Authorization'] = 'Bearer $token';
        final response = await http.Response.fromStream(await _http.send(request));
        if (response.statusCode < 200 || response.statusCode >= 300) return null;
        return _decode(response);
      } finally {
        timer.cancel();
      }
    } catch (_) {
      return null;
    }
  }

  /// An authenticated GET whose body is bytes, not JSON (`GET /me/photo`).
  Future<Uint8List> getBytes(String path) async {
    try {
      final response = await _http.get(_uri(path), headers: await _headers(auth: true));
      if (response.statusCode >= 200 && response.statusCode < 300) return response.bodyBytes;
      return _handle(response, path: path, auth: true) as Uint8List;
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
