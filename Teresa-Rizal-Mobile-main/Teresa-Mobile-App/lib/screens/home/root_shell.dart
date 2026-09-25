import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/access_level.dart';
import '../../services/citizen_session_service.dart';
import '../../services/notification_feed.dart';
import '../../services/notifications_service.dart';
import '../../theme/app_haptics.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/access_guard.dart';
import '../../widgets/teresa_rizal_curved_navbar.dart';
import '../../widgets/nav_item_data.dart';
import '../../widgets/promotional_banner_dialog.dart';
import '../../widgets/service_launcher_menu.dart';
import '../../data/catalog_gate_policy.dart';
import '../../screens/catalog/dokyu_catalog_screen.dart';
import '../../screens/catalog/sakuna_catalog_screen.dart';
import '../../screens/catalog/tulong_catalog_screen.dart';
import '../../widgets/services_sheet.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/teresa_rizal_drawer.dart';
import '../balita/balita_screen.dart';
import '../dokyu/dokyu_screen.dart';
import '../events/events_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../sakuna/sakuna_screen.dart';
import '../services/services_hub_screen.dart';
import '../tulong/tulong_screen.dart';
import 'home_screen.dart';

/// Four branches: Home, Balita, Events, Profile. Services is a raised
/// control that opens a sheet (Dokyu, Tulong, Emergency). It never becomes
/// the selected branch. Dokyu and Tulong require Verified. Emergency
/// requires signed-in (Unverified is enough).
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  static final GlobalKey<_RootShellState> _key = GlobalKey<_RootShellState>();

  /// Home=0, Balita=1, Events=2, Profile=3. Out of range lands on Home.
  /// This is a user gesture, so it haptics. Restore paths should assign
  /// the branch without calling this.
  static void jumpTo(BuildContext context, int index) {
    _key.currentState?.onBranchTap(index);
  }

  /// Opens the Services sheet. Does not change the selected branch.
  static void showServices(BuildContext context) {
    final state = _key.currentState;
    if (state == null || !state.mounted) return;
    state._showServicesSheet();
  }

  /// Dokyu, Tulong, or Emergency. Duplicate verified accounts are turned
  /// away from Dokyu and Tulong here, before the AccessGuard screen.
  /// The selected branch stays where it was.
  static void openService(BuildContext context, ServiceLauncherTarget target) {
    _key.currentState?.openService(target);
  }

  /// Catalog browse. [policy] overrides the const for tests of both modes.
  static void openCatalog(
    BuildContext context,
    ServiceLauncherTarget target, {
    CatalogGatePolicy? policy,
  }) {
    _key.currentState?.openCatalog(target, policy: policy);
  }

  /// The services list, still not a tab. The selected branch stays put.
  static void openServicesHub(BuildContext context) {
    _key.currentState?.openServicesHub();
  }

  /// Returns from a service body to the Services hub.
  static void closeService(BuildContext context) {
    _key.currentState?.openServicesHub(fromBack: true);
  }

  /// Opens the menu sheet above the shell, including the floating pill.
  static void openDrawer(BuildContext context) {
    final state = _key.currentState;
    final host = (state != null && state.mounted) ? state.context : context;
    showTeresaRizalMenu(host);
  }

  @override
  State<RootShell> createState() => _RootShellState();

  static RootShell withKey() => RootShell(key: _key);
}

class _RootShellState extends State<RootShell> {
  /// Home=0, Balita=1, Events=2, Profile=3. Never the Services control.
  int _branch = 0;
  int _bodyIndex = 0;

  // Home=0, Balita=1, Events=2, Services hub=3, Profile=4, Dokyu=5,
  // Tulong=6, Emergency=7. Hub and services are bodies, not branches.
  final _screens = const [
    HomeScreen(),
    BalitaScreen(),
    EventsScreen(),
    ServicesHubScreen(),
    ProfileScreen(),
    AccessGuard(
      required: AccessLevel.verified,
      featureName: 'Dokyu (Document Requests)',
      child: DokyuScreen(),
    ),
    AccessGuard(
      required: AccessLevel.verified,
      featureName: 'Tulong (Assistance Requests)',
      child: TulongScreen(),
    ),
    AccessGuard(
      required: AccessLevel.unverified,
      featureName: 'Risk Reduction & Emergency',
      child: SakunaScreen(),
    ),
  ];

  static const _branchBody = {0: 0, 1: 1, 2: 2, 3: 4};

  final _bannerOffered = <int>{};

  // Emergency is deliberately absent. A full-screen popup over Risk
  // Reduction covers the 911 / MDRRMO line and the evacuation list.
  // Balita, Events, Dokyu, and Tulong each have a once-per-session flag
  // in [_bannerOffered]. Home's flag lives on HomeScreen. The dialog
  // paints an empty portrait slot. No poster PNG is passed.
  static const _bannerSlots = <int, (String, AccessLevel)>{
    1: ('Balita', AccessLevel.guest),
    2: ('Events', AccessLevel.guest),
    5: ('Dokyu', AccessLevel.verified),
    6: ('Tulong', AccessLevel.verified),
  };

