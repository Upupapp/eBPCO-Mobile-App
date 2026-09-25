import 'package:shared_preferences/shared_preferences.dart';

import 'persistence_recovery.dart';

/// Tracks whether the citizen has ever completed (or skipped) the
/// three-screen first-run welcome flow — a one-time, device-local flag,
/// same SharedPreferences-backed pattern as [CitizenSessionService]'s own
/// persistence, not a ChangeNotifier since nothing needs to react live to
/// it: it's read exactly once at splash time and written exactly once
/// when onboarding finishes.
class OnboardingService {
  OnboardingService._();

  static const _key = 'teresa_rizal_onboarding_complete';

  /// Never throws. `getBool` is a checked cast inside `shared_preferences`, so
  /// a value of the wrong type here raises a `TypeError` — and this is awaited
  /// from `SplashScreen._run()`, which `initState` starts without awaiting. An
  /// escape there means `pushReplacement` never runs and the splash stays on
  /// screen forever, before `AuthGate` is ever reached. Same hang as the six
  /// service restore paths, reached by a different mechanism.
  ///
  /// Falling back to `false` re-shows the three-screen welcome flow. That is a
  /// small annoyance; the alternative is an app the citizen cannot open.
  static Future<bool> isComplete() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (error) {
      await PersistenceRecovery.discardUnreadable(
        service: 'OnboardingService',
        keys: const [_key],
        error: error,
      );
      return false;
    }
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
