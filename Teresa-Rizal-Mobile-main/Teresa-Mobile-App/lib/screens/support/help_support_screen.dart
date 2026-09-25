import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_card.dart';
import '../../widgets/expandable_panel.dart';
import '../../widgets/section_header.dart';
import '../legal/privacy_policy_screen.dart';
import 'report_problem_screen.dart';

/// Help & Support — accessible from the hamburger drawer (and the Profile
/// menu's matching entry). FAQ copy below only describes behavior actually
/// present in this codebase (registration wizard, Dokyu/Tulong request
/// flow + attachment picker, the universal AppStatus vocabulary, the
/// notifications red-dot rule, Balita's guest-vs-signed-in restriction,
/// etc.) — see each section for what it's grounded in.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _accountKey = GlobalKey();
  final _dokyuKey = GlobalKey();
  final _tulongKey = GlobalKey();
  final _uploadKey = GlobalKey();
  final _notificationsKey = GlobalKey();
  final _troubleshootingKey = GlobalKey();

  void _jumpTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.05);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Text(
              'Find answers, learn how to use Teresa, Rizal Mobile, or get help with a problem.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const SectionHeader(title: 'Quick Help'),
          _QuickHelpGrid(
            onAccount: () => _jumpTo(_accountKey),
            onDokyu: () => _jumpTo(_dokyuKey),
            onTulong: () => _jumpTo(_tulongKey),
            onUpload: () => _jumpTo(_uploadKey),
            onNotifications: () => _jumpTo(_notificationsKey),
            onTechnical: () => _jumpTo(_troubleshootingKey),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(key: _accountKey, title: 'Account & Profile'),
          const ExpandablePanel(
            title: 'How do I create an account?',
            child: Text(
              'From the Sign In screen, tap Create Account. Registration walks you through Personal Information, '
              'Terms & Conditions, Valid ID Upload, a simulated Face Verification step, and a final Review before '
              'your account is submitted for verification.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'How do I update my Resident Profile?',
            child: Text(
              'Open your Resident Profile from Profile > Household & Family, or from the "Complete Your Profile" '
              'notification, then update the Personal Information, Family Information, or Household Information '
              'sections and save your changes.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'Why should I complete my Resident Profile?',
            child: Text(
              'Completing your Resident Profile helps Teresa, Rizal LGU verify your account and unlocks full access '
              'to Teresa, Rizal Mobile’s services.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'How do I update my Family Information?',
            child: Text(
              'In your Resident Profile, open Family Information to add, edit, or remove family members and set '
              'your family name.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'What is Household Information?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Household Information and Family Information cover two different things:',
                  style: AppTypography.body,
                ),
                SizedBox(height: AppSpacing.sm),
                BulletList([
                  "Family Information — information about your own family: your family name, and your family members.",
                  'Household Information — your household details (address, housing, utilities), plus other family '
                      'groups that share the same physical household with you, where applicable.',
                ]),
              ],
            ),
          ),
          const ExpandablePanel(
            title: 'How do I change my profile picture?',
            child: Text(
              'Open Personal Information in your Resident Profile and tap your photo to choose a new one from '
              'your gallery.',
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          SectionHeader(key: _dokyuKey, title: 'Dokyu'),
          const ExpandablePanel(
            title: 'What is Dokyu?',
            child: Text(
              'Dokyu is the section of Teresa, Rizal Mobile used to request and track supported municipal documents, '
              'such as barangay clearances and certificates.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'How do I submit a Dokyu request?',
            child: Text(
              'Open Dokyu, choose the document you need, and complete the multi-step request form. You can '
              'attach any required documents before submitting.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'How do I attach a requirement?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('When attaching a file, you can:', style: AppTypography.body),
                SizedBox(height: AppSpacing.sm),
                BulletList(['Take a photo', 'Choose from gallery', 'Choose a document (PDF/DOCX)']),
              ],
            ),
          ),
          const ExpandablePanel(
            title: 'How do I know the status of my request?',
            child: Text(
              'Open the request from Dokyu to see its current status — such as Pending Review, Under '
              'Verification, Processing, Approved, or Rejected — along with a history of status updates.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'What happens if my request is rejected?',
            child: Text(
              'Check the request’s details or the related notification for any information provided. '
              'Teresa, Rizal Mobile does not currently include a formal appeal process within the app.',
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          SectionHeader(key: _tulongKey, title: 'Tulong'),
          const ExpandablePanel(
            title: 'What is Tulong?',
            child: Text(
              'Tulong is the section of Teresa, Rizal Mobile used to request supported municipal assistance programs.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'How do I request assistance?',
            child: Text(
              'Open Tulong, choose the assistance program you need, and complete the request form.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'What documents do I need?',
            child: Text(
              'Requirements depend on the specific assistance program you are applying for — the request form '
              'will show what’s needed for that program.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'How do I track my Tulong request?',
            child: Text(
              'Open the request from Tulong to see its current status and status history.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'What do Pending, Approved and Rejected mean?',
            child: Text(
              'These reflect where your request is in the review process. A request may also show other '
              'statuses, such as Under Verification, Processing, or Under Review, depending on how far '
              'along it is.',
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          SectionHeader(key: _uploadKey, title: 'Uploading Documents and Photos'),
          const ExpandablePanel(
            title: 'Why does Teresa, Rizal ask for camera permission?',
            child: Text(
              'Camera access is requested only when you choose Take a photo, so you can attach a picture '
              'directly to your request.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'Why does Teresa, Rizal ask for photo access?',
            child: Text(
              'Photo/gallery access may be requested when you choose Choose from gallery, so you can select an '
              'existing image to attach.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'How do I upload a PDF or DOCX?',
            child: Text(
              'When attaching a file, choose Choose a document (PDF/DOCX) and select the file from your '
              'device’s document picker.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'What should I do if I denied permission?',
            child: Text(
              'You can try the action again — Teresa, Rizal will ask again if needed. If the permission was '
              'permanently disabled, you may need to enable it from your device’s Settings; Teresa, Rizal will '
              'offer to take you there.',
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          SectionHeader(key: _notificationsKey, title: 'Notifications'),
          const ExpandablePanel(
            title: 'What notifications will I receive?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Teresa, Rizal Mobile may show notifications for:', style: AppTypography.body),
                SizedBox(height: AppSpacing.sm),
                BulletList([
                  'Dokyu updates',
                  'Tulong updates',
                  'Status changes',
                  'Municipal announcements',
                  'Relevant municipal information',
                  'Emergency/safety alerts, where applicable',
                ]),
              ],
            ),
          ),
          const ExpandablePanel(
            title: 'What does the red dot mean?',
            child: Text(
              'The red indicator means there is at least one notification you have not yet viewed.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'Why am I not receiving notifications?',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A few things to check:', style: AppTypography.body),
                SizedBox(height: AppSpacing.sm),
                BulletList([
                  'Check notification permission for Teresa, Rizal',
                  'Check your device’s notification settings',
                  'Check your internet connection',
                  'Restart or reopen the app',
                  'Check whether notifications are disabled for Teresa, Rizal',
                ]),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Balita & Events'),
          const ExpandablePanel(
            title: 'What is Balita?',
            child: Text(
              'Balita provides municipal and community news and updates published by Teresa, Rizal LGU.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'What is Events?',
            child: Text(
              'Events shows upcoming events, activities, and celebrations in Teresa, Rizal.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'Can I react, comment, or share?',
            child: Text(
              'Signed-in users can react to, comment on, and share Balita posts. Guests browsing without an '
              'account are asked to sign in or create an account first.',
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Emergency'),
          const ExpandablePanel(
            title: 'What is the Emergency section?',
            child: Text(
              'The Risk Reduction & Emergency section provides disaster-risk-reduction information such as '
              'emergency hotlines and evacuation center details, and lets you report an incident and track its '
              'status.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'Are emergency notices the same as regular Balita posts?',
            child: Text(
              'No. Emergency/Risk Reduction is a separate area intended for urgent, safety-related information '
              'and hotlines, while Balita is Teresa, Rizal’s general community news and updates feed. In a '
              'life-threatening emergency, call 911 or MDRRMO directly — Teresa, Rizal Mobile is not a substitute '
              'for emergency services.',
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(key: _troubleshootingKey, title: 'Troubleshooting'),
          const ExpandablePanel(
            title: 'Camera won’t open',
            child: Text(
              'Make sure you allowed camera access when prompted. If you previously denied it, you may need to '
              'enable Camera permission for Teresa, Rizal from your device Settings, then try again.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'Cannot select photo',
            child: Text(
              'Make sure you allowed photo/gallery access when prompted, then try again. On some devices you '
              'may need to choose "Allow" rather than "Allow once" for repeated use.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'Cannot upload PDF/DOCX',
            child: Text(
              'Confirm the file is a supported type (PDF or DOCX) and try selecting it again from your device’s '
              'document picker.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'Upload failed',
            child: Text(
              'Check the file’s size and format, then try attaching it again. If the problem continues, try a '
              'different photo or document.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'Request won’t submit',
            child: Text(
              'Make sure all required fields are filled in and any required attachments are added, then try '
              'submitting again.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'Notifications not appearing',
            child: Text(
              'Check that notification permission is enabled for Teresa, Rizal in your device Settings, and that '
              'you’re connected to the internet.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'App content isn’t loading',
            child: Text(
              'Try closing and reopening the app. If the issue continues, check your internet connection.',
              style: AppTypography.body,
            ),
          ),
          const ExpandablePanel(
            title: 'Sign-in problem',
            child: Text(
              'Double-check your registered email and try again. If you’re a returning user without an '
              'account on this device, use Sign In rather than Create Account.',
              style: AppTypography.body,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          const SectionHeader(title: 'Contact Support'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Municipality of Teresa, Rizal Support', style: AppTypography.subsectionLabel),
                SizedBox(height: AppSpacing.md),
                _ContactRow(icon: Icons.mail_outline_rounded, label: 'Email', value: '[TO BE PROVIDED]'),
                _ContactRow(icon: Icons.call_outlined, label: 'Phone', value: '[TO BE PROVIDED]'),
                _ContactRow(icon: Icons.apartment_outlined, label: 'Office', value: '[TO BE PROVIDED]'),
                _ContactRow(icon: Icons.schedule_outlined, label: 'Office Hours', value: '[TO BE PROVIDED]'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportProblemScreen())),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.rose50, borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.flag_outlined, size: 19, color: AppColors.rose600),
                ),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'Report a Problem',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.slate700),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.slate300),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          Center(
            child: TextButton(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
              child: const Text(
                'Privacy Policy',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.brand600),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Center(
            child: Text(
              'Teresa, Rizal Mobile — Version 1.0.0 (Frontend Preview Build)',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.slate400),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ', style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.slate700),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickHelpGrid extends StatelessWidget {
  final VoidCallback onAccount;
  final VoidCallback onDokyu;
  final VoidCallback onTulong;
  final VoidCallback onUpload;
  final VoidCallback onNotifications;
  final VoidCallback onTechnical;

  const _QuickHelpGrid({
    required this.onAccount,
    required this.onDokyu,
    required this.onTulong,
    required this.onUpload,
    required this.onNotifications,
    required this.onTechnical,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (icon: Icons.person_outline_rounded, label: 'Account & Profile', color: AppColors.brand600, onTap: onAccount),
      (icon: Icons.description_outlined, label: 'Dokyu', color: AppColors.brand600, onTap: onDokyu),
      (icon: Icons.volunteer_activism_outlined, label: 'Tulong', color: AppColors.purple700, onTap: onTulong),
      (icon: Icons.add_photo_alternate_outlined, label: 'Uploading Files', color: AppColors.teal700, onTap: onUpload),
      (icon: Icons.notifications_outlined, label: 'Notifications', color: AppColors.amber700, onTap: onNotifications),
      (icon: Icons.build_outlined, label: 'Technical Problems', color: AppColors.rose600, onTap: onTechnical),
    ];

    // A Row of Expanded cards (same idiom as SegmentedTabs) rather than a
    // fixed-aspect-ratio GridView — each card's height follows its own
    // content, so a 2-line label at a larger text scale simply grows the
    // row instead of overflowing a height GridView had already fixed.
    return Column(
      children: [
        _QuickHelpRow(items: items.sublist(0, 3)),
        const SizedBox(height: AppSpacing.sm),
        _QuickHelpRow(items: items.sublist(3, 6)),
      ],
    );
  }
}

class _QuickHelpRow extends StatelessWidget {
  final List<({IconData icon, String label, Color color, VoidCallback onTap})> items;
  const _QuickHelpRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(child: _QuickHelpCard(item: items[i])),
          ],
        ],
      ),
    );
  }
}

class _QuickHelpCard extends StatelessWidget {
  final ({IconData icon, String label, Color color, VoidCallback onTap}) item;
  const _QuickHelpCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, size: 17, color: item.color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.slate700, height: 1.2),
          ),
        ],
      ),
    );
  }
}
