import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../theme/g6_tokens.dart';
import 'package:flutter/services.dart';

import '../../../theme/soft_widget.dart';
import '../../../utils/teresa_rizal_seal.dart';
import 'g6_chrome.dart';
import 'g6_sample.dart';

/// 420ms. Spec curve is cubic-bezier(.65, 0, .35, 1), which is 90° at t = 0.5.
/// Flutter's [Curves.easeInOutCubic] is a slightly different cubic.
const kDigitalIdFlipCurve = Cubic(0.65, 0.0, 0.35, 1.0);

/// 420ms easeInOutCubic. Face swap at half, which is 210ms.
const kDigitalIdFlipDuration = Duration(milliseconds: 420);

/// Reduce-motion crossfade. No rotation and no scale.
const kDigitalIdReduceDuration = Duration(milliseconds: 150);

/// Flutter perspective for a 1200px camera: `1 / 1200 ≈ 0.000833`,
/// spec entry (3, 2) = 0.0008.
const kDigitalIdPerspective = 0.0008;

bool g6ReduceMotion(MediaQueryData media) =>
    media.disableAnimations || media.accessibleNavigation;

/// In-session count of completed flips. The hint hides after two.
class DigitalIdFlipHint {
  DigitalIdFlipHint._();
  static int completed = 0;
  static bool get visible => completed < 2;
  static void record() => completed++;
  static void reset() => completed = 0;
}

class DigitalIdCard extends StatefulWidget {
  final DigitalIdData data;
  final bool initiallyBack;
  final VoidCallback? onChanged;

  const DigitalIdCard({
    super.key,
    required this.data,
    this.initiallyBack = false,
    this.onChanged,
  });

  @override
  DigitalIdCardState createState() => DigitalIdCardState();
}

class DigitalIdCardState extends State<DigitalIdCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  bool get showingBack => _controller.value >= 0.5;
  double get linearT => _controller.value;
  bool get isAnimating => _controller.isAnimating;
  bool get headingForward => _controller.status == AnimationStatus.forward;
  bool get reduceMotion => g6ReduceMotion(MediaQuery.of(context));

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
            vsync: this,
            duration: kDigitalIdFlipDuration,
            value: widget.initiallyBack ? 1 : 0,
          )
          ..addListener(() {
            setState(() {});
            widget.onChanged?.call();
          })
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed ||
                status == AnimationStatus.dismissed) {
              DigitalIdFlipHint.record();
            }
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = reduceMotion
        ? kDigitalIdReduceDuration
        : kDigitalIdFlipDuration;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Tap the card or the Front | Back toggle. A tap during the flip
  /// reverses from the current angle. Haptic fires once per tap.
  void flip() {
    HapticFeedback.lightImpact();
    if (_controller.isAnimating) {
      if (_controller.status == AnimationStatus.forward) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
      return;
    }
    if (_controller.value >= 0.5) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _controller.value;
    final eased = kDigitalIdFlipCurve.transform(t);
    final fold = math.sin(eased * math.pi);
    final scale = 1 - 0.04 * fold;
    final blur = 34 - 16 * fold;
    final shade = 0.34 * fold;
    final angle = eased * math.pi;
    final showBack = t >= 0.5;
    final displayAngle = showBack ? angle - math.pi : angle;

    final face = showBack
        ? _IdBack(data: widget.data)
        : _IdFront(data: widget.data);

    final Widget card = reduceMotion
        ? Stack(
            key: const ValueKey('digital-id-flip-fade'),
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 1 - t,
                child: _IdFront(data: widget.data),
              ),
              Opacity(
                opacity: t,
                child: _IdBack(data: widget.data),
              ),
            ],
          )
        : Transform(
            key: const ValueKey('digital-id-flip-3d'),
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, kDigitalIdPerspective)
              ..rotateY(displayAngle),
            child: Transform.scale(
              scale: scale,
              child: Stack(
                children: [
                  face,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              G6Palette.navyClear,
                              Color.fromRGBO(10, 24, 70, shade),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

    return Semantics(
      button: true,
      label: 'Digital ID card, double-tap to flip',
      child: GestureDetector(
        key: const ValueKey('digital-id-card'),
        behavior: HitTestBehavior.opaque,
        onTap: flip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: SoftColors.cardShadow,
                blurRadius: blur,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: card,
        ),
      ),
    );
  }
}

class DigitalIdStage extends StatelessWidget {
  final DigitalIdData data;
  final bool initiallyBack;
  final bool showElapsed;
  final GlobalKey<DigitalIdCardState>? cardKey;

  /// Fires on every animation tick so a parent can mirror the flip clock.
  final VoidCallback? onTick;

  const DigitalIdStage({
    super.key,
    required this.data,
    this.initiallyBack = false,
    this.showElapsed = true,
    this.cardKey,
    this.onTick,
  });

