import 'package:flutter/material.dart';

import '../../../models/app_notification.dart';
import '../../../models/inbox_channel.dart';
import '../../../models/notification_kind.dart';
import '../../../theme/soft_widget.dart';
import 'g5_link.dart';
import 'g5_routes.dart';

enum G5InboxPreset { signedIn, advisories, emptyEvents, guest }

class _Row {
  final String id;
  final String title;
  final String body;
  final String clock;
  final Duration age;
  final bool earlier;
  final bool personal;
  final bool startsRead;
  final InboxChannel channel;
  final NotificationKind kind;
  final IconData icon;
  final InboxTileStyle tile;
  final G5Link link;
  final String? eventId;
  final String? postId;

  const _Row({
    required this.id,
    required this.title,
    required this.body,
    required this.clock,
    required this.age,
    required this.channel,
    required this.kind,
    required this.icon,
    required this.tile,
    required this.link,
    this.earlier = false,
    this.personal = false,
    this.startsRead = false,
    this.eventId,
    this.postId,
  });
}

const _danger = InboxTileStyle(
  label: 'Advisory',
  labelColor: SoftColors.danger,
  iconColor: SoftColors.danger,
  wash: SoftColors.dangerSoft,
  urgent: true,
);

const _evac = InboxTileStyle(
  label: 'Advisory',
  labelColor: SoftColors.danger,
  iconColor: SoftColors.danger,
  wash: SoftColors.dangerSoft,
);

const _tulong = InboxTileStyle(
  label: 'Tulong',
  labelColor: SoftColors.tulongInk,
  iconColor: SoftColors.tulongInk,
  wash: SoftColors.tulongSoft,
);

const _dokyu = InboxTileStyle(
  label: 'Dokyu',
  labelColor: SoftColors.blue,
  iconColor: SoftColors.endedInk,
  wash: SoftColors.endedWash,
);

const _program = InboxTileStyle(
  label: 'Balita',
  labelColor: SoftColors.tulongInk,
  iconColor: SoftColors.tulongInk,
  wash: SoftColors.tulongSoft,
);

const _balita = InboxTileStyle(
  label: 'Balita',
  labelColor: SoftColors.blue,
  iconColor: SoftColors.blue,
  wash: SoftColors.blueSoft,
);

const _event = InboxTileStyle(
  label: 'Event',
  labelColor: SoftColors.cyan,
  iconColor: SoftColors.cyan,
  wash: SoftColors.eventHeroStart,
);

const _lifted = InboxTileStyle(
  label: 'Advisory',
  labelColor: SoftColors.muted,
  iconColor: SoftColors.muted,
  wash: SoftColors.chipWash,
  muted: true,
);

