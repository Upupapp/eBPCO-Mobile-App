import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../models/inbox_channel.dart';
import '../../models/notification_kind.dart';
import '../../services/citizen_session_service.dart';
import '../../services/notification_feed.dart';
import '../../services/notifications_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/service_launcher_menu.dart';
import '../../widgets/soft_flow_scaffold.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../events/events_screen.dart';
import '../home/root_shell.dart';
import 'g5/g5_chrome.dart';
import 'g5/g5_samples.dart';

/// Inbox filter chips. Guest hides Requests.
enum _InboxFilter { all, requests, balita, events, advisories }

extension on _InboxFilter {
  String get label => switch (this) {
    _InboxFilter.all => 'All',
    _InboxFilter.requests => 'Requests',
    _InboxFilter.balita => 'Balita',
    _InboxFilter.events => 'Events',
    _InboxFilter.advisories => 'Advisories',
  };

  String get keyName => switch (this) {
    _InboxFilter.all => 'all',
    _InboxFilter.requests => 'requests',
    _InboxFilter.balita => 'balita',
    _InboxFilter.events => 'events',
    _InboxFilter.advisories => 'advisories',
  };

  InboxChannel? get channel => switch (this) {
    _InboxFilter.all => null,
    _InboxFilter.requests => InboxChannel.requests,
    _InboxFilter.balita => InboxChannel.balita,
    _InboxFilter.events => InboxChannel.events,
    _InboxFilter.advisories => InboxChannel.advisories,
  };
}

/// Push screen from the bell. No bottom nav.
///
/// [preset] paints a comp catalog (shots and empty-filter reference).
/// The bell leaves it null and shows the live sample feed.
class NotificationsScreen extends StatefulWidget {
  final G5InboxPreset? preset;

  const NotificationsScreen({super.key, this.preset});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late _InboxFilter _filter;
  final _chips = ScrollController();
  final _chipKeys = {
    for (final filter in _InboxFilter.values) filter: GlobalKey(),
  };
  late Set<String> _presetRead;
  bool _fadeLeading = false;

