import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_haptics.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_typography.dart';
import '../applications/my_applications_screen.dart';
import '../notifications/notifications_screen.dart';
import '../permits/permit_catalog_screen.dart';
import '../profile/profile_screen.dart';
import 'dashboard_screen.dart';

/// Four real tabs (Home, Applications, Notifications, Profile) plus a
/// raised, non-selectable "Apply" pill that opens the Permit Catalog —
/// same interaction shape as the design reference's `RootShell` (bottom
/// nav + a raised control that opens a sheet/screen rather than becoming a
/// fifth selected branch), adapted to eBPCO's actual four sections instead
/// of Teresa's Home/Balita/Events/Profile.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _screens = [
    DashboardScreen(),
    MyApplicationsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  void _onTap(int index) {
    AppHaptics.selection();
    setState(() => _index = index);
  }

  void _openApply() {
    AppHaptics.medium();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PermitCatalogScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openApply,
        backgroundColor: AppColors.primary500,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add),
        label: Text('Apply', style: AppTypography.button),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surface,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 0,
        child: Container(
          decoration: const BoxDecoration(boxShadow: AppShadows.cardHover),
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', selected: _index == 0, onTap: () => _onTap(0)),
              _NavItem(icon: Icons.description_rounded, label: 'Applications', selected: _index == 1, onTap: () => _onTap(1)),
              const SizedBox(width: 48),
              _NavItem(icon: Icons.notifications_rounded, label: 'Alerts', selected: _index == 2, onTap: () => _onTap(2)),
              _NavItem(icon: Icons.person_rounded, label: 'Profile', selected: _index == 3, onTap: () => _onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary600 : AppColors.gray400;
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(label, style: AppTypography.overline.copyWith(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
