import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';
import 'teresa_rizal_nav_motion.dart';

enum SoftStatusTone { guest, pending, verified }

/// 28px status pill. Verified is green, Guest is gray, anything still
/// awaiting LGU review stays gold so it never reads as verified.
class SoftStatusPill extends StatelessWidget {
  final String label;
  final SoftStatusTone tone;

  /// Full width of the parent. Profile sets this false so the pill hugs
  /// the label instead of stretching across the identity block.
  final bool expand;

  const SoftStatusPill({
    super.key,
    required this.label,
    required this.tone,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      SoftStatusTone.guest => (SoftColors.chipWash, SoftColors.muted),
      SoftStatusTone.pending => (SoftColors.pendingCream, SoftColors.pendingInk),
      SoftStatusTone.verified => (
        SoftColors.verifiedSoft,
        SoftColors.verifiedInk,
      ),
    };
    final labelText = Text(
      label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: SoftType.cellLabel.copyWith(
        color: foreground,
        fontWeight: FontWeight.w500,
        fontSize: 12,
      ),
    );
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          if (expand) Expanded(child: labelText) else labelText,
        ],
      ),
    );
  }
}

/// Initials disc for shell chrome. Guest is muted, a review account is gold,
/// and a verified account is Teresa blue. White initials, Inter 600.
class SoftInitialAvatar extends StatelessWidget {
  final String initials;
  final SoftStatusTone tone;
  final double size;

  const SoftInitialAvatar({
    super.key,
    required this.initials,
    required this.tone,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      SoftStatusTone.guest => SoftColors.muted,
      SoftStatusTone.pending => SoftColors.gold,
      SoftStatusTone.verified => SoftColors.blue,
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: SoftShadows.avatar,
      ),
      child: Text(
        initials,
        style: SoftType.cellValue.copyWith(
          color: SoftColors.white,
          fontWeight: FontWeight.w600,
          fontSize: size < 40 ? 13 : 14,
        ),
      ),
    );
  }
}

enum SoftPillKind { primary, outline, danger, dangerSoft, text }

/// Pill used by the menu sheet, the guest gate, and the home account cards.
/// Outline and danger-soft stay off the selected-tab blue fill.
class SoftPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SoftPillKind kind;

  const SoftPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = SoftPillKind.primary,
  });

  @override
  Widget build(BuildContext context) {
    final (background, foreground, border) = switch (kind) {
      SoftPillKind.primary => (SoftColors.blue, SoftColors.white, null),
      SoftPillKind.outline => (
        SoftColors.white,
        SoftColors.blue,
        SoftColors.line,
      ),
      SoftPillKind.danger => (SoftColors.danger, SoftColors.white, null),
      SoftPillKind.dangerSoft => (
        SoftColors.dangerSoft,
        SoftColors.danger,
        null,
      ),
      SoftPillKind.text => (SoftColors.clear, SoftColors.blue, null),
    };
    final vertical = kind == SoftPillKind.text ? 10.0 : 14.0;
    Widget button = Material(
      color: background,
      elevation: 0,
      shadowColor: SoftColors.clear,
      surfaceTintColor: SoftColors.clear,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: vertical),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: border == null ? null : Border.all(color: border),
          ),
          child: Text(
            label,
            style: SoftType.cellValue.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
    if (kind == SoftPillKind.primary) {
      button = DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(SoftRadius.pill)),
          boxShadow: SoftShadows.primary,
        ),
        child: button,
      );
    }
    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: button,
      ),
    );
  }
}

/// ~36px circular control used on the post-auth header wash.
class SoftCircleButton extends StatelessWidget {
  static const double diameter = 36;

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color iconColor;

  /// Painted disc stays 36. The hit target can be larger so search and the
  /// bell meet a ~48px tap without growing the chrome.
  final double tapTarget;

