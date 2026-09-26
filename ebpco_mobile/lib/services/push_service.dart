import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api/citizen_api.dart';
import '../core/config/firebase_options.dart';

/// Push notifications over Firebase Cloud Messaging.
///
/// The server decides what to send and when (muted categories, quiet hours);
/// this class only makes the handset reachable: it asks permission, hands the
/// FCM token to `POST /devices` while signed in, removes it on sign-out, shows
/// a notice that arrives while the app is open, and opens the application a
/// notice is about when it is tapped.
///
/// Android only for now — see [EbpcoFirebaseOptions].
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  /// Must match the server's `ANDROID_CHANNEL_ID` (fcm-sender.ts).
  static const channelId = 'ebpco_updates';
  static const _deviceIdKey = 'ebpco_push_device_id';

  final _storage = const FlutterSecureStorage();
  final _local = FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefresh;
  bool _ready = false;

  /// Opens the application a tapped notice is about.
  void Function(String applicationId)? onOpenApplication;

  /// A tapped notice that arrived before the session was restored.
  String? pendingApplicationId;

  String? takePendingApplication() {
    final id = pendingApplicationId;
    pendingApplicationId = null;
    return id;
  }

  /// A notice arrived while the app is in front — refresh the feed and badge.
  VoidCallback? onForegroundMessage;

  bool get supported => !Platform.isIOS;

  Future<void> init() async {
    if (!supported || _ready) return;
    try {
      await Firebase.initializeApp(options: EbpcoFirebaseOptions.android);

      await _local.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
        onDidReceiveNotificationResponse: (response) => _openFromData(response.payload),
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
      FirebaseMessaging.onMessageOpenedApp.listen((message) => _openFromData(message.data['applicationId']));
      final launchedFrom = await FirebaseMessaging.instance.getInitialMessage();
      if (launchedFrom != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openFromData(launchedFrom.data['applicationId']));
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
      payload: message.data['applicationId'],
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Application updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void _openFromData(Object? applicationId) {
    if (applicationId is String && applicationId.isNotEmpty) onOpenApplication?.call(applicationId);
  }
}
