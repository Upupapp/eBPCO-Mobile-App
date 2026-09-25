import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'screens/auth/login_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'services/applications_service.dart';
import 'services/businesses_service.dart';
import 'services/notifications_service.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(EbpcoMobileApp());
}

class EbpcoMobileApp extends StatelessWidget {
  EbpcoMobileApp({super.key}) {
    ApiClient.instance.onSessionExpired = _onSessionExpired;
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
    _messengerKey.currentState?.showSnackBar(const SnackBar(content: Text('Your session has ended. Please sign in again.')));
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
        home: const SplashScreen(),
      ),
    );
  }
}
