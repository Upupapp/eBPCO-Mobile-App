import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_elevation.dart';
import '../theme/app_haptics.dart';
import '../theme/app_typography.dart';
import 'teresa_rizal_nav_motion.dart';

/// Destinations opened from the Services hub. Dokyu and Tulong are
/// verified-only. Emergency is signed-in (unverified is enough).
enum ServiceLauncherTarget {
  dokyu(label: 'Dokyu', icon: Icons.description_rounded, accent: AppColors.brand500),
  tulong(label: 'Tulong', icon: Icons.volunteer_activism_rounded, accent: AppColors.purple500),
  emergency(label: 'Emergency', icon: Icons.shield_rounded, accent: AppColors.rose600);

  const ServiceLauncherTarget({required this.label, required this.icon, required this.accent});

  final String label;
  final IconData icon;
  final Color accent;
}

/// The center "+" launcher's expansion — two floating circular bubbles for
/// Dokyu and Tulong that pop out directly above the "+", styled exactly
/// like a tab's own raised active bubble (see TeresaRizalActiveBubble: filled
/// circle, white border ring, colored drop shadow) and driven by the same
/// motion constants as the rest of the navbar (TeresaRizalNavMotion), rather
/// than a modal bottom sheet.
///
/// Servana's own central action (ServanaBookAction, in design_reference/
/// ServanaClientAPP-main) opens a modal sheet too — there is no floating-
/// bubble expansion component anywhere in that source to port verbatim.
/// This widget instead extends Servana's own bubble/shadow/motion language
/// (the same one TeresaRizalActiveBubble and TeresaRizalCenterAction already
/// use) into a compact two-bubble expansion attached to the navbar, per
/// the explicit product requirement that the launcher must read as part of
/// the navbar's own floating-circle system rather than a separate panel.
class ServiceLauncherMenu {
  ServiceLauncherMenu._();

  static _ServiceLauncherBubblesState? _openState;

  /// True while the expansion is on screen.
  static bool get isOpen => _openState != null;

  static void show(BuildContext context, {required ValueChanged<ServiceLauncherTarget> onSelect}) {
    if (_openState != null) return;
    AppHaptics.medium();

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ServiceLauncherBubbles(
        onSelect: onSelect,
        onDismissed: () {
          entry.remove();
          _openState = null;
        },
      ),
    );
    overlay.insert(entry);
  }

  /// Closes the expansion without selecting anything — used when the "+"
  /// is tapped again while already open, so the button acts as a toggle.
  static void dismiss() => _openState?.dismiss();
}

class _ServiceLauncherBubbles extends StatefulWidget {
  final ValueChanged<ServiceLauncherTarget> onSelect;
  final VoidCallback onDismissed;
  const _ServiceLauncherBubbles({required this.onSelect, required this.onDismissed});

  @override
  State<_ServiceLauncherBubbles> createState() => _ServiceLauncherBubblesState();
}

