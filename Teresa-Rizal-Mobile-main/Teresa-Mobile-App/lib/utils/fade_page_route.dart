import 'package:flutter/material.dart';

/// A simple, lightweight cross-fade page transition — built entirely on
/// Flutter's own `PageRouteBuilder` (no animation package) — used for the
/// splash -> onboarding -> AuthGate handoffs so the Teresa, Rizal branding
/// feels like one continuous transition rather than an abrupt cut between
/// screens.
PageRouteBuilder<T> fadePageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
