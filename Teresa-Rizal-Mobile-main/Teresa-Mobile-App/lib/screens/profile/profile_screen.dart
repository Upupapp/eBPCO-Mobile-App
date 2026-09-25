import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../../models/citizen_account.dart';
import '../../services/citizen_session_service.dart';
import '../../services/master_file_service.dart';
import '../../services/notifications_service.dart';
import '../../services/requests_service.dart';
import '../../services/resident_profile_service.dart';
import '../../services/sign_out.dart';
import '../../theme/app_status.dart';
import '../../theme/soft_widget.dart';
import '../../utils/demo_resident_photo.dart';
import '../../utils/teresa_rizal_seal.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialogs.dart';
import '../../widgets/digital_id_honesty.dart';
import '../../widgets/guest_sign_in_gate.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/verification_status_panel.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../home/root_shell.dart';
import '../shared/documents_uploaded_screen.dart';
import '../shared/my_requests_screen.dart';
import '../shared/transactions_screen.dart';
import 'digital_id_screen.dart';
import 'g6/resident_id.dart';
import 'resident_profile/resident_profile_overview_screen.dart';
import 'settings_screen.dart';

/// Soft profile hub. Identity, an honest status pill, barangay and the
/// resident id from [ResidentId] (the same constant the Digital ID card
/// uses), then Account and Activity. Family membership stays on Resident
/// profile, not a hub row.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CitizenSessionService>();
    final account = session.account;
    final personal = account == null
        ? null
        : context.watch<ResidentProfileService>().profileFor(account).personal;
    final photo = profileImageFor(account, personal);
    final canPop = Navigator.of(context).canPop();
    final status = account == null
        ? null
        : AppStatusX.fromLabel(account.status);
    final verified =
        status == AppStatus.approved || status == AppStatus.verified;

    return SoftWash(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SoftCircleButton(
                icon: canPop ? Icons.arrow_back_rounded : Icons.menu_rounded,
                tooltip: canPop ? 'Back' : 'Menu',
                onPressed: () {
                  if (canPop) {
                    Navigator.of(context).maybePop();
                  } else {
                    RootShell.openDrawer(context);
                  }
                },
              ),
            ),
          ),
          title: const Text('Profile', style: SoftType.pageTitle),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: AlertsAction()),
            ),
          ],
        ),
        body: ListView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(2400),
          padding: EdgeInsets.fromLTRB(
            16,
            4,
            16,
            16 + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _Identity(
              account: account,
              photo: photo,
              verified: verified,
              status: status,
            ),
            if (account == null) ...[
              const SizedBox(height: 12),
              const _GuestActions(),
            ],
            const SizedBox(height: 12),
            _Membership(account: account),
            if (account != null) ...[
              const SizedBox(height: 10),
              const _SealBrandRow(),
            ],
            if (status == AppStatus.rejected || status == AppStatus.draft) ...[
              const SizedBox(height: 12),
              VerificationStatusPanel(
                status: status!,
                onAction: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
              ),
            ],
            const SizedBox(height: 16),
            const _SectionLabel('Account'),
            _HubCard(
              children: [
                _HubRow(
                  icon: Icons.person_outline_rounded,
                  label: 'Resident profile',
                  subtitle: 'Personal, family, household',
                  onTap: () => _openResidentProfile(context, account),
                ),
                _HubRow(
                  icon: Icons.badge_outlined,
                  label: 'Digital ID',
                  subtitle: 'Not a real government ID system',
                  onTap: () => _openDigitalId(context, account),
                ),
                _HubRow(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  subtitle: 'Notifications & preferences',
                  onTap: () => _push(context, const SettingsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _SectionLabel('Activity'),
            _HubCard(
              children: [
                _HubRow(
                  icon: Icons.assignment_outlined,
                  label: 'My requests',
                  subtitle: 'Dokyu, Tulong, incidents',
                  onTap: () => _push(context, const MyRequestsScreen()),
                ),
                _HubRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'Transactions',
                  subtitle: 'Demo payments',
                  onTap: () => _push(context, const TransactionsScreen()),
                ),
                _HubRow(
                  icon: Icons.folder_open_outlined,
                  label: 'Documents',
                  subtitle: 'Uploaded on this device',
                  onTap: () => _push(context, const DocumentsUploadedScreen()),
                ),
              ],
            ),
            if (account != null) ...[
              const SizedBox(height: 12),
              _HubCard(
                children: [
                  _HubRow(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    danger: true,
                    showChevron: false,
                    onTap: () => _signOut(context, session),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            DigitalIdHonestyPanel(
              onOpenDemonstration: () => _openDigitalId(context, account),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openResidentProfile(BuildContext context, CitizenAccount? account) {
    if (account == null) {
      showGuestSignInGate(context, 'Resident profile');
      return;
    }
    _push(context, const ResidentProfileOverviewScreen());
  }

  void _openDigitalId(BuildContext context, CitizenAccount? account) {
    if (account == null) {
      showGuestSignInGate(context, 'Digital ID');
      return;
    }
    _push(context, const DigitalIdScreen());
  }

  Future<void> _signOut(
    BuildContext context,
    CitizenSessionService session,
  ) async {
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

class _Identity extends StatelessWidget {
  final CitizenAccount? account;
  final ImageProvider? photo;
  final bool verified;
  final AppStatus? status;

  const _Identity({
    required this.account,
    required this.photo,
    required this.verified,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final account = this.account;
    final signedIn = account != null;
    final (label, tone) = _pill(signedIn);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(signedIn: signedIn, account: account, photo: photo),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                signedIn ? account.fullName : 'Guest',
                style: SoftType.h1.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: SoftStatusPill(
                  key: const ValueKey('profile-status-pill'),
                  label: label,
                  tone: tone,
                  expand: false,
                ),
              ),
              if (account != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Account details ${account.profileCompleteness}% complete',
                  style: SoftType.cellLabel,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  (String, SoftStatusTone) _pill(bool signedIn) {
    if (!signedIn) return ('Guest', SoftStatusTone.guest);
    if (verified) return ('Verified', SoftStatusTone.verified);
    return (status!.label, SoftStatusTone.pending);
  }
}

class _Avatar extends StatelessWidget {
  final bool signedIn;
  final CitizenAccount? account;
  final ImageProvider? photo;

  const _Avatar({
    required this.signedIn,
    required this.account,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return CircleAvatar(
        radius: 21,
        backgroundColor: SoftColors.blueSoft,
        backgroundImage: photo,
      );
    }
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: signedIn ? null : SoftColors.blueSoft,
        gradient: signedIn ? SoftColors.avatarGradient : null,
        boxShadow: signedIn ? SoftShadows.avatar : SoftShadows.cardSm,
        border: signedIn ? null : Border.all(color: SoftColors.line),
      ),
      child: signedIn
          ? Text(
              account!.initials,
              style: SoftType.cellValue.copyWith(
                color: SoftColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            )
          : const Icon(Icons.person_rounded, color: SoftColors.blue, size: 20),
    );
  }
}

/// Signed-in brand row. Guest does not carry the municipal seal.
class _SealBrandRow extends StatelessWidget {
  const _SealBrandRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('profile-brand-row'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: SoftColors.lineSoft),
        boxShadow: SoftShadows.cardSm,
      ),
      child: Row(
        children: [
          Container(
            key: const ValueKey('profile-brand-seal'),
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
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Municipal Government of Teresa',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.13,
                    color: SoftColors.ink,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Official LGU seal · Rizal Province',
                  style: SoftType.cellLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Membership extends StatelessWidget {
  final CitizenAccount? account;
  const _Membership({required this.account});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Cell(
              label: 'Barangay',
              value: account?.barangay ?? '—',
              valueKey: const ValueKey('profile-barangay'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Cell(
              label: 'Resident ID',
              value: ResidentId.displayFor(account),
              valueKey: const ValueKey('profile-resident-id'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String label;
  final String value;
  final Key valueKey;
  const _Cell({
    required this.label,
    required this.value,
    required this.valueKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
          const SizedBox(height: 2),
          Text(value, key: valueKey, style: SoftType.cellValue),
        ],
      ),
    );
  }
}

class _GuestActions extends StatelessWidget {
  const _GuestActions();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppButton(
          label: 'Sign In',
          fullWidth: true,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Create Account',
          variant: AppButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: SoftType.section),
    );
  }
}

class _HubCard extends StatelessWidget {
  final List<Widget> children;
  const _HubCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: SoftColors.lineSoft),
        boxShadow: SoftShadows.cardSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: SoftColors.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _HubRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool danger;
  final bool showChevron;

  const _HubRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.danger = false,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? SoftColors.danger : SoftColors.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: danger ? SoftColors.dangerSoft : SoftColors.blueSoft,
                  borderRadius: BorderRadius.circular(SoftRadius.sm),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: danger ? SoftColors.danger : SoftColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: SoftType.name.copyWith(color: color)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(subtitle!, style: SoftType.cellLabel),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: SoftColors.muted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