  @override
  Widget build(BuildContext context) {
    return _StageBody(
      data: data,
      initiallyBack: initiallyBack,
      showElapsed: showElapsed,
      cardKey: cardKey,
      onTick: onTick,
    );
  }
}

class _StageBody extends StatefulWidget {
  final DigitalIdData data;
  final bool initiallyBack;
  final bool showElapsed;
  final GlobalKey<DigitalIdCardState>? cardKey;
  final VoidCallback? onTick;

  const _StageBody({
    required this.data,
    required this.initiallyBack,
    required this.showElapsed,
    required this.cardKey,
    required this.onTick,
  });

  @override
  State<_StageBody> createState() => _StageBodyState();
}

class _StageBodyState extends State<_StageBody> {
  late final GlobalKey<DigitalIdCardState> _key =
      widget.cardKey ?? GlobalKey<DigitalIdCardState>();

  void _flip() => _key.currentState?.flip();

  @override
  Widget build(BuildContext context) {
    final state = _key.currentState;
    final showingBack = state?.showingBack ?? widget.initiallyBack;
    final running = state != null && state.isAnimating;
    final ms = ((state?.linearT ?? (widget.initiallyBack ? 1 : 0)) * 420)
        .round();
    final towardBack = running ? state.headingForward : !showingBack;
    final hint = running
        ? 'Flipping to ${towardBack ? 'back' : 'front'} · $ms / 420ms'
        : (showingBack
              ? 'Tap the card to flip back'
              : 'Tap the card to flip · QR is on the back');

    return Column(
      children: [
        Row(
          children: [
            const Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _VerifiedPill(),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _FaceToggle(showingBack: showingBack, onFlip: _flip),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Semantics(
          container: true,
          liveRegion: true,
          label: showingBack ? 'Showing back of card' : 'Showing front of card',
          child: const SizedBox(width: double.infinity, height: 1),
        ),
        AspectRatio(
          aspectRatio: 358 / 226,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: G6DashedBox(
                  color: SoftColors.apertureShadow,
                  radius: 20,
                  child: SizedBox.expand(),
                ),
              ),
              Positioned.fill(
                child: DigitalIdCard(
                  key: _key,
                  data: widget.data,
                  initiallyBack: widget.initiallyBack,
                  onChanged: () {
                    setState(() {});
                    widget.onTick?.call();
                  },
                ),
              ),
            ],
          ),
        ),
        if (widget.showElapsed && (running || DigitalIdFlipHint.visible)) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.autorenew_rounded,
                size: 14,
                color: running ? SoftColors.blueDeep : SoftColors.blue,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: G6Type.px12,
                    fontWeight: FontWeight.w400,
                    color: running ? SoftColors.blueDeep : SoftColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _VerifiedPill extends StatelessWidget {
  const _VerifiedPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: SoftColors.verifiedSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: SoftColors.verifiedInk,
              shape: BoxShape.circle,
            ),
            child: SizedBox(width: 6, height: 6),
          ),
          SizedBox(width: 6),
          Text(
            'Verified resident',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: G6Type.px11,
              fontWeight: FontWeight.w500,
              color: SoftColors.verifiedInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _FaceToggle extends StatelessWidget {
  final bool showingBack;
  final VoidCallback onFlip;
  const _FaceToggle({required this.showingBack, required this.onFlip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: SoftColors.line),
        boxShadow: SoftShadows.cardSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_seg('Front', !showingBack), _seg('Back', showingBack)],
      ),
    );
  }

  Widget _seg(String label, bool on) {
    return GestureDetector(
      onTap: on ? null : onFlip,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? SoftColors.blue : SoftColors.clear,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: G6Type.px12,
            fontWeight: FontWeight.w500,
            color: on ? SoftColors.white : SoftColors.muted,
          ),
        ),
      ),
    );
  }
}