class _ServiceLauncherBubblesState extends State<_ServiceLauncherBubbles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Duration fixed here at a default and refined once MediaQuery is
    // available in didChangeDependencies (not usable in initState).
    _controller = AnimationController(vsync: this, duration: TeresaRizalNavMotion.selection);
    ServiceLauncherMenu._openState = this;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _controller.duration = TeresaRizalNavMotion.selectionFor(context);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    // A State must not leave a static pointing at itself once disposed.
    // _openState was previously cleared only on the two dismiss paths, so a
    // disposal that skipped them left it dangling - after which show()
    // early-returns for ever (its guard is `_openState != null`) and dismiss()
    // calls reverse() on a disposed controller.
    //
    // Honest scope: this was found by a widget test's tearDown, and NO user
    // path to it has been demonstrated. The app has a single MaterialApp and
    // one root navigator, and this entry is inserted with `rootOverlay: true`,
    // so signing out navigates underneath the entry rather than disposing it;
    // the scrim also swallows every tap, so the menu cannot be left open while
    // something else navigates. The fix is here because the invariant should
    // hold regardless of whether today's tree happens to reach it - it costs
    // one line, and the failure mode is a permanently dead "+".
    //
    // `== this` rather than an unconditional null, so an older menu's teardown
    // never clears a newer one that has already claimed the slot.
    if (ServiceLauncherMenu._openState == this) ServiceLauncherMenu._openState = null;
    _controller.dispose();
    super.dispose();
  }

  Future<void> dismiss() async {
    if (ServiceLauncherMenu._openState != this) return;
    ServiceLauncherMenu._openState = null;
    // Between deactivate and dispose the State is unmounted but still the
    // registered one; the controller may already be gone.
    if (!mounted) return;
    await _controller.reverse().orCancel.catchError((_) {});
    if (mounted) widget.onDismissed();
  }

  Future<void> _select(ServiceLauncherTarget target) async {
    AppHaptics.selection();
    widget.onSelect(target);
    await dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafeInset = MediaQuery.paddingOf(context).bottom;
    // Sits just above the floating "+" itself (which pokes up
    // centerDiameter/2 above the bar's top edge) rather than above the bar
    // alone, so the bubbles never overlap the button that opened them.
    final clearance =
        bottomSafeInset + TeresaRizalNavMotion.barHeight + TeresaRizalNavMotion.centerDiameter / 2 + 14;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: dismiss,
                // A light tint, not a covering panel — just enough to read
                // as "this is momentarily the focus" without darkening the
                // screen the way a modal barrier would.
                child: Container(color: Colors.black.withValues(alpha: 0.12 * t)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: clearance,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LauncherBubble(
                      target: ServiceLauncherTarget.dokyu,
                      controller: _controller,
                      interval: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
                      onTap: () => _select(ServiceLauncherTarget.dokyu),
                    ),
                    const SizedBox(width: 28),
                    _LauncherBubble(
                      target: ServiceLauncherTarget.tulong,
                      controller: _controller,
                      interval: const Interval(0.12, 1.0, curve: Curves.easeOutCubic),
                      onTap: () => _select(ServiceLauncherTarget.tulong),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LauncherBubble extends StatelessWidget {
  final ServiceLauncherTarget target;
  final AnimationController controller;
  final Interval interval;
  final VoidCallback onTap;

  const _LauncherBubble({required this.target, required this.controller, required this.interval, required this.onTap});

  static const double _diameter = TeresaRizalNavMotion.bubbleDiameter;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: controller, curve: interval);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        final t = curved.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.5 + 0.5 * t, child: child),
        );
      },
      child: Semantics(
        button: true,
        label: target.label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: _diameter,
                height: _diameter,
                decoration: BoxDecoration(
                  color: target.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 3),
                  boxShadow: [
                    BoxShadow(color: target.accent.withValues(alpha: 0.30), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Icon(target.icon, color: Colors.white, size: TeresaRizalNavMotion.iconSize),
              ),
              const SizedBox(height: 6),
              // The label carries its own background, for the same reason the
              // bubble above carries a white ring: the scrim behind this menu
              // is a deliberate 12% tint rather than a modal barrier, so
              // whatever the citizen was reading stays visible underneath —
              // and on Home that is a full-bleed event poster. Observed on a
              // device 2026-08-30: brand-blue "Dokyu" and "Tulong" rendered
              // straight onto a dark photograph, over the poster's own white
              // text. Unreadable, and it looked like a rendering fault.
              //
              // Backing the label rather than darkening the scrim keeps that
              // original decision intact: the menu still reads as a light
              // overlay, and the labels no longer depend on what is behind
              // them.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(color: AppElevation.tabPillShadow, blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Text(
                  target.label,
                  style: const TextStyle(
                    fontFamily: AppTypography.sans,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    // Teresa, Rizal primary blue — the same color the navbar's
                    // own active-tab label uses (TeresaRizalNavItem._activeColor)
                    // — not textPrimary (navy, reads as near-black). Both
                    // Dokyu and Tulong always use this, regardless of which
                    // one is currently active.
                    color: AppColors.brand500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
