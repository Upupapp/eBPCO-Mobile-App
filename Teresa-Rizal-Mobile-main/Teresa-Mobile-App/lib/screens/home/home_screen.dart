import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/announcement.dart';
import '../../models/citizen_account.dart';
import '../../models/request_milestones.dart';
import '../../models/service_request.dart';
import '../../services/citizen_session_service.dart';
import '../../services/mock_catalog.dart';
import '../../services/notification_feed.dart';
import '../../services/notifications_service.dart';
import '../../services/requests_service.dart';
import '../../theme/app_status.dart';
import '../../theme/soft_widget.dart';
import '../../utils/teresa_rizal_seal.dart';
import '../../widgets/home_banner_carousel.dart';
import '../../widgets/home_welcome_banner.dart';
import '../../widgets/soft_chrome.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../notifications/notifications_screen.dart';
import '../shared/event_poster_viewer.dart';
import 'root_shell.dart';

/// Soft-widget home. Greeting, municipal seal, membership cells, the home
/// banner carousel, the active-request gradient, and one upcoming event.
/// Dokyu and Tulong shortcuts open the Services sheet. Access checks
/// stay in [RootShell.openService].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollController = ScrollController();
  bool _bannerOffered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_bannerOffered && mounted) {
        _bannerOffered = true;
        HomeWelcomeBanner.show(context);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    final account = session.account;
    final requests = context.watch<RequestsService>();
    final signedInId = account?.id;
    final owned = signedInId == null
        ? const <ServiceRequest>[]
        : requests.all.where((r) => r.applicantId == signedInId);
    final activeRequests =
        owned.where((r) => !AppStatusX.fromLabel(r.status).isDone).toList()
          ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    final verified = account != null && _isVerifiedAccount(account);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final unread = _unreadCount(context);

    return SoftWash(
      child: Scaffold(
        backgroundColor: SoftColors.clear,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async =>
                Future.delayed(const Duration(milliseconds: 500)),
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
              children: [
                const _HomeTopBar(),
                const SizedBox(height: 16),
                _GreetingLine(account: account),
                const SizedBox(height: 6),
                Text(_homeLede(account), style: SoftType.body),
                const SizedBox(height: 16),
                if (account == null)
                  const _GuestBrowsingCard()
                else ...[
                  if (unread > 0)
                    _UnreadNotice(count: unread)
                  else if (!verified)
                    _UnverifiedNotice(
                      statusLabel: AppStatusX.fromLabel(account.status).label,
                    ),
                ],
                const SizedBox(height: 12),
                _StatusRow(account: account),
                const SizedBox(height: 16),
                const HomeBannerCarousel(),
                const SizedBox(height: 18),
                if (account == null) ...[
                  _FromBalita(),
                  const SizedBox(height: 18),
                ] else ...[
                  _SectionRow(
                    title: 'Active requests',
                    action: 'See all',
                    onAction: () => RootShell.showServices(context),
                  ),
                  activeRequests.isEmpty
                      ? _QuietNote(_emptyRequestsCopy(account))
                      : _ActiveRequestCard(requests: activeRequests),
                  const SizedBox(height: 18),
                ],
                if (MockCatalog.events.isNotEmpty)
                  _UpcomingEvent(event: MockCatalog.events.first),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

bool _isVerifiedAccount(CitizenAccount account) {
  final status = AppStatusX.fromLabel(account.status);
  return status == AppStatus.approved || status == AppStatus.verified;
}

int _unreadCount(BuildContext context) {
  final feed = buildNotificationFeed(context);
  final service = context.watch<NotificationsService>();
  return feed.where((n) => !service.isRead(n.id)).length;
}

String _homeLede(CitizenAccount? account) {
  if (account == null) {
    return 'Browse public news and events for Teresa, Rizal.';
  }
  return 'Your citizen services for Teresa, Rizal.';
}

String _emptyRequestsCopy(CitizenAccount? account) {
  if (account == null) {
    return 'No requests on a guest visit. Dokyu and Tulong open after you sign in and Teresa, Rizal verifies the account.';
  }
  if (!_isVerifiedAccount(account)) {
    return 'No requests on this account. Dokyu and Tulong open after Teresa, Rizal verifies you. Emergency stays available.';
  }
  return 'No active requests yet. Start one from Services.';
}

/// Top row, left to right: official seal, flexible space, search,
/// notifications. The profile avatar is not on this row.
class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _OfficialSeal(),
        const Spacer(),
        SoftCircleButton(
          icon: Icons.search_rounded,
          tooltip: 'Search',
          tapTarget: 48,
          onPressed: () => _openSearch(context),
        ),
        const SizedBox(width: 4),
        const AlertsAction(color: SoftColors.ink, tapTarget: 48),
      ],
    );
  }
}

