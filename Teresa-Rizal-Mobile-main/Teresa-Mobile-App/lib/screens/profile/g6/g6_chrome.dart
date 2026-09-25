import 'package:flutter/material.dart';
import '../../../theme/g6_tokens.dart';

import '../../../theme/soft_widget.dart';
import '../../../widgets/soft_chrome.dart';
import 'g6_sample.dart';

/// Page shell for Pack F push screens. No bottom nav.
///
/// When the view has no top inset (widget screenshots), a 44px status
/// strip is drawn so the frame matches the 390×844 comp. On a device the
/// real status inset is used instead.
class G6Shell extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? footer;
  final List<Widget> actions;
  final double footerBottom;
  final Widget? overlay;
  final Widget? annotation;
  final double annotationBottom;
  final Widget? ime;

  /// Pack H: footer is the last child of the body column so it rises with
  /// `viewInsets`. The wizard head stays pinned under the page bar.
  final bool liftFooterWithInset;
  final Widget? pinned;

  const G6Shell({
    super.key,
    required this.title,
    required this.body,
    this.footer,
    this.actions = const [],
    this.footerBottom = 0,
    this.overlay,
    this.annotation,
    this.annotationBottom = 346,
    this.ime,
    this.liftFooterWithInset = false,
    this.pinned,
  });

  @override
  Widget build(BuildContext context) {
    if (liftFooterWithInset) {
      return SoftWash(
        child: Scaffold(
          backgroundColor: SoftColors.clear,
          resizeToAvoidBottomInset: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const G6StatusBar(),
              _PageBar(title: title, actions: actions),
              ?pinned,
              Expanded(child: body),
              ?footer,
            ],
          ),
        ),
      );
    }
    return SoftWash(
      child: Scaffold(
        backgroundColor: SoftColors.clear,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const G6StatusBar(),
                _PageBar(title: title, actions: actions),
                Expanded(child: body),
              ],
            ),
            if (footer != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: footerBottom,
                child: footer!,
              ),
            if (annotation != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: annotationBottom,
                child: annotation!,
              ),
            if (ime != null)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 280,
                child: G6TextIme(),
              ),
            if (overlay != null) Positioned.fill(child: overlay!),
          ],
        ),
      ),
    );
  }
}

class G6StatusBar extends StatelessWidget {
  const G6StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    if (top > 0) return SizedBox(height: top);
    return const SizedBox(
      height: 44,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 22, 0),
        child: Row(
          children: [
            Text(
              '9:41',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: G6Type.px12,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.12,
                color: SoftColors.ink,
              ),
            ),
            Spacer(),
            _SignalMarks(),
          ],
        ),
      ),
    );
  }
}

class _SignalMarks extends StatelessWidget {
  const _SignalMarks();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final h in [5.0, 8.0, 11.0]) ...[
          Container(
            width: 3,
            height: h,
            margin: const EdgeInsets.only(left: 2),
            decoration: BoxDecoration(
              color: SoftColors.ink,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: SoftColors.ink,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _PageBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  const _PageBar({required this.title, required this.actions});

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SoftCircleButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () {
                  if (navigator.canPop()) navigator.pop();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 52),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: SoftType.pageTitle,
              ),
            ),
            if (actions.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Row(mainAxisSize: MainAxisSize.min, children: actions),
              ),
          ],
        ),
      ),
    );
  }
}

class G6CloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  const G6CloseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SoftCircleButton(
      icon: Icons.close_rounded,
      tooltip: 'Close',
      onPressed: onPressed,
    );
  }
}

enum G6ButtonKind { blue, outline, danger, dangerSoft }

