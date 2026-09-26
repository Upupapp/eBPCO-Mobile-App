import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/soft_widget.dart';
import 'nav/soft_nav_motion.dart';

/// Chrome ported from the design reference's `widgets/soft_chrome.dart`,
/// recolored to eBPCO red. Shapes, sizes and motion are the reference's.

enum SoftStatusTone { neutral, pending, verified, danger }

/// 28px status pill with a leading dot.
class SoftStatusPill extends StatelessWidget {
  final String label;
  final SoftStatusTone tone;

  const SoftStatusPill({super.key, required this.label, required this.tone});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (tone) {
      SoftStatusTone.neutral => (SoftColors.chipWash, SoftColors.muted),
      SoftStatusTone.pending => (SoftColors.pendingCream, SoftColors.pendingInk),
      SoftStatusTone.verified => (SoftColors.verifiedSoft, SoftColors.verifiedInk),
      SoftStatusTone.danger => (SoftColors.dangerSoft, SoftColors.danger),
    };
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(SoftRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: foreground, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SoftType.cellLabel.copyWith(color: foreground, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Initials disc — primary red, white Inter 600, soft red glow. Shows the
/// citizen's profile photo instead when there is one.
class SoftInitialAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Uint8List? photo;

  const SoftInitialAvatar({super.key, required this.initials, this.size = 46, this.photo});

  @override
  Widget build(BuildContext context) {
    final image = photo;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(color: SoftColors.primary, shape: BoxShape.circle, boxShadow: SoftShadows.avatar),
      child: image != null
          ? Image.memory(
              image,
              width: size,
              height: size,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              // A photo the phone cannot decode falls back to the initials.
              errorBuilder: (_, _, _) => _initialsText(),
            )
          : _initialsText(),
    );
  }

  Widget _initialsText() => Text(
        initials,
        style: SoftType.cellValue.copyWith(color: SoftColors.white, fontWeight: FontWeight.w600, fontSize: size < 40 ? 13 : 16),
      );
}

enum SoftPillKind { primary, outline, danger, dangerSoft, text }

/// Full-width pill button. Primary carries the soft red glow.
class SoftPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SoftPillKind kind;
  final bool busy;
  final IconData? icon;
  final bool iconTrailing;

  const SoftPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = SoftPillKind.primary,
    this.busy = false,
    this.icon,
    this.iconTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    var (background, foreground, border) = switch (kind) {
      SoftPillKind.primary => (SoftColors.primary, SoftColors.white, null),
      SoftPillKind.outline => (SoftColors.white, SoftColors.primary, SoftColors.line),
      SoftPillKind.danger => (SoftColors.danger, SoftColors.white, null),
      SoftPillKind.dangerSoft => (SoftColors.dangerSoft, SoftColors.danger, null),
      SoftPillKind.text => (SoftColors.clear, SoftColors.primary, null),
    };
    if (!enabled && kind == SoftPillKind.primary && !busy) {
      background = SoftColors.disabledFill;
      foreground = SoftColors.disabledInk;
    }
    final vertical = kind == SoftPillKind.text ? 10.0 : 16.0;
    Widget button = Material(
      color: background,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: enabled ? onPressed : null,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: vertical),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: border == null ? null : Border.all(color: border),
          ),
          child: busy
              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null && !iconTrailing) ...[Icon(icon, size: 18, color: foreground), const SizedBox(width: 8)],
                    Flexible(
                      child: Text(label, textAlign: TextAlign.center, style: SoftType.button.copyWith(color: foreground)),
                    ),
                    if (icon != null && iconTrailing) ...[const SizedBox(width: 6), Icon(icon, size: 20, color: foreground)],
                  ],
                ),
        ),
      ),
    );
    if (kind == SoftPillKind.primary && enabled) {
      button = DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(SoftRadius.pill)),
          boxShadow: SoftShadows.primary,
        ),
        child: button,
      );
    }
    return Semantics(button: true, enabled: enabled, child: button);
  }
}

/// ~40px white circular control used on the header wash (back, bell).
/// [badge] draws the reference's red count bubble.
class SoftCircleButton extends StatelessWidget {
  static const double diameter = 40;

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final int badge;