/// H1 row: avatar immediately before the greeting.
/// One measured line sits bottom-aligned with that line. Two or more lines
/// center the avatar on the whole greeting block.
class _GreetingLine extends StatelessWidget {
  final CitizenAccount? account;
  const _GreetingLine({required this.account});

  static const double _avatarSize = 42;
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final citizen = account;
    final greeting = citizen == null
        ? 'Welcome, Guest.'
        : 'Magandang araw, ${citizen.firstName}.';
    final style = SoftType.h1;
    final tone = citizen == null
        ? SoftStatusTone.guest
        : _isVerifiedAccount(citizen)
        ? SoftStatusTone.verified
        : SoftStatusTone.pending;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textMaxWidth = constraints.maxWidth.isFinite
            ? (constraints.maxWidth - _avatarSize - _gap).clamp(
                0.0,
                double.infinity,
              )
            : double.infinity;
        final painter = TextPainter(
          text: TextSpan(text: greeting, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: textMaxWidth);
        final lineCount = painter.computeLineMetrics().length;
        painter.dispose();
        final oneLine = lineCount <= 1;

        return Row(
          key: ValueKey(
            oneLine ? 'home-greeting-align-end' : 'home-greeting-align-center',
          ),
          crossAxisAlignment: oneLine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.center,
          children: [
            Tooltip(
              message: 'Menu',
              child: Material(
                color: SoftColors.clear,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => RootShell.openDrawer(context),
                  child: SoftInitialAvatar(
                    key: const ValueKey('home-greeting-avatar'),
                    initials: citizen?.initials ?? 'G',
                    tone: tone,
                    size: _avatarSize,
                  ),
                ),
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: Text(
                greeting,
                key: const ValueKey('home-greeting-text'),
                style: style,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OfficialSeal extends StatelessWidget {
  const _OfficialSeal();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('home-brand-seal'),
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: SoftColors.white,
        boxShadow: SoftShadows.seal,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        teresaRizalSealAsset,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}

void _openSearch(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: SoftColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(SoftRadius.lg)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            const Text('Search', style: SoftType.section),
            const SizedBox(height: 8),
            const Text(
              'Services and upcoming events in Teresa, Rizal.',
              style: SoftType.body,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Services', style: SoftType.name),
              subtitle: const Text(
                'Dokyu, Tulong, and Emergency',
                style: SoftType.cellLabel,
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                RootShell.showServices(context);
              },
            ),
            for (final event in MockCatalog.events)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SoftType.name,
                ),
                subtitle: Text(event.date, style: SoftType.cellLabel),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  RootShell.jumpTo(context, 2);
                },
              ),
          ],
        ),
      );
    },
  );
}

class _StatusRow extends StatelessWidget {
  final CitizenAccount? account;
  const _StatusRow({required this.account});

  @override
  Widget build(BuildContext context) {
    final account = this.account;
    final (label, color) = _status(account);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Cell(
              label: 'Account status',
              value: Text(
                label,
                style: SoftType.cellValue.copyWith(color: color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: account == null
                ? _Cell(
                    label: 'Resident ID',
                    value: Text('—', style: SoftType.cellValue),
                  )
                : _Cell(
                    label: 'Barangay',
                    value: Text(account.barangay, style: SoftType.cellValue),
                  ),
          ),
        ],
      ),
    );
  }

  (String, Color) _status(CitizenAccount? account) {
    if (account == null) return ('Guest', SoftColors.ink);
    if (_isVerifiedAccount(account)) {
      return ('Verified', SoftColors.verifiedInk);
    }
    return ('Unverified', SoftColors.pendingInk);
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final Widget value;
  const _Cell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        border: Border.all(color: SoftColors.line),
        boxShadow: SoftShadows.cardSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SoftType.cellLabel),
          const SizedBox(height: 6),
          value,
        ],
      ),
    );
  }
}

