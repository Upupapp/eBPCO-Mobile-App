import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'screens/applications/application_detail_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/applications_service.dart';
import 'services/businesses_service.dart';
import 'services/notifications_service.dart';
import 'services/push_service.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';
import 'theme/text_scale_clamp.dart';
import 'widgets/message_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.instance.init();
  runApp(EbpcoMobileApp());
}

class _UnfocusOnNavigate extends NavigatorObserver {
  void _unfocus() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _unfocus();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _unfocus();
}

class EbpcoMobileApp extends StatelessWidget {
  EbpcoMobileApp({super.key}) {
    ApiClient.instance.onSessionExpired = _onSessionExpired;
    PushService.instance
      ..onForegroundMessage = () {
        _notifications.refresh();
        _applications.refresh();
      }
      ..onOpen = _openNotice;
  }

  /// A tapped notice counts as read, the same as tapping it in the Alerts
  /// feed, and opens the application it is about.
  void _openNotice(TappedNotice notice) {
    if (!_session.isSignedIn) {
      // It launched the app and the session is still being restored.
      // RootShell hands it back here once the signed-in shell appears.
      PushService.instance.pending = notice;
      return;
    }
    final notificationId = notice.notificationId;
    if (notificationId != null) {
      _notifications.markRead(notificationId).catchError((_) {});
    } else {
      _notifications.refresh();
    }
    final applicationId = notice.applicationId;
    if (applicationId != null) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: applicationId)),
      );
    }
  }

  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  final _session = SessionService();
  final _applications = ApplicationsService();
  final _notifications = NotificationsService();
  final _businesses = BusinessesService();

  /// Same outcome as the portal's interceptor on a real 401: drop the
  /// session, clear every cached list, and go to Sign in — once, however
  /// many requests failed together.
  Future<void> _onSessionExpired() async {
    if (!_session.isSignedIn) return;
    await _session.dropSession();
    _applications.clear();
    _notifications.clear();
    _businesses.clear();
    _navigatorKey.currentState?.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    _messengerKey.currentState?.showSnackBar(messageBar('Your session has ended. Please sign in again.'));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _session),
        ChangeNotifierProvider.value(value: _applications),
        ChangeNotifierProvider.value(value: _notifications),
        ChangeNotifierProvider.value(value: _businesses),
      ],
      child: MaterialApp(
        title: 'eBPCO',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorKey: _navigatorKey,
        scaffoldMessengerKey: _messengerKey,
        // Leaving a page never hands the keyboard to the page underneath —
        // otherwise popping back to Sign in re-opens it over the form.
        navigatorObservers: [_UnfocusOnNavigate()],
        builder: (context, child) => TextScaleClamp(child: child!),
        home: const SplashScreen(),
      ),
    );
  }
}