class G6Button extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final G6ButtonKind kind;
  final IconData? icon;
  final Key? buttonKey;

  const G6Button({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = G6ButtonKind.blue,
    this.icon,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (kind) {
      G6ButtonKind.blue => (SoftColors.blue, SoftColors.white, null),
      G6ButtonKind.outline => (
        SoftColors.white,
        SoftColors.blue,
        SoftColors.line,
      ),
      G6ButtonKind.danger => (SoftColors.danger, SoftColors.white, null),
      G6ButtonKind.dangerSoft => (
        SoftColors.dangerSoft,
        SoftColors.danger,
        null,
      ),
    };
    // Same structure as AppButton / SoftPillButton: one SoftShadows.primary
    // layer outside Material. A shadow painted inside Material is clipped
    // into a hard offset slab under the pill.
    Widget button = Material(
      color: bg,
      elevation: 0,
      shadowColor: SoftColors.clear,
      surfaceTintColor: SoftColors.clear,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        key: buttonKey,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: onPressed,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: border == null ? null : Border.all(color: border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: G6Type.px13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (kind == G6ButtonKind.blue) {
      button = DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(SoftRadius.pill)),
          boxShadow: SoftShadows.primary,
        ),
        child: button,
      );
    }
    return button;
  }
}

class G6Footer extends StatelessWidget {
  final Widget child;
  const G6Footer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SoftColors.page.withValues(alpha: 0),
            SoftColors.page.withValues(alpha: 0.96),
            SoftColors.page,
          ],
          stops: const [0, 0.28, 1],
        ),
      ),
      child: child,
    );
  }
}

class G6DualFooter extends StatelessWidget {
  final Widget left;
  final Widget right;
  const G6DualFooter({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Row(
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      ),
    );
  }
}

enum G6HonestyTone { info, gold, danger }

class G6Honesty extends StatelessWidget {
  final String lead;
  final String rest;
  final G6HonestyTone tone;
  final bool compact;

