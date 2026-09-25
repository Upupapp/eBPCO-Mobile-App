import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/expandable_panel.dart';

/// Privacy Policy — accessible from the hamburger drawer. Every fact this
/// screen states must be traceable to what Teresa, Rizal Mobile actually does
/// (see individual section comments below); anything still owned by the
/// Municipality/DPO is spelled out as a `[TO BE PROVIDED ...]` placeholder
/// rather than invented, since this app has no backend and the production
/// policy still needs LGU/legal review before release.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            child: Text(
              'Learn how Teresa, Rizal Mobile handles and protects your information.',
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
          const Text(
            'Last updated: [TO BE PROVIDED BY MUNICIPALITY]',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.slate400),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Teresa, Rizal Mobile is designed to help residents of the Municipality of Teresa, Rizal interact with '
            'municipal services digitally — including requesting documents, applying for assistance programs, and '
            'staying informed through municipal announcements. Protecting your personal information is important '
            'to us. This Privacy Policy describes what information Teresa, Rizal Mobile may collect, why it is used, '
            'and how you can manage your information.',
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xl),

          ExpandablePanel(
            title: '1. Information We Collect',
            icon: Icons.badge_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Personal Information', style: AppTypography.subsectionLabel),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'When you create an account or complete your Resident Profile, Teresa, Rizal Mobile may collect '
                  'information such as:',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                const BulletList([
                  'Full name',
                  'Date of birth',
                  'Automatically calculated age, derived from your date of birth, where applicable',
                  'Sex/gender information, where required by a municipal form',
                  'Contact information (e.g., mobile number, email address)',
                  'Address, sitio/purok, and barangay',
                  'Other information required by the specific municipal service you are using',
                ]),
                const SizedBox(height: AppSpacing.lg),
                const Text('Account Information', style: AppTypography.subsectionLabel),
                const SizedBox(height: AppSpacing.sm),
                const Text('To use Teresa, Rizal Mobile, the app maintains:', style: AppTypography.body),
                const SizedBox(height: AppSpacing.sm),
                const BulletList([
                  'Account/profile information',
                  'Authentication-related information used to sign you in',
                  'Resident profile information you submit',
                ]),
                const SizedBox(height: AppSpacing.lg),
                const Text('Family and Household Information', style: AppTypography.subsectionLabel),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'If you choose to complete the Resident Profile feature, Teresa, Rizal Mobile may also process:',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                const BulletList([
                  "Family information, including family members and their relationship to the family's head",
                  'Household information, including other families that share the same physical household, where applicable',
                  'Other information required for municipal resident records',
                ]),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'This information is only collected if you choose to complete the relevant Resident Profile section.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),

          ExpandablePanel(
            title: '2. Dokyu & Tulong Information',
            icon: Icons.description_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Dokyu (Document Requests)', style: AppTypography.subsectionLabel),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'When you request a document or municipal service through Dokyu, you may provide:',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                const BulletList([
                  'Application/form information',
                  'Supporting documents',
                  'Identification',
                  'Photos',
                  'PDF/DOCX attachments',
                  'Request/application history',
                  'Status information',
                ]),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'This information is used to process and manage the municipal service you requested.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Tulong (Assistance Requests)', style: AppTypography.subsectionLabel),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Tulong applications may require information related to the specific assistance being '
                  'requested. Depending on the program, this may include:',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                const BulletList([
                  'Applicant information',
                  'Supporting documents',
                  'Proof or requirements specific to that program',
                  'Images',
                  'Identification',
                  'Application information',
                  'Assistance request history and status',
                ]),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Not every Tulong program requires all of the items listed above — requirements depend on the '
                  'specific assistance program you are applying for.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),

          ExpandablePanel(
            title: '3. Device Permissions',
            icon: Icons.camera_alt_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Teresa, Rizal Mobile only requests access to your camera, photos, or documents when you choose to "
                  'use a feature that needs it — never automatically, and never at startup. For example:',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                const BulletList([
                  'Take a photo → Camera access may be requested.',
                  "Choose from gallery → Photo/gallery access may be requested where required by your device's platform.",
                  "Choose a document → Teresa, Rizal uses your device's own document picker wherever possible, rather than requesting broad storage access.",
                ]),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Teresa, Rizal Mobile uses the minimum access necessary to complete the action you requested. '
                  'Teresa, Rizal Mobile does not access all photos or files on your device.',
                  style: AppTypography.body,
                ),
              ],
            ),
          ),

          ExpandablePanel(
            title: '4. How We Use Information',
            icon: Icons.settings_outlined,
            child: const BulletList([
              'Providing municipal services',
              'Processing Dokyu (document) requests',
              'Processing Tulong (assistance) requests',
              'Maintaining your submitted Resident Profile information',
              'Providing request/application status updates',
              'Sending relevant notifications',
              'Supporting municipal service administration',
              'Maintaining app functionality and security',
            ]),
          ),

          ExpandablePanel(
            title: '5. Notifications',
            icon: Icons.notifications_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Teresa, Rizal Mobile may use notifications for purposes such as:', style: AppTypography.body),
                const SizedBox(height: AppSpacing.sm),
                const BulletList([
                  'Dokyu request updates',
                  'Tulong request updates',
                  'Application/request status changes',
                  'Municipal announcements',
                  'Important service information',
                  'Emergency/safety information, where applicable',
                ]),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Notification behavior and permissions depend on your device and platform settings.',
                  style: AppTypography.body,
                ),
              ],
            ),
          ),

          ExpandablePanel(
            title: '6. Information Sharing',
            icon: Icons.share_outlined,
            child: const Text(
              'Information you submit through Teresa, Rizal Mobile may need to be accessible to authorized municipal '
              "personnel or offices responsible for processing the relevant service (for example, the office "
              'handling your Dokyu or Tulong request). Teresa, Rizal Mobile does not share your information with any '
              'specific external organization unless this is confirmed by the Municipality.\n\n'
              'Details regarding authorized recipients, service providers, or other data-sharing arrangements '
              'must be confirmed by the Municipality of Teresa, Rizal before production release.',
              style: AppTypography.body,
            ),
          ),

          ExpandablePanel(
            title: '7. Data Security',
            icon: Icons.shield_outlined,
            child: const Text(
              'Teresa, Rizal Mobile aims to use reasonable technical and organizational safeguards to help protect '
              'your information against unauthorized access, unauthorized disclosure, alteration, loss, and '
              'misuse.\n\n'
              'No system can be guaranteed to be completely secure. Specific security measures or encryption '
              'systems used in production must be confirmed by the Municipality of Teresa, Rizal before this policy '
              'is finalized.',
              style: AppTypography.body,
            ),
          ),

          ExpandablePanel(
            title: '8. Data Retention',
            icon: Icons.schedule_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teresa, Rizal Mobile does not define its own retention periods. Information should only be '
                  'retained according to applicable municipal requirements, legal obligations, and approved '
                  'retention policies of the Municipality of Teresa, Rizal.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Specific retention periods: [TO BE PROVIDED/CONFIRMED BY MUNICIPALITY]',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.amber700),
                ),
              ],
            ),
          ),

          ExpandablePanel(
            title: '9. Your Privacy Rights',
            icon: Icons.gavel_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Depending on applicable Philippine data-protection requirements, you may have rights '
                  'concerning your personal information, which can include requesting access to, or correction '
                  'of, your information, and raising privacy concerns with the appropriate office. This section '
                  'is general information only and is not individualized legal advice.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.md),
                _ContactBlock(
                  lines: const [
                    'Privacy / Data Protection Contact',
                    'Email: [TO BE PROVIDED]',
                    'Phone: [TO BE PROVIDED]',
                    'Office: [TO BE PROVIDED]',
                  ],
                ),
              ],
            ),
          ),

          ExpandablePanel(
            title: '10. Information About Minors',
            icon: Icons.family_restroom_outlined,
            child: const Text(
              'Household and family records may include information about minors (for example, children listed '
              'as family members). Information about minors should only be provided where it is legitimately '
              'required for municipal services, and should be handled with appropriate safeguards. Teresa, Rizal '
              'Mobile does not define specific age thresholds or consent mechanisms beyond what is implemented '
              'in the app.',
              style: AppTypography.body,
            ),
          ),

          ExpandablePanel(
            title: '11. Third-Party Services',
            icon: Icons.extension_outlined,
            child: const Text(
              "Teresa, Rizal Mobile currently uses a small number of device-level packages to support its features "
              "(for example, selecting a photo, choosing a document, opening your device's share menu, or "
              'opening a phone/map link). These operate locally on your device and do not send your information '
              'to Teresa, Rizal. This app does not currently connect to any external backend or third-party server.\n\n'
              'This section must be reviewed and confirmed by the Municipality of Teresa, Rizal before production '
              'release, especially if a backend, analytics, or hosting provider is introduced later.',
              style: AppTypography.body,
            ),
          ),

          ExpandablePanel(
            title: '12. Changes to This Policy',
            icon: Icons.update_outlined,
            child: const Text(
              'This Privacy Policy may be updated when app functionality changes, municipal procedures change, '
              'privacy/security practices change, or applicable requirements change. Please check this page '
              'periodically for updates.',
              style: AppTypography.body,
            ),
          ),

          ExpandablePanel(
            title: '13. Contact Us',
            icon: Icons.mail_outline_rounded,
            initiallyExpanded: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Privacy Questions or Concerns', style: AppTypography.subsectionLabel),
                const SizedBox(height: AppSpacing.sm),
                _ContactBlock(
                  lines: const [
                    'Municipality of Teresa, Rizal',
                    'Privacy / Data Protection Contact',
                    'Email: [TO BE PROVIDED]',
                    'Phone: [TO BE PROVIDED]',
                    'Office: [TO BE PROVIDED]',
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBlock extends StatelessWidget {
  final List<String> lines;
  const _ContactBlock({required this.lines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.slate50, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < lines.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == lines.length - 1 ? 0 : 4),
              child: Text(
                lines[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.slate700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
