import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../models/access_level.dart';
import '../../../widgets/service_launcher_menu.dart';
import '../../../models/service_request.dart';
import '../../../services/citizen_session_service.dart';
import '../../../services/mock_catalog.dart';
import '../../../theme/soft_widget.dart';
import '../../../utils/teresa_rizal_seal.dart';
import '../../../widgets/app_dialogs.dart';
import '../../auth/login_screen.dart';
import '../../auth/register_screen.dart';
import '../../balita/balita_screen.dart';
import '../../home/root_shell.dart';
import '../../shared/detail_chrome.dart';
import '../../shared/new_request_screen.dart';
import 'g5_chrome.dart';

/// Scholarship approved landing. Text reference only — QR claim is G7.
class TulongApprovedPage extends StatelessWidget {
  const TulongApprovedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return G5Page(
      title: 'Educational Assistance',
      onBack: () => g5Back(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
        children: [
          const G5Eyebrow(),
          Text('Tulong · Scholarship · TR-TUL-0917', style: SoftType.cellLabel),
          const SizedBox(height: 4),
          const Text('Educational Assistance', style: detailHeadline),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              DetailChip(
                label: 'Approved',
                background: SoftColors.verifiedSoft,
                foreground: SoftColors.verifiedInk,
                leadingDot: true,
              ),
              DetailChip(
                label: 'Release next',
                background: SoftColors.blueSoft,
                foreground: SoftColors.blueDeep,
              ),
            ],
          ),
          const SizedBox(height: 10),
          G5Card(
            color: SoftColors.verifiedSoft,
            borderColor: SoftColors.clear,
            shadow: const [],
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SoftColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: SoftColors.verifiedInk,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your application was approved',
                        style: SoftType.cellValue.copyWith(
                          color: SoftColors.verifiedInk,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Claim in person at MSWDO Teresa · sample ₱5,000.00 cash payout.',
                        style: SoftType.greetingHi.copyWith(
                          color: SoftColors.ink,
                          height: 1.42,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const G5Card(
            padding: EdgeInsets.fromLTRB(8, 14, 8, 12),
            child: _MilestoneStrip(),
          ),
          const SizedBox(height: 10),
          const G5Card(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _Fact(
                  icon: Icons.place_outlined,
                  label: 'Where to claim',
                  value: 'MSWDO desk · Municipal Hall',
                  note: 'Poblacion, Teresa, Rizal · text only',
                ),
                _Fact(
                  icon: Icons.schedule_rounded,
                  label: 'When · sample schedule',
                  value: 'Fri, Oct 2, 2026 · 9:00 AM – 3:00 PM',
                ),
                _Fact(
                  icon: Icons.badge_outlined,
                  label: 'Bring',
                  value: 'Valid ID · school COR · this reference',
                  divider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const _ReferenceBox(),
          const G5Honesty(
            strong: true,
            icon: Icons.shield_outlined,
            lead: 'Not live assistance funds.',
            rest:
                'Approval, amount, and schedule are samples — no money is released through this preview.',
          ),
          const SizedBox(height: 12),
          G5Button(
            label: 'Add claim date to calendar',
            icon: Icons.calendar_today_outlined,
            onPressed: () => AppDialogs.toast(
              context,
              'Opens device calendar / local preview — not a live LGU booking.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneStrip extends StatelessWidget {
  const _MilestoneStrip();

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('Submitted', 'Sep 17', false),
      ('Reviewed', 'Sep 22', false),
      ('Approved', 'Sep 25', false),
      ('Release', 'Oct 2', true),
    ];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: 14,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (i > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 2,
                            margin: const EdgeInsets.only(right: 10),
                            color: steps[i].$3
                                ? SoftColors.line
                                : SoftColors.verifiedSoft,
                          ),
                        ),
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: steps[i].$3
                              ? SoftColors.blue
                              : SoftColors.verifiedInk,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: steps[i].$3
                                  ? SoftColors.blueSoft
                                  : SoftColors.verifiedSoft,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  steps[i].$1,
                  style: SoftType.cellLabel.copyWith(
                    fontWeight: FontWeight.w500,
                    color: steps[i].$3 ? SoftColors.blue : SoftColors.ink,
                  ),
                ),
                Text(steps[i].$2, style: SoftType.nav),
              ],
            ),
          ),
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? note;
  final bool divider;
  final bool tulong;

  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
    this.divider = true,
    this.tulong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: SoftColors.line))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          G5IconDisc(
            icon: icon,
            wash: tulong ? SoftColors.tulongSoft : SoftColors.blueSoft,
            color: tulong ? SoftColors.tulongInk : SoftColors.blue,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: SoftType.cellLabel),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: SoftType.bannerTitle.copyWith(color: SoftColors.ink),
                ),
                if (note != null)
                  Text(note!, style: SoftType.cellLabel.copyWith(height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceBox extends StatelessWidget {
  const _ReferenceBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: SoftColors.blueWash,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        border: Border.all(color: SoftColors.bannerDash, width: 1.5),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Show at the desk', style: SoftType.cellLabel),
                SizedBox(height: 2),
                Text(
                  'TR-TUL-0917',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.32,
                    color: SoftColors.blueDeep,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: SoftColors.white,
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            child: InkWell(
              borderRadius: BorderRadius.circular(SoftRadius.pill),
              onTap: () async {
                await Clipboard.setData(
                  const ClipboardData(text: 'TR-TUL-0917'),
                );
                if (!context.mounted) return;
                AppDialogs.toast(context, 'Reference copied on this device.');
              },
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SoftRadius.pill),
                  border: Border.all(color: SoftColors.line),
                ),
                child: Text('Copy', style: SoftType.sectionLink),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Deep-link focus state. Resubmit stays disabled until Replace.
/// Pack D's own correction frame is a different screen and stays enabled.
class CorrectionFocusPage extends StatefulWidget {
  const CorrectionFocusPage({super.key});

  @override
  State<CorrectionFocusPage> createState() => _CorrectionFocusPageState();
}

class _CorrectionFocusPageState extends State<CorrectionFocusPage> {
  bool _replaced = false;

  @override
  Widget build(BuildContext context) {
    return G5Page(
      title: 'Barangay Clearance',
      onBack: () => g5Back(context),
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            G5Button(
              key: const ValueKey('g5-resubmit'),
              label: 'Resubmit',
              kind: _replaced ? G5ButtonKind.primary : G5ButtonKind.disabled,
              onPressed: _replaced
                  ? () => AppDialogs.toast(
                      context,
                      'Resubmit is a local preview — not sent to an officer queue.',
                    )
                  : null,
            ),
            if (!_replaced) ...[
              const SizedBox(height: 8),
              const Text(
                'Replace the flagged Valid ID to enable Resubmit',
                textAlign: TextAlign.center,
                style: SoftType.cellLabel,
              ),
            ],
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 16),
        children: [
          G5Card(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const G5IconDisc(
                  icon: Icons.description_outlined,
                  wash: SoftColors.endedWash,
                  color: SoftColors.endedInk,
                  size: 32,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Barangay clearance', style: SoftType.bannerTitle),
                      Text('Dokyu · TR-DKY-0920', style: SoftType.cellLabel),
                    ],
                  ),
                ),
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SoftColors.endedWash,
                    borderRadius: BorderRadius.circular(SoftRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: SoftColors.endedInk,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Needs correction',
                        style: detailChip.copyWith(color: SoftColors.endedInk),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const G5Eyebrow(aux: 'jumped to flagged item'),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [SoftColors.clear, SoftColors.ink],
              stops: [0, 0.7],
            ).createShader(rect),
            blendMode: BlendMode.dstIn,
            child: Opacity(
              opacity: 0.5,
              child: G5Card(
                color: SoftColors.endedWash,
                borderColor: SoftColors.clear,
                shadow: const [],
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Text(
                  'One requirement was flagged. Replace the document below, then resubmit for review.',
                  style: SoftType.greetingHi.copyWith(
                    color: SoftColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text('Requirements', style: SoftType.cellValue),
              ),
              _flag('1 of 1 flagged'),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                decoration: BoxDecoration(
                  color: SoftColors.white,
                  borderRadius: BorderRadius.circular(SoftRadius.lg),
                  border: Border.all(color: SoftColors.danger, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: SoftColors.danger.withValues(alpha: 0.12),
                      spreadRadius: 6,
                    ),
                    ...SoftShadows.card,
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Valid ID', style: SoftType.name),
                        ),
                        _flag('Flagged'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: SoftColors.dangerSoft,
                        borderRadius: BorderRadius.circular(SoftRadius.sm),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OFFICER NOTE · SAMPLE',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                              color: SoftColors.danger,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Blurry and edges cut off. Upload a clearer front photo of your valid ID.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              color: SoftColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SoftColors.white,
                        borderRadius: BorderRadius.circular(SoftRadius.md),
                        border: Border.all(color: SoftColors.line),
                      ),
                      child: Row(
                        children: [
                          const G5IconDisc(
                            icon: Icons.description_outlined,
                            wash: SoftColors.dangerSoft,
                            color: SoftColors.danger,
                            size: 42,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'philsys-front.jpg',
                                  style: SoftType.bannerTitle,
                                ),
                                Text(
                                  _replaced
                                      ? 'Replacement marked · local preview'
                                      : 'Current file · needs replace',
                                  style: SoftType.cellLabel,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tip('Good light'),
                        _Tip('All 4 corners'),
                        _Tip('No glare'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    G5Button(
                      label: 'Replace document',
                      icon: Icons.file_upload_outlined,
                      onPressed: () {
                        setState(() => _replaced = true);
                        AppDialogs.toast(
                          context,
                          'Local preview — the flagged file is marked replaced on this device.',
                        );
                      },
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                top: 0,
                child: Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: SoftColors.danger,
                    borderRadius: BorderRadius.circular(SoftRadius.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.adjust_rounded,
                        size: 11,
                        color: SoftColors.white,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Needs your action',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: SoftColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          G5Card(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Opacity(
              opacity: 0.62,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: SoftColors.verifiedSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: SoftColors.verifiedInk,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Proof of residency', style: SoftType.bannerTitle),
                        Text(
                          'Accepted · no action needed',
                          style: SoftType.cellLabel,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const G5Honesty(
            lead: 'Local preview.',
            rest:
                'Officer note, replace, and resubmit are simulated — not a live officer queue.',
          ),
        ],
      ),
    );
  }

  Widget _flag(String label) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SoftColors.dangerSoft,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
      ),
      child: Text(
        label,
        style: SoftType.nav.copyWith(
          color: SoftColors.danger,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String label;
  const _Tip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: SoftColors.blueWash,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        border: Border.all(color: SoftColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_rounded,
            size: 11,
            color: SoftColors.verifiedInk,
          ),
          const SizedBox(width: 4),
          Text(label, style: SoftType.cellLabel),
        ],
      ),
    );
  }
}

class AdvisoryDetailPage extends StatefulWidget {
  final bool hotlineOpen;

  const AdvisoryDetailPage({super.key, this.hotlineOpen = false});

  @override
  State<AdvisoryDetailPage> createState() => _AdvisoryDetailPageState();
}

class _AdvisoryDetailPageState extends State<AdvisoryDetailPage> {
  late bool _hotline = widget.hotlineOpen;

  @override
  void didUpdateWidget(AdvisoryDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hotlineOpen != widget.hotlineOpen) {
      _hotline = widget.hotlineOpen;
    }
  }

  Future<void> _call911() async {
    final uri = Uri.parse('tel:911');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _directions() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Teresa+Municipal+Gym+Poblacion+Teresa+Rizal',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        G5Page(
          title: 'Advisory',
          onBack: () => g5Back(context),
          onShare: () => AppDialogs.toast(
            context,
            'Share is a local preview — nothing is posted outside this app.',
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
            children: [
              const G5Eyebrow(),
              _advisoryCard(skeleton: _hotline),
              if (!_hotline) ...[
                const SizedBox(height: 14),
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Affected barangays',
                        style: SoftType.cellValue,
                      ),
                    ),
                    Text('Sample list', style: SoftType.cellLabel),
                  ],
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _BrgyChip('Dalig'),
                    _BrgyChip('San Gabriel'),
                    _BrgyChip('Dulumbayan'),
                    _BrgyChip('San Roque'),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Open evacuation center',
                        style: SoftType.cellValue,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        RootShell.openService(
                          context,
                          ServiceLauncherTarget.emergency,
                        );
                        Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst);
                      },
                      child: const Text('See all', style: SoftType.sectionLink),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                G5Card(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EvacUpdatePage(),
                    ),
                  ),
                  child: const Row(
                    children: [
                      G5IconDisc(
                        icon: Icons.home_outlined,
                        wash: SoftColors.dangerSoft,
                        color: SoftColors.danger,
                        size: 44,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Teresa Municipal Gym',
                              style: SoftType.cellValue,
                            ),
                            Text(
                              'Poblacion · Open · Capacity 400 · sample',
                              style: SoftType.greetingHi,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: SoftColors.muted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: G5Button(
                        label: 'Call hotline',
                        icon: Icons.phone_outlined,
                        kind: G5ButtonKind.danger,
                        onPressed: () => setState(() => _hotline = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: G5Button(
                        label: 'Directions',
                        icon: Icons.near_me_outlined,
                        kind: G5ButtonKind.outline,
                        onPressed: _directions,
                      ),
                    ),
                  ],
                ),
                const G5Honesty(
                  strong: true,
                  icon: Icons.warning_amber_rounded,
                  lead: 'Sample advisory, not a live alert.',
                  rest:
                      'No PAGASA or MDRRMO feed is connected. In a real emergency call 911 and follow official Teresa announcements.',
                ),
              ],
            ],
          ),
        ),
        if (_hotline) _hotlineSheet(context),
      ],
    );
  }

  Widget _advisoryCard({required bool skeleton}) {
    return G5Card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              gradient: LinearGradient(
                begin: Alignment(-0.6, -1),
                end: Alignment(0.8, 1),
                colors: [SoftColors.dangerSoft, SoftColors.endedWash],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SoftColors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: SoftShadows.cardSm,
                  ),
                  child: const Icon(
                    Icons.thunderstorm_outlined,
                    size: 22,
                    color: SoftColors.danger,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          DetailChip(
                            label: 'Urgent',
                            background: SoftColors.dangerSoft,
                            foreground: SoftColors.danger,
                            leadingDot: true,
                          ),
                          DetailChip(
                            label: 'Sample advisory',
                            background: SoftColors.endedWash,
                            foreground: SoftColors.endedInk,
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text('Heavy rain & flood advisory', style: SoftType.name),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: skeleton
                ? const Column(
                    children: [
                      _Skel(width: 0.7),
                      SizedBox(height: 8),
                      _Skel(width: 0.9),
                      SizedBox(height: 8),
                      _Skel(width: 0.8),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              teresaRizalSealAsset,
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MDRRMO · Teresa, Rizal',
                                  style: SoftType.greetingHi,
                                ),
                                Text(
                                  'Issued Sep 25, 2026 · 8:10 AM · sample',
                                  style: SoftType.cellLabel,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Continuous heavy rain may cause flooding in low-lying areas and along creeks. Prepare go-bags and be ready to move to the nearest evacuation center if advised.',
                        style: detailBody.copyWith(color: SoftColors.ink),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _hotlineSheet(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: SoftColors.ink.withValues(alpha: 0.42),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: SoftColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: SoftColors.toggleTrack,
                        borderRadius: BorderRadius.circular(SoftRadius.pill),
                      ),
                    ),
                  ),
                  const Text('Call a hotline', style: SoftType.pageTitle),
                  const SizedBox(height: 4),
                  const Text(
                    'Opens your phone dialer. Calls are placed by your device, not by this app.',
                    style: detailBody,
                  ),
                  const SizedBox(height: 8),
                  _HotlineRow(
                    icon: Icons.phone_outlined,
                    wash: SoftColors.dangerSoft,
                    color: SoftColors.danger,
                    title: '911',
                    subtitle: 'National emergency hotline',
                    call: G5CallPill(
                      key: const ValueKey('g5-call-911'),
                      enabled: true,
                      onPressed: _call911,
                    ),
                  ),
                  IgnorePointer(
                    key: const ValueKey('g5-hotline-mdrrmo'),
                    child: _HotlineRow(
                      icon: Icons.shield_outlined,
                      wash: SoftColors.chipWash,
                      color: SoftColors.muted,
                      title: 'MDRRMO Teresa',
                      subtitle: '[TO BE PROVIDED]',
                      mutedTitle: true,
                      call: const G5CallPill(
                        key: ValueKey('g5-call-mdrrmo'),
                        enabled: false,
                        label: 'Not yet available',
                      ),
                    ),
                  ),
                  const G5Honesty(
                    lead: 'No invented numbers.',
                    rest:
                        'The local MDRRMO line stays disabled until the Municipality of Teresa confirms it.',
                  ),
                  const SizedBox(height: 14),
                  G5Button(
                    label: 'Cancel',
                    kind: G5ButtonKind.outline,
                    onPressed: () => setState(() => _hotline = false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Skel extends StatelessWidget {
  final double width;
  const _Skel({required this.width});

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: width,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: SoftColors.line,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _BrgyChip extends StatelessWidget {
  final String label;
  const _BrgyChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        border: Border.all(color: SoftColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: SoftColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: SoftType.greetingHi.copyWith(color: SoftColors.ink),
          ),
        ],
      ),
    );
  }
}

class _HotlineRow extends StatelessWidget {
  final IconData icon;
  final Color wash;
  final Color color;
  final String title;
  final String subtitle;
  final bool mutedTitle;
  final Widget call;

  const _HotlineRow({
    required this.icon,
    required this.wash,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.call,
    this.mutedTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SoftColors.line)),
      ),
      child: Row(
        children: [
          G5IconDisc(icon: icon, wash: wash, color: color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SoftType.cellValue.copyWith(
                    color: mutedTitle ? SoftColors.muted : SoftColors.ink,
                  ),
                ),
                Text(subtitle, style: SoftType.greetingHi),
              ],
            ),
          ),
          call,
        ],
      ),
    );
  }
}

