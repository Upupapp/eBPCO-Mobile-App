import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/citizen_api.dart';
import '../../core/api/problem.dart';
import '../../domain/profile_photo.dart';
import '../../services/applications_service.dart';
import '../../services/businesses_service.dart';
import '../../services/notifications_service.dart';
import '../../services/session_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_action_sheet.dart';
import '../../widgets/soft_card.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/soft_page.dart';
import '../auth/login_screen.dart';
import '../documents/my_documents_screen.dart';
import '../home/root_shell.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import 'export_data_screen.dart';
import 'help_support_screen.dart';
import 'legal_screen.dart';
import 'notification_preferences_screen.dart';

/// The consequences a citizen must see before deleting their account —
/// same content, same reasoning, as the web portals' delete-account popup:
/// typing/tapping intent is not the same as knowing what it costs.
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

enum _PhotoAction { camera, gallery, remove }

class _ProfileScreenState extends State<ProfileScreen> {
  bool _deleting = false;
  bool _photoBusy = false;

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _say(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  /// The portal's photo control: saved the moment it is chosen
  /// (`PUT /me/photo`), not staged behind Edit Profile's Save.
  Future<void> _changePhoto() async {
    final session = context.read<SessionService>();
    final hasPhoto = session.photo != null || (session.profile?.hasPhoto ?? false);
    final action = await showSoftActionSheet<_PhotoAction>(
      context,
      title: 'Profile photo',
      subtitle: 'A clear photo of your face. JPEG or PNG, up to 5 MB.',
      actions: [
        const SoftSheetAction(value: _PhotoAction.camera, icon: Icons.photo_camera_outlined, title: 'Take a photo'),
        const SoftSheetAction(value: _PhotoAction.gallery, icon: Icons.photo_library_outlined, title: 'Choose from gallery'),
        if (hasPhoto)
          const SoftSheetAction(value: _PhotoAction.remove, icon: Icons.delete_outline_rounded, title: 'Remove photo', destructive: true),
      ],
    );
    if (action == null || !mounted) return;

    if (action == _PhotoAction.remove) {
      setState(() => _photoBusy = true);
      try {
        await session.removePhoto();
        if (mounted) _say('Photo removed.');
      } on ApiError catch (e) {
        if (mounted) _say(e.citizenMessage);
      } finally {
        if (mounted) setState(() => _photoBusy = false);
      }
      return;
    }

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: action == _PhotoAction.camera ? ImageSource.camera : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.front,
        // Keeps decoding quick; the photo is scaled down further below.
        maxWidth: 1600,
        maxHeight: 1600,
      );
    } catch (_) {
      if (mounted) _say(action == _PhotoAction.camera ? 'The camera could not be opened.' : 'Your photos could not be opened.');
      return;
    }
    if (picked == null || !mounted) return;