  void _maybeShowBanner(int bodyIndex) {
    final entry = _bannerSlots[bodyIndex];
    if (entry == null || _bannerOffered.contains(bodyIndex)) return;
    final (label, required) = entry;
    if (context.read<CitizenSessionService>().accessLevel.index <
        required.index) {
      return;
    }
    _bannerOffered.add(bodyIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PromotionalBannerDialog.show(context, label: label);
      }
    });
  }

  static const _items = [
    NavItemData(
      outlineIcon: Icons.home_outlined,
      filledIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavItemData(
      outlineIcon: Icons.campaign_outlined,
      filledIcon: Icons.campaign_rounded,
      label: 'Balita',
    ),
    NavItemData(
      outlineIcon: Icons.event_outlined,
      filledIcon: Icons.event_rounded,
      label: 'Events',
    ),
    NavItemData(
      outlineIcon: Icons.person_outline_rounded,
      filledIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  /// User tap on a branch. A different branch gets a selection haptic.
  /// Reselect pops a covering route, or leaves a service body, and only
  /// then fires a light haptic. Already at that branch root: no haptic.
  void onBranchTap(int i) {
    final index = (i < 0 || i > 3) ? 0 : i;
    final body = _branchBody[index]!;
    if (index == _branch && _bodyIndex == body) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        AppHaptics.light();
        navigator.pop();
      }
      return;
    }
    if (index == _branch) {
      AppHaptics.light();
      setState(() => _bodyIndex = body);
      _maybeShowBanner(body);
      return;
    }
    AppHaptics.selection();
    setState(() {
      _branch = index;
      _bodyIndex = body;
    });
    _maybeShowBanner(body);
  }

  void _showServicesSheet() {
    ServicesSheet.show(context, onService: openCatalog);
  }

  /// Browse catalogs. A duplicate account is not stopped here — the intercept
  /// fires at Start request. [policy] lets tests exercise the one-line
  /// hub-restricted flip without changing [kCatalogGatePolicy].
  void openCatalog(ServiceLauncherTarget target, {CatalogGatePolicy? policy}) {
    final entry = catalogEntryFor(target.name, policy ?? currentCatalogGatePolicy());
    if (entry == CatalogEntry.guardedRequestList) {
      openService(target);
      return;
    }
    AppHaptics.selection();
    final page = switch (entry) {
      CatalogEntry.dokyuCatalog => const DokyuCatalogScreen(),
      CatalogEntry.tulongCatalog => const TulongCatalogScreen(),
      CatalogEntry.sakunaCatalog => const SakunaCatalogScreen(),
      CatalogEntry.guardedRequestList => const SizedBox.shrink(),
    };
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void openServicesHub({bool fromBack = false}) {
    if (!fromBack) AppHaptics.selection();
    setState(() => _bodyIndex = 3);
  }

  void openService(ServiceLauncherTarget target) {
    AppHaptics.selection();
    final body = switch (target) {
      ServiceLauncherTarget.dokyu => 5,
      ServiceLauncherTarget.tulong => 6,
      ServiceLauncherTarget.emergency => 7,
    };
    setState(() => _bodyIndex = body);
    _maybeShowBanner(body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: SoftPageWipe(index: _bodyIndex, children: _screens),
      bottomNavigationBar: TeresaRizalCurvedNavBar(
        items: _items,
        activeIndex: _branch,
        onTabSelected: onBranchTap,
        onCenterPressed: _showServicesSheet,
      ),
    );
  }
}

/// Shared top-right alerts button.
class AlertsAction extends StatelessWidget {
  final Color? color;
  final double tapTarget;
  const AlertsAction({
    super.key,
    this.color,
    this.tapTarget = SoftCircleButton.diameter,
  });

  @override
  Widget build(BuildContext context) {
    final feed = buildNotificationFeed(context);
    final service = context.watch<NotificationsService>();
    final unread = feed.where((n) => !service.isRead(n.id)).length;
    final iconColor = color ?? SoftColors.ink;
    final inset = (tapTarget - SoftCircleButton.diameter) / 2;
    final badge = unread > 9 ? '9+' : '$unread';

    return Semantics(
      label: unread > 0 ? 'Alerts, $badge unread' : 'Alerts',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SoftCircleButton(
            icon: Icons.notifications_outlined,
            tooltip: 'Alerts',
            iconColor: iconColor,
            tapTarget: tapTarget,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            ),
          ),
          if (unread > 0)
            Positioned(
              top: inset - 2,
              right: inset - 6,
              child: IgnorePointer(
                child: Container(
                  key: const ValueKey('alerts-unread-count'),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SoftColors.danger,
                    borderRadius: BorderRadius.circular(SoftRadius.pill),
                    border: Border.all(color: SoftColors.white, width: 1.5),
                  ),
                  child: Text(
                    badge,
                    style: SoftType.cellLabel.copyWith(
                      color: SoftColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BrandIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  const BrandIconBox({super.key, required this.icon, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: SoftColors.blueSoft,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, size: size * 0.45, color: SoftColors.blue),
    );
  }
}