  const SoftCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.iconColor = SoftColors.ink,
    this.tapTarget = diameter,
  });

  @override
  Widget build(BuildContext context) {
    final target = tapTarget < diameter ? diameter : tapTarget;
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: target,
        height: target,
        child: Material(
          color: SoftColors.clear,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Center(
              child: Ink(
                width: diameter,
                height: diameter,
                decoration: const BoxDecoration(
                  color: SoftColors.white,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: SoftColors.line),
                  ),
                  boxShadow: SoftShadows.cardSm,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Page wash: radial `#d4e4ff` at the top, then `--sw-page`.
class SoftWash extends StatelessWidget {
  final Widget child;
  const SoftWash({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // `#f4f6fa` under `radial-gradient(ellipse 90% 42% at 50% -4%, #d4e4ff 0%, transparent 70%)`.
    // §9 maps that ellipse to this RadialGradient.
    return DecoratedBox(
      decoration: const BoxDecoration(color: SoftColors.page),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.05,
            colors: [SoftColors.headerGlow, SoftColors.headerGlowClear],
            stops: [0, 0.7],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Centered muted note on the page wash. No icon and no invented CTA.
class QuietWashNote extends StatelessWidget {
  final String message;
  const QuietWashNote(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: SoftType.body,
      ),
    );
  }
}

/// Fixed 16:9 slot. No generated banner art is painted here.
class DashedBannerSlot extends StatelessWidget {
  final String label;
  final String? caption;
  const DashedBannerSlot({super.key, this.label = 'Banner', this.caption});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CustomPaint(
        painter: const _DashedBannerPainter(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: caption == null
                    ? SoftType.eyebrow
                    : SoftType.bannerTitle,
              ),
              if (caption != null) ...[
                const SizedBox(height: 4),
                Text(caption!, style: SoftType.cellLabel),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WipeLayer extends StatelessWidget {
  final Animation<double> animation;
  final bool incoming;
  final Widget child;

  const _WipeLayer({
    required this.animation,
    required this.incoming,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = incoming ? animation.value : 1.0;
        final scale =
            TeresaRizalNavMotion.pageStartScale +
            (1 - TeresaRizalNavMotion.pageStartScale) * t;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * TeresaRizalNavMotion.pageRiseOffset),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _DashedBannerPainter extends CustomPainter {
  const _DashedBannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(SoftRadius.lg),
    );
    canvas.drawRRect(rrect, Paint()..color = SoftColors.blueWash);
    final border = Paint()
      ..color = SoftColors.bannerDash
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), border);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBannerPainter oldDelegate) => false;
}

/// Branch change: 260ms ease-out-cubic, fade, 8px rise, scale 0.985→1.
/// Every child stays mounted, same as [IndexedStack], so scroll survives.
class SoftPageWipe extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const SoftPageWipe({super.key, required this.index, required this.children});

  @override
  State<SoftPageWipe> createState() => _SoftPageWipeState();
}

class _SoftPageWipeState extends State<SoftPageWipe>
    with SingleTickerProviderStateMixin {
  late int _shown;
  int? _outgoing;
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _shown = widget.index;
    _controller = AnimationController(vsync: this, value: 1)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            _outgoing != null &&
            mounted) {
          setState(() => _outgoing = null);
        }
      });
    _curve = CurvedAnimation(
      parent: _controller,
      curve: TeresaRizalNavMotion.pageCurve,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = TeresaRizalNavMotion.pageFor(context);
  }

  @override
  void didUpdateWidget(SoftPageWipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == _shown) return;
    _outgoing = _shown;
    _shown = widget.index;
    _controller.duration = TeresaRizalNavMotion.pageFor(context);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          Offstage(
            offstage: i != _shown && i != _outgoing,
            child: TickerMode(
              enabled: i == _shown || i == _outgoing,
              // The same parent chain on every frame. Swapping a page in and
              // out of FadeTransition would dispose its State, which reopens
              // the one-time home banner.
              child: _WipeLayer(
                animation: _curve,
                incoming: i == _shown && _outgoing != null,
                child: widget.children[i],
              ),
            ),
          ),
      ],
    );
  }
}