/// Comp catalog for the signed-in All / Advisories frames.
const g5SignedInRows = <_Row>[
  _Row(
    id: 'sample-typhoon-advisory',
    title: 'Heavy rain & flood advisory',
    body: 'Dalig · San Gabriel · sample advisory',
    clock: '8:10 AM',
    age: Duration(minutes: 50),
    channel: InboxChannel.advisories,
    kind: NotificationKind.urgent,
    icon: Icons.thunderstorm_outlined,
    tile: _danger,
    link: G5Link.advisory,
  ),
  _Row(
    id: 'sample-educational-assistance',
    title: 'Scholarship approved',
    body: 'TR-TUL-0917 · see claim steps',
    clock: '7:45 AM',
    age: Duration(minutes: 70),
    channel: InboxChannel.requests,
    kind: NotificationKind.success,
    icon: Icons.school_outlined,
    tile: _tulong,
    link: G5Link.scholarship,
    personal: true,
  ),
  _Row(
    id: 'sample-correction-clearance',
    title: 'Barangay clearance needs correction',
    body: 'Valid ID was flagged. Replace it to continue.',
    clock: '7:02 AM',
    age: Duration(minutes: 90),
    channel: InboxChannel.requests,
    kind: NotificationKind.actionRequired,
    icon: Icons.description_outlined,
    tile: _dokyu,
    link: G5Link.correction,
    personal: true,
  ),
  _Row(
    id: 'sample-evacuation-update',
    title: 'Teresa Municipal Gym is open',
    body: 'Evacuation center update · Poblacion',
    clock: '6:30 AM',
    age: Duration(minutes: 110),
    channel: InboxChannel.advisories,
    kind: NotificationKind.info,
    icon: Icons.home_outlined,
    tile: _evac,
    link: G5Link.evac,
  ),
  _Row(
    id: 'sample-new-assistance-program',
    title: 'Educational Assistance now open',
    body: 'For SHS & college students of Teresa',
    clock: 'Sep 24',
    age: Duration(days: 1, hours: 2),
    earlier: true,
    channel: InboxChannel.balita,
    kind: NotificationKind.info,
    icon: Icons.favorite_border_rounded,
    tile: _program,
    link: G5Link.program,
  ),
  _Row(
    id: 'sample-balita-ambulance',
    title: 'New LGU Teresa ambulance for residents',
    body: '',
    clock: 'Sep 22',
    age: Duration(days: 2),
    earlier: true,
    startsRead: true,
    channel: InboxChannel.balita,
    kind: NotificationKind.info,
    icon: Icons.notes_rounded,
    tile: _balita,
    link: G5Link.balita,
    postId: 'bal-ambulance',
  ),
  _Row(
    id: 'sample-event-health-caravan',
    title: 'Health Caravan this Sunday',
    body: '',
    clock: 'Sep 21',
    age: Duration(days: 3),
    earlier: true,
    startsRead: true,
    channel: InboxChannel.events,
    kind: NotificationKind.info,
    icon: Icons.calendar_today_outlined,
    tile: _event,
    link: G5Link.event,
    eventId: 'evt-health-caravan',
  ),
  _Row(
    id: 'sample-advisory-lifted',
    title: 'Road clearing advisory, Barangay May-Iba — lifted',
    body: 'Sample advisory · no action needed',
    clock: 'Sep 19',
    age: Duration(days: 5),
    earlier: true,
    startsRead: true,
    channel: InboxChannel.advisories,
    kind: NotificationKind.info,
    icon: Icons.warning_amber_rounded,
    tile: _lifted,
    link: G5Link.advisory,
  ),
];

/// Live bell adds the ended-event and removed-post rows so those routes
/// are tappable. Preset frames omit them so the comp fold stays put.
const g5ExtraRows = <_Row>[
  _Row(
    id: 'sample-event-ended',
    title: 'Health Caravan has ended',
    body: 'Opens the past-event page · Municipal Hall',
    clock: 'Aug 10',
    age: Duration(days: 6),
    earlier: true,
    channel: InboxChannel.events,
    kind: NotificationKind.info,
    icon: Icons.event_busy_outlined,
    tile: _event,
    link: G5Link.pastEvent,
    eventId: 'evt-health-caravan-past',
  ),
  _Row(
    id: 'sample-balita-removed',
    title: 'Road repair schedule, Barangay Prinza',
    body: 'This update is no longer available',
    clock: 'Sep 12',
    age: Duration(days: 12),
    earlier: true,
    channel: InboxChannel.balita,
    kind: NotificationKind.info,
    icon: Icons.notes_rounded,
    tile: _balita,
    link: G5Link.stale,
  ),
];

