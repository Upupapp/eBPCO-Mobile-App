import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/notifications_service.dart';
import '../../theme/app_haptics.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/nav/soft_nav_bar.dart';
import '../../widgets/services_sheet.dart';
import '../../widgets/soft_chrome.dart';
import '../applications/my_applications_screen.dart';
import '../business/business_list_screen.dart';
import '../documents/my_documents_screen.dart';
import '../notifications/notifications_screen.dart';
import '../payments/payments_list_screen.dart';
import '../permits/permit_catalog_screen.dart';
import '../profile/profile_screen.dart';
import 'dashboard_screen.dart';

/// Four branches (Home, Applications, Alerts, Profile) on the design
/// reference's floating pill, plus the raised center Services control that
/// opens a sheet and never becomes a selected branch — the same interaction
/// shape as the reference's `RootShell`, carrying eBPCO's own sections.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  /// Lets any descendant switch branch (e.g. the dashboard's "View all").
  static void jumpTo(BuildContext context, int index) => context.findAncestorStateOfType<_RootShellState>()?._onTap(index);

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<NotificationsService>().refresh());
  }

  void _onTap(int index) {
    if (index == _index) return;
    AppHaptics.selection();
    setState(() => _index = index);
  }

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _openServices() {
    AppHaptics.medium();
    showServicesSheet(context, [
      ServiceEntry(
        icon: Icons.add_circle_outline_rounded,
        title: 'Apply for a Permit',
        subtitle: '17 permit types · start or resume',
        onTap: () => _push(const PermitCatalogScreen()),
      ),
      ServiceEntry(
        icon: Icons.storefront_outlined,
        title: 'My Businesses',
        subtitle: 'Register and manage your businesses',
        onTap: () => _push(const BusinessListScreen()),
      ),
      ServiceEntry(
        icon: Icons.payments_outlined,
        title: 'Payments',
        subtitle: 'Orders of Payment and submissions',
        onTap: () => _push(const PaymentsListScreen()),
      ),
      ServiceEntry(
        icon: Icons.folder_outlined,
        title: 'My Documents',
        subtitle: 'Everything you have uploaded',
        onTap: () => _push(const MyDocumentsScreen()),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<NotificationsService>().unreadCount;
    return Scaffold(
      backgroundColor: SoftColors.page,
      extendBody: true,
      body: SoftPageWipe(index: _index, children: _screens),
      bottomNavigationBar: SoftNavBar(
        activeIndex: _index,
        onTabSelected: _onTap,
        onCenterPressed: _openServices,
        items: [
          const NavItemData(outlineIcon: Icons.home_outlined, filledIcon: Icons.home_rounded, label: 'Home'),
          const NavItemData(outlineIcon: Icons.assignment_outlined, filledIcon: Icons.assignment_rounded, label: 'Applications'),
          NavItemData(outlineIcon: Icons.notifications_outlined, filledIcon: Icons.notifications_rounded, label: 'Alerts', badge: unread),
          const NavItemData(outlineIcon: Icons.account_circle_outlined, filledIcon: Icons.account_circle_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}
