import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../services/applications_service.dart';
import '../../services/businesses_service.dart';
import '../../services/notifications_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/soft_card.dart';
import '../auth/login_screen.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'export_data_screen.dart';

/// The consequences a citizen must see before deleting their account —
/// same content, same reasoning, as the web portals' delete-account popup
/// shipped this session: typing/tapping intent is not the same as knowing
/// what it costs.
const _deleteWarning = "This cannot be undone. Once your account is erased:\n\n"
    '• You will not be able to sign back in — your email, mobile number, and password are permanently deleted.\n\n'
    '• Any application still awaiting payment will be automatically cancelled, since you will not be able to finish it afterward.\n\n'
    '• Any payment you have already made will NOT be refunded — payments, Official Receipts, and Orders of Payment are kept '
    'for treasury and audit records and are not reversed by deleting your account.\n\n'
    '• Any permit already issued to you remains valid and on file — a permit stays proof a structure was lawfully authorised, '
    'even after your account is gone.\n\n'
    'If you still expect a refund, or have an application already assessed or paid for, contact the Municipality before deleting your account.';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _deleting = false;

  Future<void> _logout() async {
    await context.read<SessionService>().logout();
    if (!mounted) return;
    // Cached data belongs to the account that just signed out — cleared
    // immediately rather than left to whichever screen's own initState
    // refresh() happens to run first, so a second citizen on the same
    // device never sees even a brief flash of someone else's applications.
    context.read<ApplicationsService>().clear();
    context.read<NotificationsService>().clear();
    context.read<BusinessesService>().clear();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  Future<void> _confirmDelete() async {
    final typed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Delete your account?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_deleteWarning, style: AppTypography.body),
                const SizedBox(height: AppSpacing.lg),
                Text('Type DELETE to confirm', style: AppTypography.fieldLabel),
                const SizedBox(height: 6),
                TextField(controller: controller, onChanged: (_) => setState(() {})),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(
                onPressed: controller.text.trim().toUpperCase() == 'DELETE' ? () => Navigator.of(context).pop(true) : null,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Yes, Delete My Account'),
              ),
            ],
          ),
        );
      },
    );
    if (typed != true) return;

    setState(() => _deleting = true);
    try {
      await CitizenApi.instance.eraseAccount();
      if (!mounted) return;
      await context.read<SessionService>().logout();
      if (!mounted) return;
      context.read<ApplicationsService>().clear();
      context.read<NotificationsService>().clear();
      context.read<BusinessesService>().clear();
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your account has been erased, as far as the law allows.')));
    } on ApiError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.citizenMessage)));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<SessionService>().profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl, 40),
          children: [
            SoftCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary100,
                    child: Text(
                      _initials(profile?.firstName, profile?.lastName),
                      style: AppTypography.h2.copyWith(color: AppColors.primary700),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?.fullName ?? '', style: AppTypography.h3),
                        Text(profile?.email ?? '', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _MenuTile(
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen())),
            ),
            _MenuTile(
              icon: Icons.lock_outline,
              label: 'Change Password',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            _MenuTile(
              icon: Icons.download_outlined,
              label: 'Export Your Data',
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExportDataScreen())),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                child: const Text('Log Out'),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Divider(color: AppColors.borderLight),
            const SizedBox(height: AppSpacing.lg),
            Text('Delete Your Account', style: AppTypography.h3.copyWith(color: AppColors.danger)),
            const SizedBox(height: 6),
            Text(
              'This permanently erases your account and profile, as far as the law allows — some records (like a filed '
              'permit application) must be kept for a legal retention period even after your account is deleted (RA 10173, §16(e)).',
              style: AppTypography.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _deleting ? null : _confirmDelete,
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                child: Text(_deleting ? 'Deleting…' : 'Permanently Delete My Account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String? first, String? last) {
  final a = (first?.isNotEmpty ?? false) ? first![0] : '';
  final b = (last?.isNotEmpty ?? false) ? last![0] : '';
  final result = '$a$b'.toUpperCase();
  return result.isEmpty ? '?' : result;
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: SoftCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, color: AppColors.gray600, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(label, style: AppTypography.bodyMedium)),
            const Icon(Icons.chevron_right, color: AppColors.gray400),
          ],
        ),
      ),
    );
  }
}