class _IdFront extends StatelessWidget {
  final DigitalIdData data;
  const _IdFront({required this.data});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const RadialGradient(
          center: Alignment(1, -1),
          radius: 1.2,
          colors: [G6Palette.liveGlow, SoftColors.clear],
          stops: [0, 0.6],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: SoftColors.featureGradient,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipOval(
                          child: Image.asset(
                            teresaRizalSealAsset,
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Municipality of Teresa, Rizal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: G6Type.px10,
                                  fontWeight: FontWeight.w400,
                                  color: G6Palette.white85,
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Resident Digital ID',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: G6Type.px13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: -0.2,
                                  color: SoftColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: SoftColors.gold,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: const Text(
                            'MOCK',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: G6Type.px10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: G6Palette.mockInk,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final row = Row(
                            children: [
                              const _PhotoSlot(),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Name',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: G6Type.px10,
                                        color: G6Palette.white78,
                                      ),
                                    ),
                                    Text(
                                      data.holderName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: G6Type.px16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.4,
                                        height: 1.15,
                                        color: SoftColors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Resident ID',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: G6Type.px9_5,
                                        color: G6Palette.white76,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            data.residentId,
                                            key: const ValueKey(
                                              'digital-id-resident-id',
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: G6Type.px12,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.4,
                                              color: SoftColors.white,
                                            ),
                                          ),
                                        ),
                                        if (data.sampleTagged) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: G6Palette.white18,
                                              borderRadius:
                                                  BorderRadius.circular(99),
                                            ),
                                            child: const Text(
                                              'SAMPLE',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: G6Type.px9,
                                                fontWeight: FontWeight.w500,
                                                color: SoftColors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _mini(
                                            'Barangay',
                                            data.barangay,
                                          ),
                                        ),
                                        Expanded(
                                          child: _mini(
                                            'Valid until',
                                            G6Sample.validUntil,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                          // The name block needs ~136px. A short card scales
                          // that height; the 390-wide frame still lays out at 1:1.
                          const designHeight = 136.0;
                          if (constraints.maxHeight >= designHeight) return row;
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomLeft,
                            child: SizedBox(
                              width: constraints.maxWidth,
                              height: designHeight,
                              child: row,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 28,
                child: ColoredBox(
                  color: G6Palette.navyStrip,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 12,
                        color: G6Palette.white92,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Mock card, not a government ID · sample data',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: G6Type.px10,
                            fontWeight: FontWeight.w500,
                            color: G6Palette.white92,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: G6Type.px9_5,
            color: G6Palette.white76,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: G6Type.px12,
            fontWeight: FontWeight.w500,
            color: SoftColors.white,
          ),
        ),
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: G6DashedBox(
        color: G6Palette.white62,
        radius: 12,
        fill: G6Palette.white8,
        child: const SizedBox(
          height: 92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 22,
                color: G6Palette.white86,
              ),
              SizedBox(height: 4),
              Text(
                'Photo\nslot',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: G6Type.px10,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                  color: G6Palette.white86,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdBack extends StatelessWidget {
  final DigitalIdData data;
  const _IdBack({required this.data});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SoftColors.line),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SoftColors.white, SoftColors.blueWash],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _QrSlot(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Address'),
                        Text(
                          data.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: G6Type.px12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                            color: SoftColors.ink,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _label('Emergency contact'),
                        Text(
                          '${data.emergencyName} · ${data.emergencyRole}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: G6Type.px12,
                            fontWeight: FontWeight.w500,
                            color: SoftColors.ink,
                          ),
                        ),
                        Text(
                          data.emergencyPhone,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: G6Type.px12,
                            color: SoftColors.muted,
                          ),
                        ),
                        const SizedBox(height: 7),
                        _label('Blood type'),
                        const Row(
                          children: [
                            Text(
                              G6Sample.bloodType,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: G6Type.px12,
                                fontWeight: FontWeight.w500,
                                color: SoftColors.ink,
                              ),
                            ),
                            SizedBox(width: 4),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: G6Palette.cream,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(99),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                child: Text(
                                  'SAMPLE',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: G6Type.px9,
                                    fontWeight: FontWeight.w500,
                                    color: SoftColors.endedInk,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 16,
              right: 16,
              bottom: 32,
              child: Text(
                'Issued 25 Sep 2026 · sample',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: G6Type.px10,
                  color: SoftColors.muted,
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 28,
              child: ColoredBox(
                color: G6Palette.cream,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 12,
                      color: G6Palette.goldInk,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Mock card, not a government ID · QR is a placeholder',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: G6Type.px10,
                          fontWeight: FontWeight.w500,
                          color: G6Palette.goldInk,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: G6Type.px9_5,
        color: SoftColors.muted,
      ),
    );
  }
}

class _QrSlot extends StatelessWidget {
  const _QrSlot();

  @override
  Widget build(BuildContext context) {
    return G6DashedBox(
      radius: 12,
      fill: SoftColors.white,
      child: const SizedBox(
        width: 104,
        height: 104,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 24,
              color: SoftColors.blue,
            ),
            SizedBox(height: 4),
            Text(
              'QR slot',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: G6Type.px10,
                fontWeight: FontWeight.w500,
                color: SoftColors.muted,
              ),
            ),
            SizedBox(height: 4),
            DecoratedBox(
              decoration: BoxDecoration(
                color: G6Palette.cream,
                borderRadius: BorderRadius.all(Radius.circular(99)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                child: Text(
                  'Sample only',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: G6Type.px9,
                    fontWeight: FontWeight.w500,
                    color: SoftColors.endedInk,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