class G5CallPill extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onPressed;
  final String label;

  const G5CallPill({
    super.key,
    required this.enabled,
    this.onPressed,
    this.label = 'Call',
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return IgnorePointer(
        child: Text(
          label,
          style: SoftType.greetingHi.copyWith(color: SoftColors.muted),
        ),
      );
    }
    return Semantics(
      button: true,
      label: 'Call 911',
      child: Material(
        color: SoftColors.danger,
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(SoftRadius.pill),
          onTap: onPressed,
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.phone_outlined,
                  size: 13,
                  color: SoftColors.white,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: SoftType.sectionLink.copyWith(color: SoftColors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EvacUpdatePage extends StatelessWidget {
  const EvacUpdatePage({super.key});

  Future<void> _directions() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=Teresa+Municipal+Gym+Poblacion+Teresa+Rizal',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return G5Page(
      title: 'Center detail',
      onBack: () => g5Back(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
        children: [
          const G5Eyebrow(),
          G5Card(
            color: SoftColors.blueSoft,
            borderColor: SoftColors.clear,
            shadow: const [],
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SoftColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 16,
                    color: SoftColors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update · Sep 25, 6:30 AM · sample',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: SoftColors.blueDeep,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Center is open and accepting families from Dalig and San Gabriel.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                          color: SoftColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          G5Card(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 112,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    gradient: SoftColors.eventHeroGradient,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      G5MapPin(),
                      SizedBox(height: 6),
                      Text(
                        'Map preview not available · text address only',
                        style: SoftType.cellLabel,
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          DetailChip(
                            label: 'Sample center',
                            background: SoftColors.endedWash,
                            foreground: SoftColors.endedInk,
                          ),
                          DetailChip(
                            label: 'Open',
                            background: SoftColors.verifiedSoft,
                            foreground: SoftColors.verifiedInk,
                            leadingDot: true,
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Teresa Municipal Gym',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.45,
                          color: SoftColors.ink,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text('Poblacion, Teresa, Rizal', style: detailBody),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _Stat(label: 'Barangay', value: 'Poblacion'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _Stat(label: 'Capacity', value: '400 persons'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const G5Card(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                G5IconDisc(
                  icon: Icons.phone_outlined,
                  wash: SoftColors.blueSoft,
                  color: SoftColors.blue,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact', style: SoftType.cellValue),
                      Text('[TO BE PROVIDED]', style: SoftType.greetingHi),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: G5Button(
                  label: 'Directions',
                  icon: Icons.near_me_outlined,
                  onPressed: _directions,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: G5Button(
                  label: 'Call hotline',
                  icon: Icons.phone_outlined,
                  kind: G5ButtonKind.outline,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const AdvisoryDetailPage(hotlineOpen: true),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const G5Honesty(
            lead: 'Sample update.',
            rest:
                'Status and capacity are simulated. Directions hand off to your maps app. Confirm with MDRRMO during real events.',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return G5Card(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SoftType.cellLabel),
          const SizedBox(height: 4),
          Text(value, style: SoftType.cellValue),
        ],
      ),
    );
  }
}

class TulongProgramPage extends StatelessWidget {
  const TulongProgramPage({super.key});

  void _apply(BuildContext context) {
    CitizenSessionService? session;
    try {
      session = context.read<CitizenSessionService>();
    } catch (_) {
      session = null;
    }
    if (session == null || session.accessLevel != AccessLevel.verified) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GuestGatePage(
            destination: const TulongProgramPage(),
            kindLabel: 'Tulong · Educational Assistance',
            hiddenLine: 'Apply opens after a verified sign-in',
          ),
        ),
      );
      return;
    }
    final item = MockCatalog.assistanceTypes.firstWhere(
      (entry) => entry.key == 'tulong_educational',
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NewRequestScreen(
          category: ServiceCategory.tulong,
          item: item,
          accent: SoftColors.tulongInk,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return G5Page(
      title: 'Tulong program',
      onBack: () => g5Back(context),
      onShare: () => AppDialogs.toast(
        context,
        'Share is a local preview — nothing is posted outside this app.',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
        children: [
          const G5Eyebrow(),
          G5Card(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment(-0.8, -1),
                      end: Alignment(0.8, 1),
                      colors: [SoftColors.tulongSoft, SoftColors.blueSoft],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: SoftColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: SoftShadows.cardSm,
                        ),
                        child: const Icon(
                          Icons.school_outlined,
                          size: 22,
                          color: SoftColors.tulongInk,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                DetailChip(
                                  label: 'Tulong · Educational',
                                  background: SoftColors.white,
                                  foreground: SoftColors.tulongInk,
                                ),
                                DetailChip(
                                  label: 'Applications open',
                                  background: SoftColors.verifiedSoft,
                                  foreground: SoftColors.verifiedInk,
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Educational Assistance',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.45,
                                color: SoftColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  child: Text(
                    'Financial help for qualified senior high school and college students who are residents of Teresa, Rizal. Released through MSWDO.',
                    style: detailBody.copyWith(color: SoftColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const G5Card(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                _Fact(
                  icon: Icons.people_outline,
                  label: 'Who can apply',
                  value: 'Enrolled SHS / college students',
                  note: 'Resident of any of the 9 barangays of Teresa',
                  tulong: true,
                ),
                _Fact(
                  icon: Icons.calendar_today_outlined,
                  label: 'Application window · sample dates',
                  value: 'Sep 25 – Oct 15, 2026',
                  divider: false,
                  tulong: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const G5Card(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Requirements', style: SoftType.cellValue),
                    ),
                    Text('4 items', style: SoftType.cellLabel),
                  ],
                ),
                _Req(n: '1', label: 'Valid ID (student or government)'),
                _Req(n: '2', label: 'Certificate of registration (COR)'),
                _Req(n: '3', label: 'Barangay certificate of residency'),
                _Req(n: '4', label: 'Latest grades / report card', last: true),
              ],
            ),
          ),
          const SizedBox(height: 14),
          G5Button(label: 'Apply now', onPressed: () => _apply(context)),
          const SizedBox(height: 8),
          const Text(
            'Verified accounts only · opens the Tulong request wizard',
            textAlign: TextAlign.center,
            style: SoftType.cellLabel,
          ),
          const G5Honesty(
            lead: 'Sample program.',
            rest:
                'Eligibility, dates, and requirements are preview content — not an official MSWDO call for applications.',
          ),
        ],
      ),
    );
  }
}

class _Req extends StatelessWidget {
  final String n;
  final String label;
  final bool last;
  const _Req({required this.n, required this.label, this.last = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: SoftColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: SoftColors.tulongSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              n,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SoftColors.tulongInk,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: SoftType.bannerTitle.copyWith(color: SoftColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class StaleDeepLinkPage extends StatelessWidget {
  const StaleDeepLinkPage({super.key});

  void _balita(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    RootShell.jumpTo(context, 1);
    if (!context.mounted) return;
    final nav = Navigator.of(context);
    if (nav.canPop()) return;
    nav.push(MaterialPageRoute<void>(builder: (_) => const BalitaScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return G5Page(
      title: 'Update',
      onBack: () => g5Back(context),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 28),
        children: [
          const G5Eyebrow(),
          const SizedBox(height: 28),
          Center(
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: SoftColors.chipWash,
                shape: BoxShape.circle,
                boxShadow: SoftShadows.cardSm,
              ),
              child: const Icon(
                Icons.link_off_rounded,
                size: 30,
                color: SoftColors.muted,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This update is no longer available',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.45,
              color: SoftColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The post may have been removed, or the item was closed by the municipality. There’s nothing you need to do.',
            textAlign: TextAlign.center,
            style: detailBody,
          ),
          const SizedBox(height: 22),
          Text(
            'YOU TAPPED',
            style: SoftType.cellLabel.copyWith(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Opacity(
            opacity: 0.85,
            child: G5Card(
              child: Row(
                children: [
                  G5IconDisc(
                    icon: Icons.notes_rounded,
                    wash: SoftColors.chipWash,
                    color: SoftColors.muted,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Balita',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: SoftColors.muted,
                              ),
                            ),
                            SizedBox(width: 6),
                            DetailChip(
                              label: 'Removed',
                              background: SoftColors.chipWash,
                              foreground: SoftColors.muted,
                            ),
                            Spacer(),
                            Text('Sep 12', style: SoftType.cellLabel),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Road repair schedule, Barangay Prinza',
                          style: SoftType.cellValue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          G5Button(
            label: 'Back to Notifications',
            onPressed: () => g5Back(context),
          ),
          const SizedBox(height: 8),
          G5Button(
            label: 'Go to Balita',
            kind: G5ButtonKind.outline,
            onPressed: () => _balita(context),
          ),
          const G5Honesty(
            lead: 'Frontend simulation.',
            rest:
                'Availability is checked against local sample data only. Ended events open their past-event detail instead of this page.',
          ),
        ],
      ),
    );
  }
}

/// Guest opens a personal request link. The sheet hides status, amount,
/// and name. Sign-in replaces this page with [destination].
class GuestGatePage extends StatelessWidget {
  final Widget destination;
  final String kindLabel;
  final String hiddenLine;

  const GuestGatePage({
    super.key,
    required this.destination,
    this.kindLabel = 'Tulong · Request update',
    this.hiddenLine = 'Details hidden until you sign in',
  });

  Future<void> _auth(BuildContext context, {required bool register}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => register ? const RegisterScreen() : const LoginScreen(),
      ),
    );
    if (!context.mounted) return;
    CitizenSessionService? session;
    try {
      session = context.read<CitizenSessionService>();
    } catch (_) {
      return;
    }
    if (session.account != null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        G5Page(
          title: 'Request',
          onBack: _noop,
          body: Padding(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                G5Eyebrow(),
                _Skel(width: 0.4),
                SizedBox(height: 10),
                _Skel(width: 0.7),
                SizedBox(height: 12),
                _Skel(width: 0.34),
                SizedBox(height: 16),
                G5Card(child: SizedBox(height: 88)),
                SizedBox(height: 12),
                G5Card(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: ColoredBox(
            color: SoftColors.ink.withValues(alpha: 0.42),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Material(
                color: SoftColors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: SoftColors.toggleTrack,
                          borderRadius: BorderRadius.circular(SoftRadius.pill),
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: SoftColors.blueSoft,
                          shape: BoxShape.circle,
                          boxShadow: SoftShadows.cardSm,
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 26,
                          color: SoftColors.blue,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sign in to open this update',
                        textAlign: TextAlign.center,
                        style: SoftType.pageTitle,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'This notification is about a personal request. Sign in with the account that submitted it — we’ll take you straight there.',
                        textAlign: TextAlign.center,
                        style: detailBody,
                      ),
                      const SizedBox(height: 14),
                      G5Card(
                        color: SoftColors.blueWash,
                        borderColor: SoftColors.line,
                        shadow: const [],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const G5IconDisc(
                              icon: Icons.favorite_border_rounded,
                              wash: SoftColors.tulongSoft,
                              color: SoftColors.tulongInk,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kindLabel,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: SoftColors.tulongInk,
                                    ),
                                  ),
                                  Text(hiddenLine, style: SoftType.bannerTitle),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 16,
                              color: SoftColors.muted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const G5Card(
                        color: SoftColors.blueSoft,
                        borderColor: SoftColors.clear,
                        shadow: [],
                        child: Text.rich(
                          TextSpan(
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                              color: SoftColors.ink,
                            ),
                            children: [
                              TextSpan(
                                text: 'Frontend simulation',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextSpan(
                                text:
                                    ' — Guest / account gates are local preview state. No live LGU account or push backend.',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      G5Button(
                        label: 'Sign in',
                        onPressed: () => _auth(context, register: false),
                      ),
                      const SizedBox(height: 8),
                      G5Button(
                        label: 'Create account',
                        kind: G5ButtonKind.outline,
                        onPressed: () => _auth(context, register: true),
                      ),
                      const SizedBox(height: 4),
                      G5Button(
                        label: 'Back to Notifications',
                        kind: G5ButtonKind.text,
                        onPressed: () => g5Back(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _noop() {}
