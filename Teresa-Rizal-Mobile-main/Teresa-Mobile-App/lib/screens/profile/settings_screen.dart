import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_card.dart';

/// Basic account preferences. Kept intentionally small — matches what a
/// citizen actually needs, not a copy of the Web Admin's admin-facing
/// Settings module (General/Branding/Audit Logs are admin-only concerns
/// and must never appear on mobile, per Section 6 of the alignment doc).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = true;
  String _language = 'Filipino';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const _SectionLabel('Notifications'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: _pushEnabled,
                  onChanged: (v) => setState(() => _pushEnabled = v),
                  title: const Text(
                    'Push notifications',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Request status updates and announcements', style: TextStyle(fontSize: 11.5)),
                  activeThumbColor: AppColors.brand500,
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  value: _emailEnabled,
                  onChanged: (v) => setState(() => _emailEnabled = v),
                  title: const Text(
                    'Email notifications',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                  ),
                  subtitle: const Text('Copy of important updates by email', style: TextStyle(fontSize: 11.5)),
                  activeThumbColor: AppColors.brand500,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Language'),
          AppCard(
            padding: EdgeInsets.zero,
            child: RadioGroup<String>(
              groupValue: _language,
              onChanged: (v) => setState(() => _language = v!),
              child: Column(
                children: ['Filipino', 'English']
                    .map(
                      (lang) => RadioListTile<String>(
                        value: lang,
                        title: Text(lang, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500)),
                        activeColor: AppColors.brand500,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('About'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Teresa, Rizal Mobile', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Version 1.0.0 (Frontend Preview Build)',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Municipality of Teresa, Rizal — Region V (Bicol Region)',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
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
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
