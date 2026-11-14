import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/permit_catalog.dart';
import '../../services/applications_service.dart';
import '../../services/earlier_records_service.dart';
import '../../services/live_updates.dart';
import '../../services/notifications_service.dart';
import '../../services/push_service.dart';
import '../../services/session_service.dart';
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

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _index = 0;

  /// Asks the server about once a second what changed, while this shell is
  /// up (signed in) and the app is in the foreground. Null only in a test
  /// that provides none.
  LiveUpdates? _live;

  /// Changed on the server while no tab listing them was on screen; read
  /// again once one is (hidden tabs are not refreshed as things change).
  bool _applicationsStale = false;
  bool _earlierRecordsStale = false;

  static const _screens = [
    DashboardScreen(),
    MyApplicationsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _live = context.read<LiveUpdates?>()?..addListener(_onLiveChange);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle == null || lifecycle == AppLifecycleState.resumed || lifecycle == AppLifecycleState.inactive) {
      _live?.start();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsService>().refresh();
      final tapped = PushService.instance.takePending();
      if (tapped != null) PushService.instance.onOpen?.call(tapped);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _live
      ?..removeListener(_onLiveChange)
      ..stop();
    super.dispose();
  }

  /// Checks only while the app is on screen; back on screen, check at once.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _live?.start();
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _live?.stop();
      case AppLifecycleState.inactive:
        // Still on screen: a system sheet over it, or the other half of a
        // split screen.
        break;
    }
  }

  /// Something changed on the server. Read again, keeping what is on screen
  /// meanwhile: the notifications (the badge shows on every tab) and the
  /// account (Home, Profile and the wizard read it) at once; the
  /// applications only for the tab on screen, any other tab once it is
  /// opened. An open application or Payments page reads its own.
  void _onLiveChange() {
    final changed = _live!.changed;
    if (changed.contains(LiveTopic.notifications)) context.read<NotificationsService>().refreshQuietly();
    if (changed.contains(LiveTopic.account)) context.read<SessionService>().refreshProfile().catchError((_) {});
    if (changed.contains(LiveTopic.applications) || changed.contains(LiveTopic.payments)) _applicationsStale = true;
    // The permits from before eBPCO an officer matched to the account (069).
    if (changed.contains(LiveTopic.applications) || changed.contains(LiveTopic.account)) _earlierRecordsStale = true;
    _refreshShownTab();
  }

  /// Home and Applications list the applications; Applications also lists
  /// the earlier permits. Alerts and Profile read what is refreshed at once.
  void _refreshShownTab() {
    if (_applicationsStale && (_index == 0 || _index == 1)) {
      _applicationsStale = false;
      context.read<ApplicationsService>().refreshQuietly();
    }
    if (_earlierRecordsStale && _index == 1) {
      _earlierRecordsStale = false;
      context.read<EarlierRecordsService>().refresh();
    }
  }

  void _onTap(int index) {
    if (index == _index) return;
    AppHaptics.selection();
    setState(() => _index = index);
    _refreshShownTab();
  }

  void _push(Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _openServices() {
    AppHaptics.medium();
    showServicesSheet(context, [
      ServiceEntry(
        icon: Icons.add_circle_outline_rounded,
        title: 'Apply for a Permit',
        // Counted from the catalog: the FSEC and FSIC left it (the BFP issues them).
        subtitle: '$offeredPermitTypeCount permit types · start or resume',
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
    // System Back on another tab returns to Home first; only Home leaves the app.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onTap(0);
      },
      child: Scaffold(
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
      ),
    );
  }
}
