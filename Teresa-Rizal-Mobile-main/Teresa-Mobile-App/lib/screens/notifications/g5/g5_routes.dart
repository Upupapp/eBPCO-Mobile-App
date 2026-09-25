import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/citizen_session_service.dart';
import '../../../services/mock_catalog.dart';
import '../../balita/balita_post_detail_screen.dart';
import '../../events/event_detail_screen.dart';
import 'g5_landings.dart';
import 'g5_link.dart';

/// Notification tap → Pack E landing. Ended events open Pack C's past
/// event page. A missing target opens the stale screen. Personal links
/// while guest open the gate and resume after sign-in.
class G5Routes {
  G5Routes._();

  static void follow(
    BuildContext context,
    G5Link link, {
    String? eventId,
    String? postId,
  }) {
    switch (link) {
      case G5Link.advisory:
        _push(context, const AdvisoryDetailPage());
      case G5Link.evac:
        _push(context, const EvacUpdatePage());
      case G5Link.scholarship:
        _personal(context, const TulongApprovedPage());
      case G5Link.correction:
        _personal(context, const CorrectionFocusPage());
      case G5Link.program:
        _push(context, const TulongProgramPage());
      case G5Link.event:
        openEventById(context, eventId ?? 'evt-health-caravan');
      case G5Link.pastEvent:
        openEventById(context, eventId ?? 'evt-health-caravan-past');
      case G5Link.balita:
        BalitaPostDetailScreen.openFromNotification(
          context,
          postId ?? balitaAmbulancePostId,
        );
      case G5Link.stale:
        _push(context, const StaleDeepLinkPage());
    }
  }

  /// Ended events stay on Pack C's past-event page. Only a missing id
  /// falls through to the stale screen.
  static void openEventById(BuildContext context, String eventId) {
    for (final event in MockCatalog.events) {
      if (event.id == eventId) {
        EventDetailScreen.openFromNotification(context, event);
        return;
      }
    }
    _push(context, const StaleDeepLinkPage());
  }

  static void _personal(BuildContext context, Widget page) {
    if (_guest(context)) {
      _push(context, GuestGatePage(destination: page));
      return;
    }
    _push(context, page);
  }

  static bool _guest(BuildContext context) {
    try {
      return context.read<CitizenSessionService>().account == null;
    } catch (_) {
      return false;
    }
  }

  static void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }
}
