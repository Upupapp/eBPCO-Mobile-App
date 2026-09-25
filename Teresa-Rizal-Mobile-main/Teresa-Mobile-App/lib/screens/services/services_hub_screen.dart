import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/service_launcher_menu.dart';
import '../../widgets/soft_chrome.dart';
import '../home/root_shell.dart';

/// Services hub. Dokyu, Tulong, and Emergency leave the primary rail and
/// open from here. Access checks stay in [RootShell.openService].
class ServicesHubScreen extends StatelessWidget {
  const ServicesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SoftWash(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              Row(
                children: [
                  SoftCircleButton(
                    icon: Icons.menu_rounded,
                    tooltip: 'Menu',
                    onPressed: () => RootShell.openDrawer(context),
                  ),
                  const Spacer(),
                  const AlertsAction(),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Municipal services', style: SoftType.eyebrow),
              const SizedBox(height: 4),
              const Text('Services', style: SoftType.h1),
              const SizedBox(height: 6),
              const Text(
                'Documents, assistance, and emergency tools for Teresa, Rizal.',
                style: SoftType.body,
              ),
              const SizedBox(height: 18),
              _ServiceCard(
                icon: Icons.description_outlined,
                title: 'Dokyu',
                subtitle: 'Request and track municipal documents.',
                onTap: () =>
                    RootShell.openService(context, ServiceLauncherTarget.dokyu),
              ),
              _ServiceCard(
                icon: Icons.volunteer_activism_outlined,
                title: 'Tulong',
                subtitle: 'Apply for assistance programs.',
                onTap: () => RootShell.openService(
                  context,
                  ServiceLauncherTarget.tulong,
                ),
              ),
              _ServiceCard(
                icon: Icons.shield_outlined,
                title: 'Emergency',
                subtitle: 'Hotlines, evacuation centers, and incident reports.',
                alert: true,
                onTap: () => RootShell.openService(
                  context,
                  ServiceLauncherTarget.emergency,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool alert;

  const _ServiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(SoftRadius.lg),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SoftRadius.lg),
              border: Border.all(color: SoftColors.line),
              boxShadow: SoftShadows.cardSm,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: alert ? AppColors.rose50 : SoftColors.blueSoft,
                      borderRadius: BorderRadius.circular(SoftRadius.sm),
                    ),
                    child: Icon(
                      icon,
                      color: alert ? AppColors.rose600 : SoftColors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: SoftType.name),
                        const SizedBox(height: 2),
                        Text(subtitle, style: SoftType.body),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: SoftColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