  @override
  void initState() {
    super.initState();
    _applyPreset(widget.preset);
    _chips.addListener(_onChipScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  @override
  void didUpdateWidget(NotificationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset == widget.preset) return;
    _applyPreset(widget.preset);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chips.hasClients) return;
      if (_chips.offset != 0) {
        _chips.jumpTo(0);
        WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
        return;
      }
      _revealSelected();
    });
  }

  @override
  void dispose() {
    _chips.removeListener(_onChipScroll);
    _chips.dispose();
    super.dispose();
  }

  void _applyPreset(G5InboxPreset? preset) {
    _filter = switch (preset) {
      G5InboxPreset.advisories => _InboxFilter.advisories,
      G5InboxPreset.emptyEvents => _InboxFilter.events,
      _ => _InboxFilter.all,
    };
    _presetRead = preset == null ? <String>{} : presetReadIds(preset);
  }

  void _onChipScroll() {
    if (!mounted || !_chips.hasClients) return;
    final leading = _chips.offset > 4;
    if (leading == _fadeLeading) return;
    setState(() => _fadeLeading = leading);
  }

  void _selectFilter(_InboxFilter filter) {
    setState(() => _filter = filter);
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealSelected());
  }

  List<_InboxFilter> _filters(bool guest) => [
    for (final filter in _InboxFilter.values)
      if (!(guest && filter == _InboxFilter.requests)) filter,
  ];

  /// Scrolls the selected chip into view. Off-screen chips are not built, so
  /// the first pass jumps toward that index and the next frame calls
  /// [Scrollable.ensureVisible].
  void _revealSelected({bool jumped = false}) {
    if (!mounted) return;
    final ctx = _chipKeys[_filter]?.currentContext;
    if (ctx == null) {
      if (jumped || !_chips.hasClients) return;
      final filters = _filters(_isGuest);
      final index = filters.indexOf(_filter);
      if (index < 0) return;
      final max = _chips.position.maxScrollExtent;
      if (max <= 0 || filters.length <= 1) return;
      _chips.jumpTo(max * index / (filters.length - 1));
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _revealSelected(jumped: true),
      );
      return;
    }
    final box = ctx.findRenderObject();
    final viewport = Scrollable.maybeOf(ctx)?.context.findRenderObject();
    if (box is! RenderBox ||
        !box.hasSize ||
        viewport is! RenderBox ||
        !viewport.hasSize) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 1,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: Duration.zero,
      );
      return;
    }
    final chipLeft = box.localToGlobal(Offset.zero, ancestor: viewport).dx;
    final chipRight = chipLeft + box.size.width;
    if (chipRight > viewport.size.width + 0.5) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 1,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: Duration.zero,
      );
    } else if (chipLeft < -0.5) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        duration: Duration.zero,
      );
    }
  }

  bool get _guest {
    if (widget.preset == G5InboxPreset.guest) return true;
    if (widget.preset != null) return false;
    return context.watch<CitizenSessionService>().account == null;
  }

  /// Same answer as [_guest] for callbacks, which must not watch.
  bool get _isGuest {
    if (widget.preset == G5InboxPreset.guest) return true;
    if (widget.preset != null) return false;
    return context.read<CitizenSessionService>().account == null;
  }

  bool _isRead(String id) {
    if (widget.preset != null) return _presetRead.contains(id);
    return context.read<NotificationsService>().isRead(id);
  }

  void _markRead(String id) {
    if (widget.preset != null) {
      setState(() => _presetRead.add(id));
      return;
    }
    context.read<NotificationsService>().markRead(id);
  }

  void _markAll(Iterable<String> ids) {
    if (widget.preset != null) {
      setState(() => _presetRead.addAll(ids));
      return;
    }
    context.read<NotificationsService>().markAllRead(ids);
  }

  List<AppNotification> _source() {
    if (widget.preset != null) {
      return g5PresetNotifications(context, widget.preset!);
    }
    return buildNotificationFeed(context);
  }

  bool _visibleToGuest(AppNotification notification) {
    if (!_guest) return true;
    if (notification.personal) return false;
    if (notification.channel == InboxChannel.requests) return false;
    return true;
  }

  bool _inFilter(AppNotification notification) {
    final channel = _filter.channel;
    if (channel == null) return true;
    return notification.channel == channel;
  }

  bool _earlier(AppNotification notification) {
    if (notification.earlier) return true;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    return notification.at.isBefore(start);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preset == null) context.watch<NotificationsService>();
    final guest = _guest;
    final pool = [
      for (final n in _source())
        if (_visibleToGuest(n)) n,
    ];
    final visible = [
      for (final n in pool)
        if (_inFilter(n)) n,
    ]..sort((a, b) => b.at.compareTo(a.at));
    final filters = _filters(guest);
    final today = [
      for (final n in visible)
        if (!_earlier(n)) n,
    ];
    final earlier = [
      for (final n in visible)
        if (_earlier(n)) n,
    ];

    int unreadIn(_InboxFilter filter) {
      final channel = filter.channel;
      return pool.where((n) {
        if (_isRead(n.id)) return false;
        if (channel == null) return true;
        return n.channel == channel;
      }).length;
    }

    final filteredUnread = visible.where((n) => !_isRead(n.id)).length;
    final meta = switch (_filter) {
      _InboxFilter.all =>
        filteredUnread == 0 ? 'All caught up' : '$filteredUnread unread',
      _ => '${_filter.label} · $filteredUnread',
    };

    return SoftFlowScaffold(
      title: 'Notifications',
      centerTitle: true,
      onBack: () => Navigator.of(context).maybePop(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (guest) _guestCard(context),
          SizedBox(
            height: 36,
            child: ShaderMask(
              shaderCallback: (rect) {
                final left = _fadeLeading;
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: left
                      ? const [SoftColors.clear, SoftColors.ink, SoftColors.ink]
                      : const [
                          SoftColors.ink,
                          SoftColors.ink,
                          SoftColors.clear,
                        ],
                  stops: left ? const [0, 0.12, 1] : const [0, 0.88, 1],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                key: const ValueKey('inbox-filters'),
                controller: _chips,
                scrollDirection: Axis.horizontal,
                primary: false,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (var i = 0; i < filters.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      KeyedSubtree(
                        key: ValueKey('inbox-filter-${filters[i].keyName}'),
                        child: _FilterChip(
                          key: _chipKeys[filters[i]],
                          label: filters[i].label,
                          count: unreadIn(filters[i]) == 0
                              ? null
                              : unreadIn(filters[i]),
                          selected: _filter == filters[i],
                          onSelected: () => _selectFilter(filters[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!guest)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  Text(meta, style: SoftType.greetingHi),
                  const Spacer(),
                  if (filteredUnread > 0)
                    GestureDetector(
                      key: const ValueKey('inbox-mark-all-read'),
                      onTap: () => _markAll(visible.map((n) => n.id)),
                      child: const Text(
                        'Mark all read',
                        style: SoftType.sectionLink,
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              key: const ValueKey('inbox-list'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                if (!guest && _filter == _InboxFilter.all)
                  const G5Honesty(
                    compact: true,
                    lead: 'Sample Teresa notifications.',
                    rest: 'Frontend preview — no live push service.',
                  ),
                if (visible.isEmpty)
                  _emptyFilter(context)
                else ...[
                  if (guest)
                    _groupLabel('PUBLIC UPDATES')
                  else if (today.isNotEmpty)
                    _groupLabel('TODAY'),
                  for (final n in (guest ? visible : today)) _tile(context, n),
                  if (!guest && earlier.isNotEmpty) ...[
                    _groupLabel('EARLIER'),
                    for (final n in earlier) _tile(context, n),
                  ],
                ],
                if (_filter == _InboxFilter.advisories &&
                    visible.isNotEmpty) ...[
                  const G5Honesty(
                    strong: true,
                    icon: Icons.shield_outlined,
                    lead: 'Sample advisories only.',
                    rest:
                        'This preview is not connected to PAGASA or MDRRMO feeds. For real emergencies call 911 and follow official Municipality of Teresa announcements.',
                  ),
                  const SizedBox(height: 12),
                  _emergencyHub(context),
                ],
                if (guest)
                  const G5Honesty(
                    lead: 'Frontend simulation.',
                    rest:
                        'Guest view shows public sample updates only — no personal data, no live push service.',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Text(
        text,
        style: SoftType.cellLabel.copyWith(
          fontWeight: FontWeight.w500,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _categoryLine(AppNotification n) {
    final raw = n.tile?.label.trim();
    if (raw != null && raw.isNotEmpty) {
      final head = raw.split('·').first.trim();
      if (head.isNotEmpty) return head;
    }
    return switch (n.channel) {
      InboxChannel.requests => 'Dokyu',
      InboxChannel.balita => 'Balita',
      InboxChannel.events => 'Event',
      InboxChannel.advisories => 'Advisory',
      null => n.kind.badgeLabel,
    };
  }

  Widget _tile(BuildContext context, AppNotification n) {
    final unread = !_isRead(n.id) && !_guest;
    final style = n.tile;
    final labelColor = style?.labelColor ?? n.kind.foreground;
    final wash = style?.wash ?? n.kind.background;
    final iconColor = style?.iconColor ?? n.kind.foreground;
    var body = n.body;
    if (_filter == _InboxFilter.advisories &&
        n.id == 'sample-typhoon-advisory') {
      body = 'Low-lying areas of Dalig and San Gabriel · sample advisory';
    }
    return Padding(
      key: ValueKey('inbox-tile-${n.id}'),
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: n.onTap == null && n.onAction == null
              ? null
              : () {
                  _markRead(n.id);
                  (n.onTap ?? n.onAction)?.call();
                },
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: SoftColors.lineSoft),
              boxShadow: SoftShadows.cardSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                G5IconDisc(icon: n.icon, wash: wash, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _categoryLine(n),
                            maxLines: 1,
                            softWrap: false,
                            style: SoftType.cellLabel.copyWith(
                              color: labelColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (style?.urgent == true) ...[
                            const SizedBox(width: 6),
                            Container(
                              constraints: const BoxConstraints(minHeight: 18),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 1,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: SoftColors.dangerSoft,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: SoftColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Urgent',
                                    style: SoftType.nav.copyWith(
                                      color: SoftColors.danger,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (n.time != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                n.time!,
                                maxLines: 1,
                                softWrap: false,
                                textAlign: TextAlign.right,
                                style: SoftType.cellLabel,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        n.title,
                        style: SoftType.cellValue.copyWith(
                          fontWeight: unread
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                      ),
                      if (body.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: SoftType.greetingHi.copyWith(height: 1.38),
                        ),
                      ],
                      if (n.actionLabel != null) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _markRead(n.id);
                            (n.onAction ?? n.onTap)?.call();
                          },
                          child: Text(
                            n.actionLabel!,
                            style: SoftType.sectionLink.copyWith(
                              color: labelColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (unread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: SoftColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _guestCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: G5Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                G5IconDisc(
                  icon: Icons.notifications_none_rounded,
                  wash: SoftColors.blueSoft,
                  color: SoftColors.blue,
                  size: 40,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sign in for personal alerts', style: SoftType.name),
                      SizedBox(height: 4),
                      Text(
                        'Request updates, corrections, and approvals need an account. Public advisories, Balita, and Events still show below.',
                        style: SoftType.greetingHi,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: G5Button(
                    label: 'Sign in',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: G5Button(
                    label: 'Create account',
                    kind: G5ButtonKind.outline,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyFilter(BuildContext context) {
    final events = _filter == _InboxFilter.events;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 48, 8, 0),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: SoftColors.blueSoft,
              shape: BoxShape.circle,
              boxShadow: SoftShadows.cardSm,
            ),
            child: Icon(
              events
                  ? Icons.calendar_today_outlined
                  : Icons.notifications_none_rounded,
              size: 30,
              color: SoftColors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            events ? 'No event notifications' : 'Nothing in this view',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.45,
              color: SoftColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            events
                ? 'When the Municipality of Teresa posts an upcoming event or reminder, it will show up here.'
                : 'No Teresa, Rizal updates match this filter.',
            textAlign: TextAlign.center,
            style: detailQuiet,
          ),
          if (events) ...[
            const SizedBox(height: 24),
            G5Button(
              key: const ValueKey('g5-browse-events'),
              label: 'Browse Events',
              onPressed: () {
                RootShell.jumpTo(context, 2);
                final nav = Navigator.of(context);
                if (nav.canPop()) {
                  nav.pop();
                  return;
                }
                nav.push(
                  MaterialPageRoute<void>(builder: (_) => const EventsScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
            G5Button(
              key: const ValueKey('g5-show-all'),
              label: 'Show all notifications',
              kind: G5ButtonKind.outline,
              onPressed: () => _selectFilter(_InboxFilter.all),
            ),
          ],
          const G5Honesty(
            lead: 'Filter only.',
            rest: 'Filters sort local samples on this device and never delete.',
          ),
        ],
      ),
    );
  }

  Widget _emergencyHub(BuildContext context) {
    return G5Card(
      key: const ValueKey('g5-emergency-hub'),
      color: SoftColors.blueWash,
      borderColor: SoftColors.line,
      shadow: const [],
      onTap: () {
        RootShell.openService(context, ServiceLauncherTarget.emergency);
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: const Row(
        children: [
          G5IconDisc(
            icon: Icons.phone_outlined,
            wash: SoftColors.dangerSoft,
            color: SoftColors.danger,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency hub', style: SoftType.bannerTitle),
                Text(
                  'Hotlines · report incident · evacuation centers',
                  style: SoftType.cellLabel,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 16, color: SoftColors.muted),
        ],
      ),
    );
  }
}

const detailQuiet = TextStyle(
  fontFamily: 'Inter',
  fontSize: 13,
  fontWeight: FontWeight.w400,
  height: 1.45,
  color: SoftColors.muted,
);

class _FilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SoftColors.blue : SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: onSelected,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: Border.all(
              color: selected ? SoftColors.blue : SoftColors.line,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: SoftType.greetingHi.copyWith(
                  color: selected ? SoftColors.white : SoftColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  height: 18,
                  constraints: const BoxConstraints(minWidth: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? SoftColors.white.withValues(alpha: 0.22)
                        : SoftColors.blueSoft,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$count',
                    style: SoftType.nav.copyWith(
                      color: selected ? SoftColors.white : SoftColors.blueDeep,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