    setState(() => _photoBusy = true);
    try {
      final prepared = await compute(prepareProfilePhoto, await picked.readAsBytes());
      if (prepared == null) {
        if (mounted) _say('That file is not a photo that can be used. Choose a JPEG or PNG image.');
        return;
      }
      await session.setPhoto(prepared);
      if (mounted) _say('Photo updated.');
    } on ApiError catch (e) {
      if (mounted) _say(e.citizenMessage);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  Future<void> _logout() async {
    await context.read<SessionService>().logout();
    if (!mounted) return;
    // Cached data belongs to the account that just signed out — cleared
    // immediately so a second citizen on the same device never sees even a
    // brief flash of someone else's applications.
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
            title: Text('Delete your account?', style: SoftType.pageTitle.copyWith(fontSize: 20)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_deleteWarning, style: SoftType.body.copyWith(color: SoftColors.ink)),
                  const SizedBox(height: 16),
                  Text('Type DELETE to confirm', style: SoftType.fieldLabel),
                  const SizedBox(height: 8),
                  TextField(controller: controller, style: SoftType.field, onChanged: (_) => setState(() {})),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              TextButton(
                onPressed: controller.text.trim().toUpperCase() == 'DELETE' ? () => Navigator.of(context).pop(true) : null,
                style: TextButton.styleFrom(foregroundColor: SoftColors.danger),
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
    final session = context.watch<SessionService>();
    final profile = session.profile;
    final unread = context.watch<NotificationsService>().unreadCount;
    final verified = profile?.emailVerifiedAt != null;
    final barangay = profile?.barangay;
    final mobile = profile?.mobileNumber;

    return SoftPageScaffold(
      title: 'Profile',
      underNav: true,
      actions: [
        SoftCircleButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          badge: unread,
          onPressed: () => RootShell.jumpTo(context, 2),
        ),
      ],
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, SoftPageScaffold.navClearance(context)),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.fullName ?? '', style: SoftType.h1.copyWith(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(profile?.email ?? '', style: SoftType.body),
                    const SizedBox(height: 10),
                    SoftStatusPill(
                      label: verified ? 'Email verified' : 'Email not verified',
                      tone: verified ? SoftStatusTone.verified : SoftStatusTone.pending,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _PhotoButton(
                initials: _initials(profile?.firstName, profile?.lastName),
                photo: session.photo,
                busy: _photoBusy,
                onTap: _photoBusy ? null : _changePhoto,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            verified
                ? 'Your email address was confirmed when you signed up.'
                : 'Your email address was not confirmed when this account was created. This does not block '
                    'anything here; the Municipality may confirm it with you directly.',
            style: SoftType.cellLabel.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _InfoCell(label: 'Barangay', value: (barangay == null || barangay.isEmpty) ? 'Not set' : barangay)),
              const SizedBox(width: 12),
              Expanded(child: _InfoCell(label: 'Mobile', value: (mobile == null || mobile.isEmpty) ? 'Not set' : mobile)),
            ],
          ),
          const SizedBox(height: 12),
          SoftCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: SoftColors.white, shape: BoxShape.circle, boxShadow: SoftShadows.seal),
                  child: Image.asset('assets/images/ebpco_seal.png', fit: BoxFit.contain),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Municipality of Castilla', style: SoftType.tileTitle.copyWith(fontSize: 16)),
                      const SizedBox(height: 2),
                      Text('Province of Sorsogon · eBPCO citizen account', style: SoftType.tileSub),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SoftSectionHeader(title: 'Account'),
          SoftGroupedList(rows: [
            SoftListRow(icon: Icons.person_outline_rounded, title: 'Edit Profile', subtitle: 'Name, address and mobile number', onTap: () => _push(const EditProfileScreen())),
            SoftListRow(icon: Icons.lock_outline_rounded, title: 'Change Password', onTap: () => _push(const ChangePasswordScreen())),
            SoftListRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notification Preferences',
              onTap: () => _push(const NotificationPreferencesScreen()),
            ),
          ]),
          const SizedBox(height: 22),
          const SoftSectionHeader(title: 'Activity'),
          SoftGroupedList(rows: [
            SoftListRow(icon: Icons.folder_outlined, title: 'My Documents', subtitle: 'Files you have uploaded', onTap: () => _push(const MyDocumentsScreen())),
            SoftListRow(icon: Icons.download_outlined, title: 'Export Your Data', onTap: () => _push(const ExportDataScreen())),
          ]),
          const SizedBox(height: 22),
          const SoftSectionHeader(title: 'Support'),
          SoftGroupedList(rows: [
            SoftListRow(icon: Icons.help_outline_rounded, title: 'Help & Support', onTap: () => _push(const HelpSupportScreen())),
            SoftListRow(icon: Icons.description_outlined, title: 'Terms & Privacy', onTap: () => _push(const LegalScreen())),
          ]),
          const SizedBox(height: 24),
          SoftPillButton(label: 'Log Out', kind: SoftPillKind.outline, icon: Icons.logout_rounded, onPressed: _logout),
          const SizedBox(height: 28),
          SoftCard(
            color: SoftColors.dangerSoft,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delete Your Account', style: SoftType.tileTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w600, color: SoftColors.danger)),
                const SizedBox(height: 6),
                Text(
                  'This permanently erases your account and profile, as far as the law allows — some records (like a filed '
                  'permit application) must be kept for a legal retention period even after your account is deleted (RA 10173, §16(e)).',
                  style: SoftType.body.copyWith(color: SoftColors.ink),
                ),
                const SizedBox(height: 14),
                SoftPillButton(
                  label: _deleting ? 'Deleting…' : 'Permanently Delete My Account',
                  kind: SoftPillKind.danger,
                  busy: _deleting,
                  onPressed: _deleting ? null : _confirmDelete,
                ),
              ],
            ),
          ),
        ],
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

/// The avatar with a camera badge — tap to take, choose or remove a photo.
class _PhotoButton extends StatelessWidget {
  final String initials;
  final Uint8List? photo;
  final bool busy;
  final VoidCallback? onTap;
  const _PhotoButton({required this.initials, required this.photo, required this.busy, required this.onTap});

  static const _size = 72.0;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: photo == null ? 'Add profile photo' : 'Change profile photo',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: _size + 4,
          height: _size + 4,
          child: Stack(
            children: [
              SoftInitialAvatar(initials: initials, photo: photo, size: _size),
              if (busy)
                Container(
                  width: _size,
                  height: _size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: SoftColors.ink.withValues(alpha: 0.35), shape: BoxShape.circle),
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: SoftColors.white),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: SoftColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: SoftColors.white, width: 2),
                  ),
                  child: const Icon(Icons.photo_camera_rounded, size: 14, color: SoftColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final String label;
  final String value;
  const _InfoCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SoftType.cellLabel.copyWith(fontSize: 13)),
          const SizedBox(height: 4),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: SoftType.cellValue.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
