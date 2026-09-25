import 'package:flutter/material.dart';

import '../../theme/soft_widget.dart';
import 'soft_nav_motion.dart';

class NavItemData {
  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;
  final int badge;
  const NavItemData({required this.outlineIcon, required this.filledIcon, required this.label, this.badge = 0});
}

/// The design reference's floating pill nav (`TeresaRizalCurvedNavBar`),
/// in eBPCO red: a blurred 94%-white pill inset from the screen edges, four
/// branch tabs, one raised center control, and a single red bubble that
/// travels to the active tab and carries its filled icon. The center
/// control is never a selected tab — it opens the services sheet.
class SoftNavBar extends StatelessWidget {
  final List<NavItemData> items;
  final int activeIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterPressed;
  final String centerLabel;
  final IconData centerIcon;

  const SoftNavBar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onTabSelected,
    required this.onCenterPressed,
    this.centerLabel = 'Services',
    this.centerIcon = Icons.grid_view_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final reduced = SoftNavMotion.reduced(context);
    final branch = activeIndex < 0 || activeIndex >= items.length ? 0 : activeIndex;
    final active = items[branch];

    // Content scrolling under the tabs fades out above the pill instead of
    // being sliced by its top edge.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          top: -40,
          left: 0,
          right: 0,
          height: 52,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [SoftColors.pageClear, SoftColors.page],
                ),
              ),
            ),
          ),
        ),
        const Positioned.fill(top: 12, child: IgnorePointer(child: ColoredBox(color: SoftColors.page))),
        _bar(context, reduced, branch, active),
      ],
    );
  }

  Widget _bar(BuildContext context, bool reduced, int branch, NavItemData active) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(SoftNavMotion.sideInset, 0, SoftNavMotion.sideInset, SoftNavMotion.bottomInset),
        child: SizedBox(
          height: SoftNavMotion.barHeight + SoftNavMotion.bubbleLift,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final left = SoftNavMotion.bubbleLeft(width: constraints.maxWidth, branchIndex: branch);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: SoftNavMotion.bubbleLift,
                    left: 0,
                    right: 0,
                    height: SoftNavMotion.barHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(SoftNavMotion.surfaceRadius),
                        boxShadow: SoftShadows.nav,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: SoftColors.white,
                          borderRadius: BorderRadius.circular(SoftNavMotion.surfaceRadius),
                          border: Border.all(color: SoftColors.lineSoft),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i == 2)
                          Expanded(child: _CenterAction(label: centerLabel, icon: centerIcon, onPressed: onCenterPressed)),
                        _NavItem(item: items[i], isActive: i == branch, onTap: () => onTabSelected(i)),
                      ],
                    ],
                  ),
                  AnimatedPositioned(
                    duration: SoftNavMotion.selectionFor(context),
                    curve: SoftNavMotion.selectionCurve,
                    left: left,
                    top: SoftNavMotion.bubbleTop,
                    width: SoftNavMotion.bubbleDiameter,
                    height: SoftNavMotion.bubbleDiameter,
                    child: IgnorePointer(child: _ActiveBubble(item: active, reduced: reduced)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({required this.item, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? SoftColors.primary : SoftColors.muted;
    return Expanded(
      child: Semantics(
        label: item.label,
        button: true,
        selected: isActive,
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: SoftNavMotion.barHeight + SoftNavMotion.bubbleLift,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (!isActive)
                  Positioned(
                    top: SoftNavMotion.bubbleLift + SoftNavMotion.iconCenterBelowBarTop - SoftNavMotion.iconSize / 2,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(item.outlineIcon, color: color, size: SoftNavMotion.iconSize),
                          if (item.badge > 0)
                            Positioned(
                              top: -2,
                              right: -3,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: SoftColors.danger,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: SoftColors.white, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  left: 2,
                  right: 2,
                  bottom: SoftNavMotion.labelBottom,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: SoftType.nav.copyWith(color: color, fontWeight: isActive ? FontWeight.w500 : FontWeight.w400),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveBubble extends StatelessWidget {
  final NavItemData item;
  final bool reduced;

  const _ActiveBubble({required this.item, required this.reduced});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: SoftColors.primary, shape: BoxShape.circle, boxShadow: SoftShadows.aperture),
      child: Center(
        child: AnimatedSwitcher(
          duration: reduced ? SoftNavMotion.reducedDuration : SoftNavMotion.selection,
          switchInCurve: SoftNavMotion.selectionCurve,
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: Icon(item.filledIcon, key: ValueKey(item.label), color: SoftColors.white, size: SoftNavMotion.iconSize),
        ),
      ),
    );
  }
}

/// Raised center control on the soft tint — never takes the red bubble.
class _CenterAction extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _CenterAction({required this.label, required this.icon, required this.onPressed});

  @override
  State<_CenterAction> createState() => _CenterActionState();
}

class _CenterActionState extends State<_CenterAction> with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    const settle = SoftNavMotion.pressRelease;
    _press = AnimationController(vsync: this, duration: SoftNavMotion.press + SoftNavMotion.pressRelease + settle);
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: SoftNavMotion.pressScale), weight: SoftNavMotion.press.inMilliseconds.toDouble()),
      TweenSequenceItem(
        tween: Tween(begin: SoftNavMotion.pressScale, end: SoftNavMotion.releaseScale),
        weight: SoftNavMotion.pressRelease.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(tween: Tween(begin: SoftNavMotion.releaseScale, end: 1), weight: settle.inMilliseconds.toDouble()),
    ]).animate(CurvedAnimation(parent: _press, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!SoftNavMotion.reduced(context)) _press.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: SizedBox(
          height: SoftNavMotion.barHeight + SoftNavMotion.bubbleLift,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: SoftNavMotion.bubbleTop,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: SoftNavMotion.centerDiameter,
                    height: SoftNavMotion.centerDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SoftColors.primarySoft,
                      border: Border.all(color: SoftColors.line),
                      boxShadow: SoftShadows.cardSm,
                    ),
                    child: Icon(widget.icon, color: SoftColors.primary, size: SoftNavMotion.iconSize + 2),
                  ),
                ),
              ),
              Positioned(
                left: 2,
                right: 2,
                bottom: SoftNavMotion.labelBottom,
                child: Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: SoftType.nav),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
