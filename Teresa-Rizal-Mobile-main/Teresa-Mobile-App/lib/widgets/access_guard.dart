import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/access_level.dart';
import '../services/citizen_session_service.dart';
import 'restricted_feature_notice.dart';

/// Centralized access control for a screen/tab — wrap any Dokyu/Tulong/
/// Emergency-style protected destination in this instead of re-deriving
/// "is this user allowed here" logic per screen. Compares
/// [CitizenSessionService.accessLevel] against [required] and swaps in
/// [RestrictedFeatureNotice] when it isn't met, so a Guest or unverified
/// citizen is never dropped into a broken/empty protected screen.
class AccessGuard extends StatelessWidget {
  final AccessLevel required;
  final String featureName;
  final Widget child;

  const AccessGuard({super.key, required this.required, required this.featureName, required this.child});

  @override
  Widget build(BuildContext context) {
    final level = context.watch<CitizenSessionService>().accessLevel;
    if (level.index >= required.index) return child;

    return RestrictedFeatureNotice(
      reason: level == AccessLevel.guest ? RestrictionReason.guestOnly : RestrictionReason.needsVerification,
      featureName: featureName,
    );
  }
}
