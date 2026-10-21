import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/account_verification.dart';
import '../../domain/models.dart';
import '../../services/applications_service.dart';
import '../../services/notifications_service.dart';
import '../../services/session_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../../widgets/status_badge.dart';
import '../applications/application_detail_screen.dart';
import '../applications/my_applications_screen.dart';
import '../business/business_list_screen.dart';
import '../payments/payments_list_screen.dart';
import '../permits/permit_catalog_screen.dart';
import '../profile/account_verification_screen.dart';
import 'root_shell.dart';

/// Home — the design reference's home layout (seal and round bell on the
/// wash, initials avatar with a big greeting, a tinted callout, two stat
/// cards, a hero photo, then the active list), carrying eBPCO's real data:
/// the citizen's own applications and notifications from the live API.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ApplicationsService>().refresh());
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<ApplicationsService>().refresh(),
      context.read<NotificationsService>().refresh(),
      // The account may have been verified since sign-in.
      context.read<SessionService>().refreshProfile().catchError((_) {}),
    ]);
  }

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionService>();
    final apps = context.watch<ApplicationsService>();
    final unread = context.watch<NotificationsService>().unreadCount;
    final profile = session.profile;
    final firstName = profile?.firstName ?? '';
    final initials = [profile?.firstName, profile?.lastName].where((s) => s != null && s.isNotEmpty).map((s) => s![0]).join().toUpperCase();
    // Open applications only: a completed, withdrawn, rejected or expired one
    // is not "active" (QA TC-33, 2026-10-03).
    final active = apps.applications.where((a) => !a.isClosed).toList();
    final verification = verificationBanner(session.verification);

    return SoftWash(
      child: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 8, 20, SoftPageScaffold.navClearance(context)),
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(color: SoftColors.white, shape: BoxShape.circle, boxShadow: SoftShadows.seal),
                    child: Image.asset('assets/images/ebpco_seal.png', fit: BoxFit.contain),
                  ),
                  const SizedBox(width: 12),
                  const _Wordmark(),
                  const Spacer(),
                  SoftCircleButton(
                    icon: Icons.notifications_none_rounded,
                    tooltip: 'Notifications',
                    badge: unread,
                    onPressed: () => RootShell.jumpTo(context, 2),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SoftInitialAvatar(initials: initials.isEmpty ? '?' : initials, photo: session.photo, size: 50),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      firstName.isEmpty ? 'Welcome back.' : 'Welcome back, $firstName.',
                      style: SoftType.h1.copyWith(fontSize: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('Your permit services for Castilla, Sorsogon.', style: SoftType.body.copyWith(fontSize: 15)),
              const SizedBox(height: 18),
              if (verification != null) ...[
                _VerificationBanner(
                  title: verification.title,
                  body: verification.body,
                  action: verification.action,
                  rejected: session.verification?.isRejected ?? false,
                  onAction: () => _push(const AccountVerificationScreen()),
                ),
                const SizedBox(height: 14),
              ],
              if (apps.awaitingActionCount > 0)
                _Callout(
                  icon: Icons.priority_high_rounded,
                  title: '${apps.awaitingActionCount} application${apps.awaitingActionCount == 1 ? '' : 's'} need your action',
                  body: 'Open it to see what the reviewing office needs from you.',
                  onTap: () => RootShell.jumpTo(context, 1),
                )
              else if (unread > 0)
                _Callout(
                  icon: Icons.notifications_none_rounded,
                  title: '$unread unread notification${unread == 1 ? '' : 's'}',
                  body: 'Status updates on your applications from the Municipality.',
                  onTap: () => RootShell.jumpTo(context, 2),
                ),
              if (apps.awaitingActionCount > 0 || unread > 0) const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _StatCard(label: 'Applications', value: '${apps.applications.length}')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Needs action',
                      value: '${apps.awaitingActionCount}',
                      valueColor: apps.awaitingActionCount > 0 ? SoftColors.primary : SoftColors.verifiedInk,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(SoftRadius.lg),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset('assets/images/castilla_town_hall.jpg', fit: BoxFit.cover, alignment: const Alignment(0, -0.35)),
                ),
              ),
              const SizedBox(height: 16),
              _FeatureCard(onTap: () => _push(const PermitCatalogScreen())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _QuickAction(icon: Icons.storefront_outlined, label: 'My Businesses', onTap: () => _push(const BusinessListScreen()))),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(icon: Icons.payments_outlined, label: 'Payments', onTap: () => _push(const PaymentsListScreen()))),
                ],
              ),
              const SizedBox(height: 26),
              SoftSectionHeader(
                title: 'Active applications',
                action: 'See all',
                // "See all" means every application, not whichever filter the
                // Applications tab was last left on.
                onAction: () {
                  MyApplicationsScreen.showFilter('All');
                  RootShell.jumpTo(context, 1);
                },
              ),
              if (apps.loading && apps.applications.isEmpty)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else if (active.isEmpty)
                SoftEmptyCard(
                  // Someone whose only application is finished was told "No
                  // active applications yet", as if they had never applied
                  // (6 Oct 2026 live test).
                  apps.error != null && apps.applications.isEmpty
                      ? apps.error!
                      : apps.applications.isEmpty
                          ? 'No applications yet. Start one from Services.'
                          : 'Nothing in progress right now. Your finished applications are under See all.',
                )
              else
                ...active.take(4).map((a) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _ApplicationRow(application: a))),
            ],
          ),
        ),
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;
  const _Callout({required this.icon, required this.title, required this.body, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      color: SoftColors.pendingCream,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: SoftColors.white, borderRadius: BorderRadius.circular(SoftRadius.sm)),
            child: Icon(icon, color: SoftColors.pendingInk, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SoftType.tileTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(body, style: SoftType.body.copyWith(color: SoftColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Not verified yet (ebpco-api 067): what that means, and the way to send an ID.
class _VerificationBanner extends StatelessWidget {
  final String title;
  final String? body;
  final String? action;
  final bool rejected;
  final VoidCallback onAction;
  const _VerificationBanner({
    required this.title,
    required this.body,
    required this.action,
    required this.rejected,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final ink = rejected ? SoftColors.danger : SoftColors.pendingInk;
    return SoftCard(
      color: rejected ? SoftColors.dangerSoft : SoftColors.pendingCream,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: SoftColors.white, borderRadius: BorderRadius.circular(SoftRadius.sm)),
                child: Icon(rejected ? Icons.error_outline_rounded : Icons.badge_outlined, color: ink, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SoftType.tileTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w600)),
                    if (body != null) ...[
                      const SizedBox(height: 4),
                      Text(body!, style: SoftType.body.copyWith(color: SoftColors.muted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: 14),
            SoftPillButton(label: action!, icon: Icons.badge_outlined, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _StatCard({required this.label, required this.value, this.valueColor = SoftColors.ink});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SoftType.cellLabel.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          Text(value, style: SoftType.cellValue.copyWith(fontSize: 22, fontWeight: FontWeight.w600, color: valueColor)),
        ],
      ),
    );
  }
}

/// The reference's gradient feature card, in red.
class _FeatureCard extends StatelessWidget {
  final VoidCallback onTap;
  const _FeatureCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(SoftRadius.lg), boxShadow: SoftShadows.feature),
      child: Material(
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(gradient: SoftColors.primaryGradient),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(SoftRadius.sm)),
                    child: const Icon(Icons.add_rounded, color: SoftColors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Apply for a Permit', style: SoftType.tileTitle.copyWith(color: SoftColors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Browse permit types and start a new application', style: SoftType.tileSub.copyWith(color: const Color(0xE6FFFFFF))),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: SoftColors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          SoftIconTile(icon: icon, size: 40),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: SoftType.tileTitle.copyWith(fontSize: 15))),
        ],
      ),
    );
  }
}

