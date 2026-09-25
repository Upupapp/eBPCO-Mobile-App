import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/app_card.dart';
import '../../widgets/soft_chrome.dart';

/// Local inbox preferences. Toggles live in this screen's state only.
/// There is no push service, and these switches do not filter the feed.
class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _emergency = true;
  bool _requests = true;
  bool _announcements = true;

  @override
  Widget build(BuildContext context) {
    return SoftWash(
      child: Scaffold(
        backgroundColor: SoftColors.headerGlowClear,
        appBar: AppBar(
          backgroundColor: SoftColors.headerGlowClear,
          surfaceTintColor: SoftColors.headerGlowClear,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leadingWidth: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SoftCircleButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          title: const Text('Preferences', style: SoftType.pageTitle),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const Text(
              'Choose what you want this inbox to emphasize. Choices stay on this phone. Teresa, Rizal Mobile is not sending push alerts in this preview.',
              style: SoftType.body,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _PrefTile(
                    tileKey: const ValueKey('pref-emergency'),
                    value: _emergency,
                    title: 'Emergency and safety alerts',
                    subtitle: 'MDRRMO weather and evacuation notices',
                    onChanged: (v) => setState(() => _emergency = v),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _PrefTile(
                    tileKey: const ValueKey('pref-requests'),
                    value: _requests,
                    title: 'Dokyu and Tulong updates',
                    subtitle: 'Status changes on your requests',
                    onChanged: (v) => setState(() => _requests = v),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _PrefTile(
                    tileKey: const ValueKey('pref-announcements'),
                    value: _announcements,
                    title: 'Municipal announcements',
                    subtitle: 'Programs and barangay notices',
                    onChanged: (v) => setState(() => _announcements = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Turning a switch off does not remove messages already in the inbox, and nothing here reaches a notification server.',
              style: SoftType.cellLabel.copyWith(height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final Key tileKey;
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const _PrefTile({
    required this.tileKey,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: tileKey,
      value: value,
      onChanged: onChanged,
      activeThumbColor: SoftColors.blue,
      title: Text(title, style: SoftType.name.copyWith(fontSize: 14)),
      subtitle: Text(subtitle, style: SoftType.cellLabel),
    );
  }
}
