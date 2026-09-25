import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';

/// Sample barangays for the Register personal step.
/// Teresa, Rizal's nine barangays — not the seeded catalogue list.
const teresaRegisterBarangays = <String>[
  'Bagumbayan',
  'Calumpang',
  'Dalig',
  'Dulumbayan',
  'May-Iba',
  'Poblacion',
  'Prinza',
  'San Gabriel',
  'San Roque',
];

/// Extra space so a focused field can sit above the sticky Continue bar.
const authFieldScrollPadding = EdgeInsets.fromLTRB(20, 72, 20, 120);

ThemeData authSoftTheme(ThemeData base) {
  final radius = BorderRadius.circular(SoftRadius.md);
  OutlineInputBorder edge(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return base.copyWith(
    scaffoldBackgroundColor: SoftColors.clear,
    splashColor: SoftColors.blueSoft,
    appBarTheme: const AppBarTheme(
      backgroundColor: SoftColors.clear,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: SoftColors.clear,
      foregroundColor: SoftColors.ink,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: SoftColors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: SoftType.body.copyWith(color: SoftColors.muted),
      labelStyle: SoftType.body.copyWith(fontSize: 13, color: SoftColors.ink),
      border: edge(SoftColors.line),
      enabledBorder: edge(SoftColors.line),
      focusedBorder: edge(SoftColors.blue, 1.5),
      errorBorder: edge(SoftColors.danger),
      focusedErrorBorder: edge(SoftColors.danger, 1.5),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: SoftColors.blue,
        textStyle: SoftType.sectionLink,
      ),
    ),
  );
}

class AuthSoftCard extends StatelessWidget {
  final Widget child;
  const AuthSoftCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: SoftColors.line),
        boxShadow: SoftShadows.cardSm,
      ),
      child: child,
    );
  }
}

class AuthInlineLink extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Key? linkKey;

  const AuthInlineLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.linkKey,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: linkKey,
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: SoftColors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: SoftType.sectionLink.copyWith(fontSize: 14),
      ),
      child: Text(label),
    );
  }
}

class AuthErrorText extends StatelessWidget {
  final String message;
  const AuthErrorText(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: SoftType.body.copyWith(fontSize: 13, color: SoftColors.danger),
    );
  }
}

class AuthStepProgress extends StatelessWidget {
  final int step;
  final List<String> labels;

  const AuthStepProgress({super.key, required this.step, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Step ${step + 1} of ${labels.length}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SoftType.sectionLink,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                labels[step],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: SoftType.cellLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i <= step ? SoftColors.blue : SoftColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const SizedBox(height: 4),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Outline pill. Primary actions stay on [AppButton], which is already blue.
class AuthOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const AuthOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(SoftRadius.pill),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SoftRadius.pill),
              border: Border.all(color: SoftColors.line),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: AppTypography.sans,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: SoftColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AuthDashedWell extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const AuthDashedWell({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SoftColors.blueWash,
      borderRadius: BorderRadius.circular(SoftRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.md),
        onTap: onTap,
        child: CustomPaint(
          painter: const _DashPainter(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SoftColors.bannerDash
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(SoftRadius.md),
    );
    final path = Path()..addRRect(rrect);
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
