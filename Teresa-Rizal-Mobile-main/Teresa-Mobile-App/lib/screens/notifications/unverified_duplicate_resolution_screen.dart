import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/citizen_account.dart';
import '../../services/mock_catalog.dart';
import '../../services/notifications_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_haptics.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_dialogs.dart';

/// Unverified + Unverified duplicate-registration demo (FRONTEND
/// SIMULATION ONLY — see MockCatalog.unverifiedDuplicateAccountA's doc
/// comment): the same resident registered twice while still Pending
/// Review both times, so — unlike the Verified-Perlita scenario, where
/// one side is already the "real" account — there's no existing verified
/// account to defer to. Both registrations are shown side by side and the
/// citizen picks which one continues toward verification.
///
/// Choosing a registration to keep is explicitly NOT the same as becoming
/// Verified: the kept account only stops being blocked by *this* duplicate
/// conflict and returns to the normal verification queue, still Pending
/// Review under [CitizenSessionService.accessLevel] — an LGU officer still
/// has to approve it like any other registration.
class UnverifiedDuplicateResolutionScreen extends StatelessWidget {
  const UnverifiedDuplicateResolutionScreen({super.key});

  Future<void> _keep(BuildContext context, NotificationsService notifications, String accountId) async {
    final label = accountId == 'A' ? 'Account A' : 'Account B';
    final confirmed = await AppDialogs.confirm(
      context,
      title: 'Keep This Registration?',
      message:
          'The other registration will be marked as a duplicate and its verification will be cancelled. This '
          'account ($label) will continue toward verification — it does not become Verified automatically; an '
          'LGU officer still reviews it like any other registration.',
      confirmLabel: 'Yes, Keep This Account',
    );
    if (!confirmed) return;
    AppHaptics.medium();
    await notifications.resolveUnverifiedDuplicate(accountId);
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationsService>();
    final kept = notifications.unverifiedDuplicateKeptAccountId;

    return Scaffold(
      appBar: AppBar(title: const Text('Duplicate Registrations')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const Text(
              'Choose the Account You Want to Keep',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Two unverified Teresa, Rizal registrations appear to belong to the same resident. Choose which account '
              'you want to continue using for verification.',
              style: TextStyle(fontSize: 12.5, color: AppColors.slate700, height: 1.45),
            ),
            const SizedBox(height: AppSpacing.xl),
            _AccountCard(
              label: 'Account A',
              account: MockCatalog.unverifiedDuplicateAccountA,
              createdAt: MockCatalog.unverifiedDuplicateAccountACreatedAt,
              resolution: kept == null ? null : (kept == 'A' ? _Resolution.kept : _Resolution.cancelled),
              onKeep: () => _keep(context, notifications, 'A'),
            ),
            const SizedBox(height: AppSpacing.md),
            _AccountCard(
              label: 'Account B',
              account: MockCatalog.unverifiedDuplicateAccountB,
              createdAt: MockCatalog.unverifiedDuplicateAccountBCreatedAt,
              resolution: kept == null ? null : (kept == 'B' ? _Resolution.kept : _Resolution.cancelled),
              onKeep: () => _keep(context, notifications, 'B'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Resolution { kept, cancelled }

class _AccountCard extends StatelessWidget {
  final String label;
  final CitizenAccount account;
  final String createdAt;
  final _Resolution? resolution;
  final VoidCallback onKeep;

  const _AccountCard({
    required this.label,
    required this.account,
    required this.createdAt,
    required this.resolution,
    required this.onKeep,
  });

  static String _maskEmail(String email) {
    final at = email.indexOf('@');
    if (at <= 1) return email;
    return '${email.substring(0, 2)}${'*' * (at - 2)}${email.substring(at)}';
  }

  static String _maskMobile(String mobile) {
    final digits = mobile.replaceAll(' ', '');
    if (digits.length < 8) return mobile;
    return '${digits.substring(0, 4)} ••• ${digits.substring(digits.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          if (resolution != null) ...[
            const SizedBox(height: 6),
            // Its own row (not inline with the label) — the resolved
            // status text is long enough ("Duplicate Registration —
            // Verification Cancelled") that squeezing it beside the label
            // in one row overflowed at normal phone widths.
            Align(alignment: Alignment.centerLeft, child: _ResolutionBadge(resolution: resolution!)),
          ],
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(icon: Icons.mail_outline_rounded, text: _maskEmail(account.email)),
          const SizedBox(height: 4),
          _InfoRow(icon: Icons.phone_outlined, text: _maskMobile(account.mobile)),
          const SizedBox(height: 4),
          _InfoRow(icon: Icons.event_outlined, text: 'Registered $createdAt'),
          const SizedBox(height: AppSpacing.md),
          if (resolution == null)
            AppButton(label: 'Keep This Account', fullWidth: true, onPressed: onKeep)
          else
            Text(
              resolution == _Resolution.kept
                  ? 'This account continues toward verification. It is still Pending Review — it has not become '
                      'Verified automatically.'
                  : 'This registration was marked as a duplicate. Its verification has been cancelled.',
              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.slate400),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12.5, color: AppColors.slate700)),
        ),
      ],
    );
  }
}

class _ResolutionBadge extends StatelessWidget {
  final _Resolution resolution;
  const _ResolutionBadge({required this.resolution});

  @override
  Widget build(BuildContext context) {
    final kept = resolution == _Resolution.kept;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kept ? AppColors.emerald50 : AppColors.rose50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        kept ? 'Unverified — Continue Verification' : 'Duplicate Registration — Verification Cancelled',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: kept ? AppColors.emerald700 : AppColors.rose700,
        ),
      ),
    );
  }
}