class _UnverifiedNotice extends StatelessWidget {
  final String statusLabel;
  const _UnverifiedNotice({required this.statusLabel});

  @override
  Widget build(BuildContext context) {
    final title = _sentence(statusLabel);
    return Container(
      key: const ValueKey('home-unverified-notice'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoftColors.pendingCream,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SoftColors.white,
                  borderRadius: BorderRadius.circular(SoftRadius.sm),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: SoftColors.pendingInk,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style: SoftType.name.copyWith(fontWeight: FontWeight.w600),
                    children: [
                      TextSpan(text: title),
                      const TextSpan(text: '  ·  '),
                      const TextSpan(
                        text: 'Unverified',
                        style: TextStyle(color: SoftColors.pendingInk),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Home, Balita, and Events are open. Emergency is available. Dokyu and Tulong stay locked until Approved.',
            style: SoftType.body,
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AccessChip('Home', open: true),
              _AccessChip('Balita', open: true),
              _AccessChip('Events', open: true),
              _AccessChip('Emergency', open: true),
              _AccessChip('Dokyu locked', open: false),
              _AccessChip('Tulong locked', open: false),
            ],
          ),
          const SizedBox(height: 14),
          SoftPillButton(
            label: 'Continue verification',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
          ),
          const SizedBox(height: 10),
          const Text(
            'Frontend simulation — no real LGU officer is reviewing this account.',
            style: SoftType.cellLabel,
          ),
        ],
      ),
    );
  }
}

String _sentence(String label) {
  if (label.isEmpty) return label;
  return label[0] + label.substring(1).toLowerCase();
}

class _AccessChip extends StatelessWidget {
  final String label;
  final bool open;
  const _AccessChip(this.label, {required this.open});