class _ApplicationRow extends StatelessWidget {
  final ApplicationSummary application;
  const _ApplicationRow({required this.application});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ApplicationDetailScreen(applicationId: application.id))),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SoftIconTile(icon: Icons.description_outlined),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(application.permitType, style: SoftType.tileTitle.copyWith(fontSize: 16)),
                const SizedBox(height: 2),
                Text(application.displayReference, style: SoftType.tileSub),
                const SizedBox(height: 8),
                StatusBadge(label: application.statusLabel),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: SoftColors.chevron),
        ],
      ),
    );
  }
}

/// The app's name beside the seal: the sign-in screen's "eBPCO" lockup at
/// header size, the "e" in Castilla red, with the municipality under it in the
/// eyebrow style. Read as one label.
class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'eBPCO, Municipality of Castilla, Sorsogon',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            const TextSpan(children: [
              TextSpan(text: 'e', style: TextStyle(color: SoftColors.primary)),
              TextSpan(text: 'BPCO'),
            ]),
            style: SoftType.hero.copyWith(fontSize: 22, letterSpacing: -0.6, height: 1.0),
          ),
          const SizedBox(height: 4),
          Text(
            'CASTILLA · SORSOGON',
            style: SoftType.eyebrow.copyWith(fontSize: 10.5, letterSpacing: 1.4, height: 1.0),
          ),
        ],
      ),
    );
  }
}
