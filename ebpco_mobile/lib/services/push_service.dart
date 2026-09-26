import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api/citizen_api.dart';
import '../core/config/firebase_options.dart';

/// A notice the citizen tapped — both ids ride in the push's data
/// (`push-delivery.service.ts`); either may be absent.
class TappedNotice {
  const TappedNotice({this.notificationId, this.applicationId});

  final String? notificationId;
  final String? applicationId;

  static TappedNotice? fromData(Map<String, dynamic> data) {
    String? text(Object? value) => value is String && value.isNotEmpty ? value : null;
    final notice = TappedNotice(notificationId: text(data['notificationId']), applicationId: text(data['applicationId']));
    return notice.notificationId == null && notice.applicationId == null ? null : notice;
  }
}

/// Push notifications over Firebase Cloud Messaging.
///
/// The server decides what to send and when (muted categories, quiet hours);
/// this class only makes the handset reachable: it asks permission, hands the
/// FCM token to `POST /devices` while signed in, removes it on sign-out, shows
/// a notice that arrives while the app is open, and reports a tapped notice
/// so the app can open it.
///
/// Android only for now — see [EbpcoFirebaseOptions].
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  /// Must match the server's `ANDROID_CHANNEL_ID` (fcm-sender.ts).
  static const channelId = 'ebpco_updates';
  static const _deviceIdKey = 'ebpco_push_device_id';
  /// Same icon and tint the manifest gives Firebase for background notices.
  static const _smallIcon = '@drawable/ic_stat_ebpco';
  static const _accent = Color(0xFFC81E2C);

  final _storage = const FlutterSecureStorage();
  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefresh;
  bool _ready = false;

  /// Opens a tapped notice.
  void Function(TappedNotice notice)? onOpen;

  /// A notice tapped before the session was restored (it launched the app).
  TappedNotice? pending;

  TappedNotice? takePending() {
    final notice = pending;
    pending = null;
    return notice;
  }

  /// A notice arrived while the app is in front — refresh the feed and badge.
  VoidCallback? onForegroundMessage;

  bool get supported => !Platform.isIOS;

  Future<void> init() async {
    if (!supported || _ready) return;
    try {
      await Firebase.initializeApp(options: EbpcoFirebaseOptions.android);

      await _local.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings(_smallIcon)),
        onDidReceiveNotificationResponse: (response) => _openPayload(response.payload),
      );
      // The channel background pushes are posted to; created up front so its
      // name and importance are ours rather than Firebase's default.
      await _local
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(const AndroidNotificationChannel(
            channelId,
            'Application updates',
            description: 'Status changes on your permit applications from the Municipality.',
            importance: Importance.high,
          ));

      FirebaseMessaging.onMessage.listen(_showInForeground);
      FirebaseMessaging.onMessageOpenedApp.listen((message) => _open(TappedNotice.fromData(message.data)));
      final launchedFrom = await FirebaseMessaging.instance.getInitialMessage();
      if (launchedFrom != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _open(TappedNotice.fromData(launchedFrom.data)));
      }
      // Tapping an in-app banner while the app was closed launches it here.
      final launch = await _local.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        final payload = launch!.notificationResponse?.payload;
        WidgetsBinding.instance.addPostFrameCallback((_) => _openPayload(payload));
      }
      _ready = true;
    } catch (e) {
      // Push is a convenience, never the record — the in-app feed still works.
      debugPrint('Push unavailable: $e');
    }
  }

  /// Call once signed in: asks permission (Android 13+) and registers this
  /// handset with the server. Safe to call on every launch — the server
  /// de-duplicates the same token.
  Future<void> registerSignedIn() async {
    if (!_ready) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
      _tokenRefresh ??= FirebaseMessaging.instance.onTokenRefresh.listen(_register);
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  /// Call on a fresh sign-in. A registration still stored here belongs to a
  /// session that ended without removing it (it could not reach the server),
  /// possibly another account's — rotate the token so that account's notices
  /// stop reaching whoever signs in now.
  Future<void> registerAfterSignIn() async {
    if (await _storage.read(key: _deviceIdKey) != null) await forgetLocally();
    await registerSignedIn();
  }

  Future<void> _register(String token) async {
    try {
      final deviceId = await CitizenApi.instance.registerDevice(
        platform: 'android',
        pushToken: token,
        locale: Platform.localeName,
      );
      await _storage.write(key: _deviceIdKey, value: deviceId);
    } catch (e) {
      debugPrint('Push token not registered: $e');
    }
  }

  /// Call BEFORE the session is revoked (removing the device needs it):
  /// stops pushes to this handset for the account signing out.
  Future<void> unregister() async {
    final deviceId = await _storage.read(key: _deviceIdKey);
    if (deviceId != null) {
      try {
        await CitizenApi.instance.removeDevice(deviceId);
      } catch (_) {
        // Best effort; deleting the token below makes the old one unusable.
      }
      await _storage.delete(key: _deviceIdKey);
    }
    await forgetLocally();
  }

  /// The session is already gone (expired, erased) so the server cannot be
  /// told — rotate the token so the old registration can never reach this
  /// handset; the server prunes it as UNREGISTERED on its next attempt.
  Future<void> forgetLocally() async {
    await _tokenRefresh?.cancel();
    _tokenRefresh = null;
    await _storage.delete(key: _deviceIdKey);
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  void _showInForeground(RemoteMessage message) {
    onForegroundMessage?.call();
    final notice = message.notification;
    if (notice == null) return;
    _local.show(
      id: message.messageId.hashCode,
      title: notice.title,
      body: notice.body,
      payload: jsonEncode(message.data),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Application updates',
          importance: Importance.high,
          priority: Priority.high,
          color: _accent,
        ),
      ),
    );
  }

  void _openPayload(String? payload) {
    if (payload == null) return;
    try {
      _open(TappedNotice.fromData(jsonDecode(payload) as Map<String, dynamic>));
    } on FormatException {
      // Not one of ours.
    }
  }

  void _open(TappedNotice? notice) {
    if (notice != null) onOpen?.call(notice);
  }
}