  const G6Honesty({
    super.key,
    required this.lead,
    required this.rest,
    this.tone = G6HonestyTone.info,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (tone) {
      G6HonestyTone.info => SoftColors.blueSoft,
      G6HonestyTone.gold => G6Palette.cream,
      G6HonestyTone.danger => SoftColors.dangerSoft,
    };
    final iconColor = switch (tone) {
      G6HonestyTone.info => SoftColors.blue,
      G6HonestyTone.gold => SoftColors.endedInk,
      G6HonestyTone.danger => SoftColors.danger,
    };
    return Container(
      margin: EdgeInsets.only(top: compact ? 10 : 12),
      padding: EdgeInsets.fromLTRB(12, compact ? 9 : 12, 12, compact ? 9 : 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        border: tone == G6HonestyTone.gold
            ? Border.all(color: SoftColors.gold.withValues(alpha: 0.35))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 24 : 28,
            height: compact ? 24 : 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: SoftColors.white,
              borderRadius: BorderRadius.circular(compact ? 8 : 10),
              boxShadow: SoftShadows.cardSm,
            ),
            child: Icon(Icons.info_outline_rounded, size: 14, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                  color: SoftColors.ink,
                ),
                children: [
                  TextSpan(
                    text: lead,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: ' $rest'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class G6Initials extends StatelessWidget {
  final String initials;
  final G6AvatarTone? tone;
  final double size;
  final bool onBlue;

  const G6Initials({
    super.key,
    required this.initials,
    this.tone,
    this.size = 40,
    this.onBlue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: onBlue ? G6Palette.white20 : null,
        gradient: onBlue || tone == null ? null : g6AvatarGradient(tone!),
        boxShadow: onBlue ? null : SoftShadows.avatar,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size >= 60 ? 19 : (size <= 36 ? 12 : 13),
          fontWeight: FontWeight.w600,
          color: SoftColors.white,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

class G6VerifyChip extends StatelessWidget {
  final G6Verify verify;
  final bool onBlue;
  final String? label;
  final bool showIcon;

  const G6VerifyChip({
    super.key,
    required this.verify,
    this.onBlue = false,
    this.label,
    this.showIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final text =
        label ??
        switch (verify) {
          G6Verify.verified => 'Verified',
          G6Verify.unverified => 'Unverified',
          G6Verify.pending => 'Pending',
        };
    final (bg, fg) = onBlue
        ? (G6Palette.white18, SoftColors.white)
        : switch (verify) {
            G6Verify.verified => (
              SoftColors.verifiedSoft,
              SoftColors.verifiedInk,
            ),
            G6Verify.unverified => (SoftColors.chipWash, SoftColors.muted),
            G6Verify.pending => (G6Palette.cream, SoftColors.endedInk),
          };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon && verify != G6Verify.unverified) ...[
            Icon(
              verify == G6Verify.verified
                  ? Icons.check_rounded
                  : Icons.schedule_rounded,
              size: 12,
              color: fg,
            ),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: G6Type.px11,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class G6KindChip extends StatelessWidget {
  final String label;
  const G6KindChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SoftColors.blueSoft,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: G6Type.px11,
          fontWeight: FontWeight.w500,
          color: SoftColors.blueDeep,
        ),
      ),
    );
  }
}

class G6DashedBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final double radius;
  final Color? fill;

  const G6DashedBox({
    super.key,
    required this.child,
    this.color = SoftColors.bannerDash,
    this.radius = 12,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashPainter(color: color, radius: radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: child,
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect.deflate(0.75));
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + 5;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// Text IME harness. Plain keys, no OS or vendor branding. Same idea as
/// the G4 register keyboard frame: a drawn keypad sitting in the inset,
/// with the footer placed above it.
class G6TextIme extends StatelessWidget {
  const G6TextIme({super.key});

  static const _bg = G6Palette.keyBg;
  static const _key = SoftColors.white;
  static const _wide = G6Palette.keyWide;

  @override
  Widget build(BuildContext context) {
    const rows = <List<_Key>>[
      [
        _Key('q'),
        _Key('w'),
        _Key('e'),
        _Key('r'),
        _Key('t'),
        _Key('y'),
        _Key('u'),
        _Key('i'),
        _Key('o'),
        _Key('p'),
      ],
      [
        _Key('a'),
        _Key('s'),
        _Key('d'),
        _Key('f'),
        _Key('g'),
        _Key('h'),
        _Key('j'),
        _Key('k'),
        _Key('l'),
      ],
      [
        _Key.icon(Icons.arrow_upward_rounded, wide: true),
        _Key('z'),
        _Key('x'),
        _Key('c'),
        _Key('v'),
        _Key('b'),
        _Key('n'),
        _Key('m'),
        _Key.icon(Icons.backspace_outlined, wide: true),
      ],
      [
        _Key('123', wide: true),
        _Key(',', wide: true),
        _Key('space', space: true),
        _Key('.', wide: true),
        _Key('Next', go: true),
      ],
    ];
    return Material(
      color: _bg,
      elevation: 0,
      shadowColor: SoftColors.clear,
      surfaceTintColor: SoftColors.clear,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 0, 6, 8),
        child: Column(
          children: [
            const SizedBox(
              height: 34,
              child: Row(
                children: [
                  _Suggest('Santos'),
                  _Suggest('Santiago', divider: true),
                  _Suggest('Santa', divider: true),
                ],
              ),
            ),
            for (final row in rows)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final key in row)
                        Expanded(
                          flex: key.space ? 4 : (key.wide || key.go ? 2 : 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: key.go
                                    ? SoftColors.blue
                                    : (key.wide ? _wide : _key),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: const [
                                  BoxShadow(
                                    color: G6Palette.hairline,
                                    blurRadius: 0,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Center(child: key.build()),
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
}

class _Suggest extends StatelessWidget {
  final String text;
  final bool divider;
  const _Suggest(this.text, {this.divider = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: divider
              ? const Border(left: BorderSide(color: G6Palette.keyLine))
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: G6Type.px13,
              fontWeight: FontWeight.w400,
              color: SoftColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _Key {
  final String? label;
  final IconData? icon;
  final bool wide;
  final bool space;
  final bool go;

  const _Key(
    this.label, {
    this.wide = false,
    this.space = false,
    this.go = false,
  }) : icon = null;
  const _Key.icon(this.icon, {this.wide = false})
    : label = null,
      space = false,
      go = false;

  Widget build() {
    if (icon != null) {
      return Icon(icon, size: 18, color: SoftColors.ink);
    }
    return Text(
      label!,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: go || wide || space ? 12 : 15,
        fontWeight: go || wide ? FontWeight.w500 : FontWeight.w400,
        color: go
            ? SoftColors.white
            : (wide || space ? SoftColors.muted : SoftColors.ink),
      ),
    );
  }
}

class G6Annotation extends StatelessWidget {
  final String text;
  const G6Annotation(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: G6Palette.ink90,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: G6Palette.scrimShadow,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: G6Type.px11,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: SoftColors.white,
        ),
      ),
    );
  }
}