const g5EmptyRows = <_Row>[
  _Row(
    id: 'sample-educational-assistance',
    title: 'Scholarship approved',
    body: 'TR-TUL-0917 · see claim steps',
    clock: '7:45 AM',
    age: Duration(minutes: 70),
    channel: InboxChannel.requests,
    kind: NotificationKind.success,
    icon: Icons.school_outlined,
    tile: _tulong,
    link: G5Link.scholarship,
    personal: true,
  ),
  _Row(
    id: 'sample-typhoon-advisory',
    title: 'Heavy rain & flood advisory',
    body: 'Dalig · San Gabriel · sample advisory',
    clock: '8:10 AM',
    age: Duration(minutes: 50),
    channel: InboxChannel.advisories,
    kind: NotificationKind.urgent,
    icon: Icons.thunderstorm_outlined,
    tile: _danger,
    link: G5Link.advisory,
  ),
  _Row(
    id: 'sample-evacuation-update',
    title: 'Teresa Municipal Gym is open',
    body: 'Evacuation center update · Poblacion',
    clock: '6:30 AM',
    age: Duration(minutes: 110),
    channel: InboxChannel.advisories,
    kind: NotificationKind.info,
    icon: Icons.home_outlined,
    tile: _evac,
    link: G5Link.evac,
  ),
];

const g5GuestRows = <_Row>[
  _Row(
    id: 'sample-typhoon-advisory',
    title: 'Heavy rain & flood advisory',
    body: 'Sample advisory · open to everyone',
    clock: '8:10 AM',
    age: Duration(minutes: 10),
    channel: InboxChannel.advisories,
    kind: NotificationKind.urgent,
    icon: Icons.thunderstorm_outlined,
    tile: _danger,
    link: G5Link.advisory,
  ),
  _Row(
    id: 'sample-evacuation-update',
    title: 'Teresa Municipal Gym is open',
    body: '',
    clock: '6:30 AM',
    age: Duration(minutes: 40),
    channel: InboxChannel.advisories,
    kind: NotificationKind.info,
    icon: Icons.home_outlined,
    tile: _evac,
    link: G5Link.evac,
  ),
  _Row(
    id: 'sample-balita-ambulance',
    title: 'New LGU Teresa ambulance for residents',
    body: '',
    clock: 'Sep 22',
    age: Duration(days: 2),
    earlier: true,
    startsRead: true,
    channel: InboxChannel.balita,
    kind: NotificationKind.info,
    icon: Icons.notes_rounded,
    tile: _balita,
    link: G5Link.balita,
    postId: 'bal-ambulance',
  ),
  _Row(
    id: 'sample-event-health-caravan',
    title: 'Health Caravan this Sunday',
    body: '',
    clock: 'Sep 21',
    age: Duration(days: 3),
    earlier: true,
    startsRead: true,
    channel: InboxChannel.events,
    kind: NotificationKind.info,
    icon: Icons.calendar_today_outlined,
    tile: _event,
    link: G5Link.event,
    eventId: 'evt-health-caravan',
  ),
];

List<_Row> _rowsFor(G5InboxPreset? preset) {
  return switch (preset) {
    G5InboxPreset.emptyEvents => g5EmptyRows,
    G5InboxPreset.guest => g5GuestRows,
    G5InboxPreset.signedIn || G5InboxPreset.advisories => g5SignedInRows,
    null => [...g5SignedInRows, ...g5ExtraRows],
  };
}

AppNotification _notificationFor(BuildContext context, _Row row) {
  return AppNotification(
    id: row.id,
    kind: row.kind,
    icon: row.icon,
    title: row.title,
    body: row.body,
    time: row.clock,
    at: DateTime.now().subtract(row.age),
    channel: row.channel,
    tile: row.tile,
    earlier: row.earlier,
    personal: row.personal,
    onTap: () => G5Routes.follow(
      context,
      row.link,
      eventId: row.eventId,
      postId: row.postId,
    ),
  );
}

List<AppNotification> g5PresetNotifications(
  BuildContext context,
  G5InboxPreset preset,
) {
  return [for (final row in _rowsFor(preset)) _notificationFor(context, row)];
}

List<AppNotification> g5LiveSamples(BuildContext context) {
  return [for (final row in _rowsFor(null)) _notificationFor(context, row)];
}

Set<String> presetReadIds(G5InboxPreset preset) {
  final rows = _rowsFor(preset);
  return {
    for (final row in rows)
      if (row.startsRead) row.id,
  };
}
