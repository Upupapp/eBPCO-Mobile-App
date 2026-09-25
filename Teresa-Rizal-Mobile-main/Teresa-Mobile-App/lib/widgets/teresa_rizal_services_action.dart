import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';
import 'teresa_rizal_nav_motion.dart';

/// Services cradle in the center slot. Wash/soft fill, never a selected
/// tab: it does not take the aperture and it does not use primary blue.
/// The press opens the services sheet.
class TeresaRizalServicesAction extends StatefulWidget {
  final VoidCallback onPressed;

  const TeresaRizalServicesAction({super.key, required this.onPressed});

  @override
  State<TeresaRizalServicesAction> createState() =>
      _TeresaRizalServicesActionState();
}

class _TeresaRizalServicesActionState extends State<TeresaRizalServicesAction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    const settle = TeresaRizalNavMotion.pressRelease;
    _press = AnimationController(
      vsync: this,
      duration:
          TeresaRizalNavMotion.press +
          TeresaRizalNavMotion.pressRelease +
          settle,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1, end: TeresaRizalNavMotion.pressScale),
        weight: TeresaRizalNavMotion.press.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: TeresaRizalNavMotion.pressScale,
          end: TeresaRizalNavMotion.releaseScale,
        ),
        weight: TeresaRizalNavMotion.pressRelease.inMilliseconds.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(begin: TeresaRizalNavMotion.releaseScale, end: 1),
        weight: settle.inMilliseconds.toDouble(),
      ),
    ]).animate(CurvedAnimation(parent: _press, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!TeresaRizalNavMotion.reduced(context)) {
      _press.forward(from: 0);
    }
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Services',
      selected: false,
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('nav-center-action'),
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: SizedBox(
          height:
              TeresaRizalNavMotion.barHeight + TeresaRizalNavMotion.bubbleLift,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                top: TeresaRizalNavMotion.bubbleTop,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    key: const ValueKey('nav-services-cradle'),
                    width: TeresaRizalNavMotion.centerDiameter,
                    height: TeresaRizalNavMotion.centerDiameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SoftColors.blueSoft,
                      border: Border.all(color: SoftColors.line),
                      boxShadow: SoftShadows.cardSm,
                    ),
                    child: const Icon(
                      Icons.grid_view_rounded,
                      color: SoftColors.blue,
                      size: TeresaRizalNavMotion.iconSize,
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 2,
                right: 2,
                bottom: 8,
                child: Text(
                  'Services',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: SoftType.nav,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
