import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/service_catalog_mock.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';

/// Focused fields keep this much room above the next obstruction.
/// Floor is 16; the target is 20. Never set a field below 16.
const kFieldScrollPadding = EdgeInsets.all(20);

class CatalogPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget> pinned;
  final Widget? footer;
  final VoidCallback? onClose;
  final bool closeIcon;

  const CatalogPage({
    super.key,
    required this.title,
    required this.body,
    this.pinned = const [],
    this.footer,
    this.onClose,
    this.closeIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoftColors.page,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
              child: Row(
                children: [
                  SoftCircleButton(
                    icon: closeIcon ? Icons.close_rounded : Icons.arrow_back_rounded,
                    tooltip: closeIcon ? 'Close' : 'Back',
                    onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: SoftType.pageTitle,
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            ...pinned,
            Expanded(child: body),
            ?footer,
          ],
        ),
      ),
    );
  }
}

class SamplePill extends StatelessWidget {
  final String label;
  const SamplePill({super.key, this.label = 'Sample'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: SoftColors.sampleWash,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
      ),
      child: Text(label, style: CatalogType.sample),
    );
  }
}

class HonestyNote extends StatelessWidget {
  final String text;
  final Color background;
  final IconData icon;
  final Color iconColor;

  const HonestyNote({
    super.key,
    required this.text,
    this.background = SoftColors.blueWash,
    this.icon = Icons.info_outline_rounded,
    this.iconColor = SoftColors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SoftRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: CatalogType.honesty)),
        ],
      ),
    );
  }
}

/// Compact Call 911 strip. Pinned on every Sakuna surface in this pack.
class Call911Strip extends StatelessWidget {
  final String headline;
  final String subtitle;

  const Call911Strip({
    super.key,
    this.headline = ServiceCatalogMock.stripHeadline,
    this.subtitle = ServiceCatalogMock.stripMdrrmo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: SoftColors.dangerSoft,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        child: Padding(
          key: const Key('sos-911-strip'),
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SoftColors.white,
                  borderRadius: BorderRadius.circular(SoftRadius.sm),
                ),
                child: const Icon(Icons.phone_in_talk_outlined, color: SoftColors.danger, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: CatalogType.bandTitle),
                    Text(subtitle, style: CatalogType.bandSub),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Call911Button(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Call911Button extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: SoftColors.danger,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        key: const Key('call-911'),
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: () => launchUrl(Uri.parse('tel:${ServiceCatalogMock.emergencyNumber}')),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_rounded, color: SoftColors.white, size: 14),
              SizedBox(width: 4),
              Text('Call 911', style: CatalogType.onDanger),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary actions use [SoftPillButton], which owns the single CTA shadow.
/// Disabled actions are a flat fill with no shadow wrapper.
class CatalogCta extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;

  const CatalogCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    if (onPressed == null) {
      return Material(
        color: SoftColors.disabledFill,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        child: InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(SoftRadius.pill),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            alignment: Alignment.center,
            child: Text(label, style: CatalogType.buttonMuted),
          ),
        ),
      );
    }
    if (danger) {
      return SoftPillButton(
        label: label,
        onPressed: onPressed,
        kind: SoftPillKind.danger,
      );
    }
    if (!primary) {
      return SoftPillButton(
        label: label,
        onPressed: onPressed,
        kind: SoftPillKind.outline,
      );
    }
    return SoftPillButton(label: label, onPressed: onPressed);
  }
}

class CatalogFooter extends StatelessWidget {
  final Widget child;
  const CatalogFooter({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      key: const Key('wizard-footer'),
      color: SoftColors.page,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: child,
      ),
    );
  }
}

class DualFooter extends StatelessWidget {
  final String back;
  final String next;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const DualFooter({
    super.key,
    this.back = 'Back',
    this.next = 'Continue',
    this.onBack,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return CatalogFooter(
      child: Row(
        children: [
          Expanded(
            child: CatalogCta(label: back, onPressed: onBack, primary: false),
          ),
          const SizedBox(width: 10),
          Expanded(child: CatalogCta(label: next, onPressed: onNext)),
        ],
      ),
    );
  }
}

class IconDisc extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color foreground;
  const IconDisc({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(SoftRadius.sm),
      ),
      child: Icon(icon, color: foreground, size: 18),
    );
  }
}

class WizardHead extends StatelessWidget {
  final int step;
  final String label;
  const WizardHead({super.key, required this.step, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('wizard-pinned-head'),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            child: LinearProgressIndicator(
              value: step / 7,
              minHeight: 4,
              backgroundColor: SoftColors.line,
              color: SoftColors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('Hakbang $step · $label', style: CatalogType.eyebrow),
              ),
              Text('$step / 7', style: CatalogType.counter),
            ],
          ),
        ],
      ),
    );
  }
}

List<InlineSpan> highlightQuery(String text, String query, TextStyle base) {
  final q = query.trim();
  if (q.isEmpty) return [TextSpan(text: text, style: base)];
  final lower = text.toLowerCase();
  final needle = q.toLowerCase();
  final spans = <InlineSpan>[];
  var index = 0;
  while (index < text.length) {
    final at = lower.indexOf(needle, index);
    if (at < 0) {
      spans.add(TextSpan(text: text.substring(index), style: base));
      break;
    }
    if (at > index) {
      spans.add(TextSpan(text: text.substring(index, at), style: base));
    }
    spans.add(TextSpan(
      text: text.substring(at, at + needle.length),
      style: CatalogType.highlight,
    ));
    index = at + needle.length;
  }
  return spans;
}

(Color, Color) dokyuTint(DokyuSection section) => switch (section) {
      DokyuSection.barangay => (SoftColors.blueSoft, SoftColors.blue),
      DokyuSection.civil => (SoftColors.cyanSoft, SoftColors.cyanInk),
      DokyuSection.business => (SoftColors.goldSoft, SoftColors.endedInk),
      DokyuSection.ids => (SoftColors.verifiedSoft, SoftColors.verifiedInk),
    };

String windowLabel(ProgramWindow window) => switch (window) {
      ProgramWindow.open => 'Open',
      ProgramWindow.closed => 'Closed',
      ProgramWindow.opensSoon => 'Opens soon',
    };

(Color, Color) windowColors(ProgramWindow window) => switch (window) {
      ProgramWindow.open => (SoftColors.verifiedSoft, SoftColors.verifiedInk),
      ProgramWindow.closed => (SoftColors.chipWash, SoftColors.muted),
      ProgramWindow.opensSoon => (SoftColors.endedWash, SoftColors.endedInk),
    };
