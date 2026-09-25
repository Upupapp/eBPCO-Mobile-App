import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/master_file_service.dart';
import '../services/notifications_service.dart';
import '../services/requests_service.dart';
import '../services/resident_profile_service.dart';
import '../services/sign_out.dart';
import '../screens/auth/register_screen.dart';
import '../screens/directory/directory_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/profile/digital_id_screen.dart';
import '../screens/profile/resident_profile/resident_profile_overview_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/shared/documents_uploaded_screen.dart';
import '../screens/shared/my_requests_screen.dart';
import '../screens/shared/transactions_screen.dart';
import '../screens/support/help_support_screen.dart';
import '../services/citizen_session_service.dart';
import '../theme/app_status.dart';
import '../theme/soft_widget.dart';
import 'app_dialogs.dart';
import 'soft_chrome.dart';

/// Bottom soft sheet. Guests get Sign in / Create account, then public
/// rows only. Signed-in citizens get Account, Activity, More, and a
/// danger-soft Sign out. Not a side drawer.
Future<void> showTeresaRizalMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: SoftColors.clear,
    barrierColor: SoftColors.ink.withValues(alpha: 0.55),
    builder: (_) => const TeresaRizalDrawer(),
  );
}

class TeresaRizalDrawer extends StatelessWidget {
  const TeresaRizalDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    final signedIn = session.isSignedIn;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        key: const ValueKey('menu-sheet'),
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Material(
          key: ValueKey(
            signedIn ? 'drawer-variant-signed-in' : 'drawer-variant-guest',
          ),
          color: SoftColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Handle(),
                const SizedBox(height: 14),
                if (!signedIn) ...[
                  const Text('Menu', style: SoftType.h1),
                  const SizedBox(height: 4),
                  const Text(
                    'Guest · public destinations only',
                    style: SoftType.body,
                  ),
                  const SizedBox(height: 16),
                  SoftPillButton(
                    label: 'Sign in',
                    onPressed: () => _goToAuth(context, register: false),
                  ),
                  const SizedBox(height: 10),
                  SoftPillButton(
                    label: 'Create account',
                    kind: SoftPillKind.outline,
                    onPressed: () => _goToAuth(context, register: true),
                  ),
                  const SizedBox(height: 18),
                  const _SectionLabel('Public'),
                  _MenuGroup(
                    rows: [
                      _MenuRow(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        subtitle: 'FAQ · contacts [TO BE PROVIDED]',
                        onTap: () => _push(context, const HelpSupportScreen()),
                      ),
                      _MenuRow(
                        icon: Icons.shield_outlined,
                        label: 'Privacy Policy',
                        subtitle: 'How this preview stores data',
                        onTap: () =>
                            _push(context, const PrivacyPolicyScreen()),
                      ),
                      _MenuRow(
                        icon: Icons.account_balance_outlined,
                        label: 'Government Directory',
                        subtitle: 'Municipal offices',
                        onTap: () => _push(context, const DirectoryScreen()),
                      ),
                    ],
                  ),
                ] else ...[
                  _SignedInHeader(session: session),
                  const SizedBox(height: 8),
                  const _SectionLabel('Account'),
                  _MenuGroup(
                    rows: [
                      _MenuRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Resident profile',
                        onTap: () => _push(
                          context,
                          const ResidentProfileOverviewScreen(),
                        ),
                      ),
                      _MenuRow(
                        icon: Icons.badge_outlined,
                        label: 'Digital ID',
                        subtitle: 'Mock destination · not a real ID',
                        onTap: () => _push(context, const DigitalIdScreen()),
                      ),
                      _MenuRow(
                        icon: Icons.settings_outlined,
                        label: 'Settings',
                        onTap: () => _push(context, const SettingsScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const _SectionLabel('Activity'),
                  _MenuGroup(
                    rows: [
                      _MenuRow(
                        icon: Icons.description_outlined,
                        label: 'My requests',
                        onTap: () => _push(context, const MyRequestsScreen()),
                      ),
                      _MenuRow(
                        icon: Icons.credit_card_outlined,
                        label: 'Transactions',
                        onTap: () => _push(context, const TransactionsScreen()),
                      ),
                      _MenuRow(
                        icon: Icons.folder_outlined,
                        label: 'Documents',
                        onTap: () =>
                            _push(context, const DocumentsUploadedScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const _SectionLabel('More'),
                  _MenuGroup(
                    rows: [
                      _MenuRow(
                        icon: Icons.account_balance_outlined,
                        label: 'Directory',
                        onTap: () => _push(context, const DirectoryScreen()),
                      ),
                      _MenuRow(
                        icon: Icons.help_outline_rounded,
                        label: 'Help & Support',
                        onTap: () => _push(context, const HelpSupportScreen()),
                      ),
                      _MenuRow(
                        icon: Icons.shield_outlined,
                        label: 'Privacy',
                        onTap: () =>
                            _push(context, const PrivacyPolicyScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SoftPillButton(
                    label: 'Sign out',
                    kind: SoftPillKind.dangerSoft,
                    onPressed: () => _signOut(context, session),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _goToAuth(BuildContext context, {required bool register}) async {
    Navigator.of(context).pop();
    await context.read<CitizenSessionService>().endGuestSession();
    if (!context.mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    // Pop back to the root route rather than pushing a fresh LoginScreen/
    // RegisterScreen on top of an otherwise-emptied stack. The root route
    // is _AuthGate (main.dart), which just reacted to endGuestSession()
    // above and is already showing LoginScreen on its own — the previous
    // `pushAndRemoveUntil(..., (route) => false)` removed _AuthGate from
    // the stack entirely, so any *later* login()/logout() had nothing
    // left to react to, leaving the user stuck on whatever screen was
    // showing (this was the root cause behind "Nicanor/Perlita no longer
    // opening" when reached via this Sign in / Create account path).
    nav.popUntil((route) => route.isFirst);
    if (register) {
      nav.push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    }
  }

  Future<void> _signOut(
    BuildContext context,
    CitizenSessionService session,
  ) async {
    Navigator.of(context).pop();
    final requests = context.read<RequestsService>();
    final profiles = context.read<ResidentProfileService>();
    final masterFile = context.read<MasterFileService>();
    final notifications = context.read<NotificationsService>();
    final ok = await AppDialogs.confirm(
      context,
      title: 'Sign out?',
      message:
          'Your profile, photo, requests and uploaded documents will be removed '
          'from this device. You can register or sign in again anytime.',
      confirmLabel: 'Sign Out',
      danger: true,
    );
    if (ok) {
      await SignOut.signOut(
        session,
        requests: requests,
        profiles: profiles,
        masterFile: masterFile,
        notifications: notifications,
      );
    }
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: SoftColors.line,
          borderRadius: BorderRadius.circular(SoftRadius.pill),
        ),
      ),
    );
  }
}

class _HugPill extends StatelessWidget {
  final String label;
  final SoftStatusTone tone;
  const _HugPill({required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      SoftStatusTone.guest => (SoftColors.chipWash, SoftColors.muted),
      SoftStatusTone.pending => (
        SoftColors.pendingCream,
        SoftColors.pendingInk,
      ),
      SoftStatusTone.verified => (
        SoftColors.verifiedSoft,
        SoftColors.verifiedInk,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: SoftType.cellLabel.copyWith(
              color: foreground,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: SoftType.cellLabel.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SignedInHeader extends StatelessWidget {
  final CitizenSessionService session;
  const _SignedInHeader({required this.session});

  @override
  Widget build(BuildContext context) {
    final account = session.account!;
    final status = AppStatusX.fromLabel(account.status);
    final verified =
        status == AppStatus.approved || status == AppStatus.verified;
    final tone = verified ? SoftStatusTone.verified : SoftStatusTone.pending;
    return Row(
      children: [
        SoftInitialAvatar(initials: account.initials, tone: tone, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.fullName,
                style: SoftType.h1.copyWith(fontSize: 20),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              _HugPill(label: verified ? 'Verified' : 'Unverified', tone: tone),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuRow> rows;
  const _MenuGroup({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            const Divider(height: 1, thickness: 1, color: SoftColors.line),
          rows[i],
        ],
      ],
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SoftColors.clear,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SoftColors.blueSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: SoftColors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: SoftType.name),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: SoftType.cellLabel),
                      ],
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: SoftColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