  const SoftCircleButton({super.key, required this.icon, required this.onPressed, required this.tooltip, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Shadow sits outside the Material: an Ink decoration's shadow is
            // clipped to its square bounds and shows as a grey box.
            DecoratedBox(
              decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: SoftShadows.cardSm),
              child: Material(
                color: SoftColors.white,
                shape: const CircleBorder(side: BorderSide(color: SoftColors.line)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onPressed,
                  child: SizedBox(
                    width: diameter,
                    height: diameter,
                    child: Icon(icon, size: 18, color: SoftColors.ink),
                  ),
                ),
              ),
            ),
            if (badge > 0)
              Positioned(
                top: 0,
                right: -2,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 20),
                    decoration: BoxDecoration(
                      color: SoftColors.danger,
                      borderRadius: BorderRadius.circular(SoftRadius.pill),
                      border: Border.all(color: SoftColors.white, width: 1.5),
                    ),
                    child: Text(
                      badge > 9 ? '9+' : '$badge',
                      textAlign: TextAlign.center,
                      style: SoftType.cellLabel.copyWith(color: SoftColors.white, fontSize: 11, fontWeight: FontWeight.w600),
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

/// Page wash: a soft radial red glow at the top, then the page color —
/// the reference's `SoftWash`, recolored.
class SoftWash extends StatelessWidget {
  final Widget child;
  const SoftWash({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: DecoratedBox(
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
      ),
    );
  }
}

/// Section heading row: title left, optional red link right.
class SoftSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SoftSectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: SoftType.section.copyWith(fontSize: 18))),
          if (action != null)
            GestureDetector(onTap: onAction, child: Text(action!, style: SoftType.sectionLink.copyWith(fontSize: 14))),
        ],
      ),
    );
  }
}

/// Horizontal filter pill: selected is solid red, otherwise white with a hairline.
class SoftFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SoftFilterChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SoftColors.primary : SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: Border.all(color: selected ? SoftColors.primary : SoftColors.line),
          ),
          child: Text(label, style: SoftType.chip.copyWith(color: selected ? SoftColors.white : SoftColors.ink)),
        ),
      ),
    );
  }
}

/// A tap-to-pick value (e.g. a date) drawn like the pill text fields.
class SoftPickerField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;
  const SoftPickerField({super.key, required this.value, required this.placeholder, required this.onTap, this.icon = Icons.calendar_today_outlined});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: () {
          // Otherwise the last text field regains focus when the picker
          // closes and the keyboard pops back over the form.
          FocusScope.of(context).unfocus();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: Border.all(color: SoftColors.line),
          ),
          child: Row(
            children: [
              Expanded(child: Text(value ?? placeholder, style: value == null ? SoftType.hint : SoftType.field)),
              Icon(icon, size: 18, color: SoftColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Form field caption above an input.
class SoftFieldLabel extends StatelessWidget {
  final String text;
  const SoftFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: SoftType.fieldLabel.copyWith(fontSize: 14)),
    );
  }
}

/// Centered muted note on the wash — no icon, no invented CTA.
class QuietWashNote extends StatelessWidget {
  final String message;
  const QuietWashNote(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
      child: Text(message, textAlign: TextAlign.center, style: SoftType.body),
    );
  }
}

/// A tinted empty-state card (the reference's "No active requests yet").
class SoftEmptyCard extends StatelessWidget {
  final String message;
  const SoftEmptyCard(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(color: SoftColors.primaryWash, borderRadius: BorderRadius.circular(SoftRadius.lg)),
      child: Text(message, textAlign: TextAlign.center, style: SoftType.body.copyWith(fontSize: 15)),
    );
  }
}

class _WipeLayer extends StatelessWidget {
  final Animation<double> animation;
  final bool incoming;
  final Widget child;

  const _WipeLayer({required this.animation, required this.incoming, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = incoming ? animation.value : 1.0;
        final scale = SoftNavMotion.pageStartScale + (1 - SoftNavMotion.pageStartScale) * t;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - t) * SoftNavMotion.pageRiseOffset),
            child: Transform.scale(scale: scale, alignment: Alignment.topCenter, child: child),
          ),
        );
      },
    );
  }
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

class _SoftPageWipeState extends State<SoftPageWipe> with SingleTickerProviderStateMixin {
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
        if (status == AnimationStatus.completed && _outgoing != null && mounted) {
          setState(() => _outgoing = null);
        }
      });
    _curve = CurvedAnimation(parent: _controller, curve: SoftNavMotion.pageCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = SoftNavMotion.pageFor(context);
  }

  @override
  void didUpdateWidget(SoftPageWipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == _shown) return;
    _outgoing = _shown;
    _shown = widget.index;
    _controller.duration = SoftNavMotion.pageFor(context);
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
              child: _WipeLayer(animation: _curve, incoming: i == _shown && _outgoing != null, child: widget.children[i]),
            ),
          ),
      ],
    );
  }
}
