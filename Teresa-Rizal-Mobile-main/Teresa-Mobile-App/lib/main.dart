import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/tulong_program_route.dart';
import 'screens/auth/login_screen.dart';
import 'screens/catalog/tulong_program_placeholder.dart';
import 'screens/home/root_shell.dart';
import 'screens/splash/splash_screen.dart';
import 'services/balita_service.dart';
import 'services/citizen_session_service.dart';
import 'services/master_file_service.dart';
import 'services/notifications_service.dart';
import 'services/requests_service.dart';
import 'services/resident_profile_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const TeresaRizalMobileApp());
}

class TeresaRizalMobileApp extends StatelessWidget {
  const TeresaRizalMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CitizenSessionService()),
        // seedDemoData: false — the live-demo cleanup: Dokyu/Tulong start
        // with nothing pre-submitted, so the presenter's own live
        // submissions are the first thing that ever appears there.
        // retireLegacyDemoRequestSeeds: true — also strips the nine
        // pre-existing seeded Dokyu/Tulong demo requests from any
        // browser/device that already persisted them under an earlier
        // build (see RequestsService's own doc comments on both flags).
        ChangeNotifierProvider(
          create: (_) => RequestsService(seedDemoData: false, retireLegacyDemoRequestSeeds: true),
        ),
        ChangeNotifierProvider(create: (_) => BalitaService()),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
        ChangeNotifierProvider(create: (_) => NotificationsService()),
      ],
      child: MaterialApp(
        title: 'Teresa, Rizal Mobile',
        // Checked-mode ribbon is for local review shots only. Store,
        // console, profile, and release binaries never paint it: the flag
        // is compile-time false unless a debug build also passes
        // --dart-define=TERESA_DEBUG_RIBBON=true, and kDebugMode is false
        // in profile and release.
        debugShowCheckedModeBanner:
            kDebugMode && const bool.fromEnvironment('TERESA_DEBUG_RIBBON'),
        theme: AppTheme.light,
        routes: {
          kTulongProgramRoute: (_) => const TulongProgramPlaceholder(),
          kMyReportsRoute: (_) => const MyReportsPlaceholder(),
        },
        // SplashScreen (every launch) hands off to either the first-run
        // welcome flow or straight to AuthGate — see splash_screen.dart's
        // doc comment for why every handoff uses pushReplacement rather
        // than push, which matters a great deal here: AuthGate must stay
        // the *root* route (index 0) for RootShell/RestrictedFeatureNotice's
        // `popUntil((route) => route.isFirst)` calls to keep working — see
        // AuthGate's own doc comment for the history behind that.
        home: const SplashScreen(),
      ),
    );
  }
}

/// Frontend-only auth gate: shows the citizen login flow until a mock
/// session exists, then the main app shell. Mirrors the Web Admin's own
/// pattern of gating routes on `Alpine.store('citizenSession').account`
/// rather than a real server-verified session.
///
/// Must remain the *root* route once reached (see SplashScreen/
/// OnboardingScreen, which both reach it via `pushReplacement`, never
/// `push`) — RootShell.jumpTo and RestrictedFeatureNotice's "back to
/// root" actions rely on `Navigator.popUntil((route) => route.isFirst)`
/// landing here. A previous bug (see git history around this comment)
/// came from a button pushing a *second* RootShell on top of this one
/// instead of trusting AuthGate to react to session changes on its own.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();

    if (session.loading) {
      return const Scaffold(
        backgroundColor: AppColors.navy900,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!session.isSignedIn && !session.isGuest) {
      return const LoginScreen();
    }

    return RootShell.withKey();
  }
}
