import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/splash/splash_screen.dart';
import 'services/applications_service.dart';
import 'services/notifications_service.dart';
import 'services/session_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const EbpcoMobileApp());
}

class EbpcoMobileApp extends StatelessWidget {
  const EbpcoMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionService()),
        ChangeNotifierProvider(create: (_) => ApplicationsService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(
        title: 'eBPCO',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      ),
    );
  }
}