  @override
  Widget build(BuildContext context) {
    final background = open ? SoftColors.verifiedSoft : SoftColors.chipWash;
    final foreground = open ? SoftColors.verifiedInk : SoftColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
      ),
      child: Text(
        label,
        style: SoftType.cellLabel.copyWith(
          color: foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _UnreadNotice extends StatelessWidget {
  final int count;
  const _UnreadNotice({required this.count});

  @override
  Widget build(BuildContext context) {
    final title = count == 1
        ? '1 unread notification'
        : '$count unread notifications';
    return Material(
      color: SoftColors.clear,
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        child: Ink(
          key: const ValueKey('home-unread-card'),
          decoration: BoxDecoration(
            color: SoftColors.pendingCream,
            borderRadius: BorderRadius.circular(SoftRadius.lg),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SoftColors.white,
                  borderRadius: BorderRadius.circular(SoftRadius.sm),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 18,
                  color: SoftColors.pendingInk,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SoftType.name.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bell badge proves G1 unread chrome. Sample alerts stay local in this preview.',
                      style: SoftType.body,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestBrowsingCard extends StatelessWidget {
  const _GuestBrowsingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('home-guest-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoftColors.blueWash,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Browsing as Guest', style: SoftType.name),
          const SizedBox(height: 6),
          const Text(
            'You can read Balita and Events. Create an account to request Dokyu or Tulong, and to like or comment.',
            style: SoftType.body,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SoftPillButton(
                  label: 'Create account',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SoftPillButton(
                  label: 'Sign in',
                  kind: SoftPillKind.outline,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Frontend simulation — Guest is local preview state, not a live LGU session.',
            style: SoftType.cellLabel,
          ),
        ],
      ),
    );
  }
}

class _FromBalita extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final post = MockCatalog.announcements.isEmpty
        ? null
        : MockCatalog.announcements.first;
    final title = post == null
        ? 'Municipal news'
        : post.body.split('\n').first.trim();
    return Column(
      children: [
        _SectionRow(
          title: 'From Balita',
          action: 'See all',
          onAction: () => RootShell.jumpTo(context, 1),
        ),
        Material(
          color: SoftColors.clear,
          child: InkWell(
            borderRadius: BorderRadius.circular(SoftRadius.lg),
            onTap: () => RootShell.jumpTo(context, 1),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SoftColors.white,
                borderRadius: BorderRadius.circular(SoftRadius.lg),
                border: Border.all(color: SoftColors.lineSoft),
                boxShadow: SoftShadows.cardSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post == null
                        ? 'Teresa, Rizal'
                        : '${post.author} · ${post.time}',
                    style: SoftType.cellLabel.copyWith(color: SoftColors.blue),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SoftType.name.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  final String title;
  final String? action;
  final String? trailing;
  final VoidCallback? onAction;
  const _SectionRow({
    required this.title,
    this.action,
    this.trailing,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: SoftType.section)),
          if (trailing != null)
            GestureDetector(
              onTap: onAction,
              child: Text(trailing!, style: SoftType.sectionLink),
            ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: SoftType.sectionLink),
            ),
        ],
      ),
    );
  }
}

class _QuietNote extends StatelessWidget {
  final String text;
  const _QuietNote(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoftColors.blueSoft,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
      ),
      child: Text(text, style: SoftType.body),
    );
  }
}

class _ActiveRequestCard extends StatelessWidget {
  final List<ServiceRequest> requests;
  const _ActiveRequestCard({required this.requests});

  @override
  Widget build(BuildContext context) {
    final top = requests.first;
    final fraction = _fraction(top.status);
    return Material(
      color: SoftColors.clear,
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        onTap: () => RootShell.showServices(context),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.lg),
            gradient: SoftColors.featureGradient,
            boxShadow: SoftShadows.feature,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: SoftColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${requests.length}',
                    style: SoftType.greetingName.copyWith(
                      color: SoftColors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${top.category.label} · ${top.status}',
                        style: SoftType.onFeatureEyebrow,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        top.typeName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SoftType.onFeatureTitle,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                SoftRadius.pill,
                              ),
                              child: SizedBox(
                                height: 4,
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  backgroundColor: SoftColors.progressTrack,
                                  color: SoftColors.gold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(top.status, style: SoftType.progressLabel),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _fraction(String status) {
    final index = RequestMilestones.sequence.indexOf(status);
    if (index >= 0) return (index + 1) / RequestMilestones.sequence.length;
    if (status == RequestMilestones.underReview) {
      return 2 / RequestMilestones.sequence.length;
    }
    return 0.2;
  }
}

class _UpcomingEvent extends StatelessWidget {
  final EventItem event;
  const _UpcomingEvent({required this.event});

  @override
  Widget build(BuildContext context) {
    final chip = [
      event.venue,
      event.category,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return Column(
      children: [
        _SectionRow(
          title: 'Upcoming event',
          trailing: event.date,
          onAction: () => RootShell.jumpTo(context, 2),
        ),
        Material(
          color: SoftColors.clear,
          child: InkWell(
            borderRadius: BorderRadius.circular(SoftRadius.lg),
            onTap: event.imagePath == null
                ? null
                : () => EventPosterViewer.open(context, event),
            child: Ink(
              decoration: BoxDecoration(
                color: SoftColors.white,
                borderRadius: BorderRadius.circular(SoftRadius.lg),
                border: Border.all(color: SoftColors.lineSoft),
                boxShadow: SoftShadows.cardSm,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(SoftRadius.md),
                        gradient: SoftColors.eventHeroGradient,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: SoftColors.white,
                            borderRadius: BorderRadius.circular(
                              SoftRadius.pill,
                            ),
                          ),
                          child: Text(
                            chip,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SoftType.cellLabel.copyWith(
                              color: SoftColors.blue,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SoftType.name,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${event.time} · ${event.venue}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SoftType.body,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
