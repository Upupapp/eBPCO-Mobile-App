import 'package:flutter/material.dart';
import '../../theme/g6_tokens.dart';
import 'package:provider/provider.dart';

import '../../services/citizen_session_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../auth/register_screen.dart';
import 'g6/digital_id_card.dart';
import 'g6/g6_chrome.dart';
import 'g6/g6_sample.dart';
import 'g6/resident_id.dart';

/// Which Pack F frame to pose. Null follows the signed-in account.
enum G6IdShot { front, back, flip, fullscreen, locked }

/// Resident Digital ID. Only a verified holder gets a card. Household
/// members do not. Photo and QR stay dashed placeholders.
class DigitalIdScreen extends StatelessWidget {
  final G6IdShot? shot;

  const DigitalIdScreen({super.key, this.shot});

  @override
  Widget build(BuildContext context) {
    switch (shot) {
      case G6IdShot.fullscreen:
        return const DigitalIdFullscreenPage(data: DigitalIdData.pack);
      case G6IdShot.locked:
        return const _LockedPage();
      case G6IdShot.front:
        return const _VerifiedPage(data: DigitalIdData.pack);
      case G6IdShot.back:
        return const _VerifiedPage(
          data: DigitalIdData.pack,
          initiallyBack: true,
        );
      case G6IdShot.flip:
        return const _VerifiedPage(
          data: DigitalIdData.pack,
          annotateFlip: true,
        );
      case null:
        return const _Live();
    }
  }
}

class _Live extends StatelessWidget {
  const _Live();

  @override
  Widget build(BuildContext context) {
    final account = context.watch<CitizenSessionService>().account;
    if (!ResidentId.isVerified(account) || account == null) {
      return const _LockedPage();
    }
    final address = account.address.trim().isEmpty
        ? '${account.purok}, ${account.barangay}, Teresa, Rizal'
        : account.address;
    return _VerifiedPage(
      data: DigitalIdData.forAccount(
        holderName: account.fullName,
        barangay: account.barangay,
        address: address,
        verified: true,
      ),
    );
  }
}

class _VerifiedPage extends StatefulWidget {
  final DigitalIdData data;
  final bool initiallyBack;
  final bool annotateFlip;

  const _VerifiedPage({
    required this.data,
    this.initiallyBack = false,
    this.annotateFlip = false,
  });

  @override
  State<_VerifiedPage> createState() => _VerifiedPageState();
}

class _VerifiedPageState extends State<_VerifiedPage> {
  final GlobalKey<DigitalIdCardState> _cardKey =
      GlobalKey<DigitalIdCardState>();
  late bool _showingBack = widget.initiallyBack;

  void _tick() {
    final showing = _cardKey.currentState?.showingBack ?? _showingBack;
    if (!mounted) return;
    setState(() => _showingBack = showing);
  }

  void _openFull() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DigitalIdFullscreenPage(
          data: widget.data,
          initiallyBack: _showingBack,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t =
        _cardKey.currentState?.linearT ?? (widget.initiallyBack ? 1.0 : 0.0);
    return G6Shell(
      title: 'Digital ID',
      actions: [
        SoftCircleButton(
          icon: Icons.fullscreen_rounded,
          tooltip: 'Full screen',
          onPressed: _openFull,
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          DigitalIdStage(
            data: widget.data,
            initiallyBack: widget.initiallyBack,
            cardKey: _cardKey,
            onTick: _tick,
          ),
          if (widget.annotateFlip) ...[
            const SizedBox(height: 14),
            _FlipSpec(progress: t),
          ] else if (_showingBack)
            _BackDetails(data: widget.data)
          else
            _FrontDetails(data: widget.data, onFull: _openFull),
        ],
      ),
    );
  }
}

class _FrontDetails extends StatelessWidget {
  final DigitalIdData data;
  final VoidCallback onFull;
  const _FrontDetails({required this.data, required this.onFull});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        _DetailCard(
          rows: [
            _DetailRow('Card holder', data.holderName),
            _DetailRow(
              'Resident ID',
              data.residentId,
              sub: data.sampleTagged ? 'Sample number, not issued' : null,
            ),
            const _DetailRow(
              'Issuer',
              'Municipality of Teresa, Rizal',
              sub: 'Mock preview',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: SoftColors.blueWash,
            borderRadius: BorderRadius.circular(SoftRadius.md),
            border: Border.all(color: SoftColors.line),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Not a real government ID',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: G6Type.px14,
                  fontWeight: FontWeight.w500,
                  color: SoftColors.ink,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'This card is a frontend mock. It is not an official PhilSys or LGU-issued credential and has no live civil registry link.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: G6Type.px12,
                  height: 1.4,
                  color: SoftColors.muted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        G6Button(
          label: 'View full screen',
          kind: G6ButtonKind.outline,
          icon: Icons.fullscreen_rounded,
          onPressed: onFull,
        ),
      ],
    );
  }
}

class _BackDetails extends StatelessWidget {
  final DigitalIdData data;
  const _BackDetails({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Emergency contact', style: SoftType.name),
            const Spacer(),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sample contact. Saved on this device.'),
                  ),
                );
              },
              child: const Text(
                'Change',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: G6Type.px13,
                  fontWeight: FontWeight.w500,
                  color: SoftColors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: SoftColors.white,
            borderRadius: BorderRadius.circular(SoftRadius.lg),
            border: Border.all(color: SoftColors.lineSoft),
            boxShadow: SoftShadows.cardSm,
          ),
          child: Row(
            children: [
              G6Initials(
                initials: data.emergencyInitials,
                tone: G6AvatarTone.blue,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.emergencyName, style: SoftType.name),
                    const SizedBox(height: 2),
                    Text(
                      '${data.emergencyRole} · picked from your household',
                      style: SoftType.cellLabel,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: SoftColors.muted),
            ],
          ),
        ),
        const G6Honesty(
          lead: 'QR is a placeholder, not scannable.',
          rest:
              'No live verification service reads this card. Blood type and contact are sample data you control on this device.',
          tone: G6HonestyTone.gold,
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<Widget> rows;
  const _DetailCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: SoftColors.lineSoft),
        boxShadow: SoftShadows.cardSm,
      ),
      child: Column(children: rows),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  const _DetailRow(this.label, this.value, {this.sub});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: SoftType.cellLabel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: G6Type.px13,
                    fontWeight: FontWeight.w500,
                    color: SoftColors.ink,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    textAlign: TextAlign.right,
                    style: SoftType.cellLabel,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipSpec extends StatelessWidget {
  final double progress;
  const _FlipSpec({required this.progress});

  @override
  Widget build(BuildContext context) {
    const rows = <(String, String)>[
      ('Duration', '420ms total · face swap at 210ms (90°)'),
      ('Curve', 'easeInOutCubic · cubic-bezier(.65,0,.35,1)'),
      (
        '3D',
        'rotateY 0 → 180° · perspective 1200px (Flutter Matrix4 entry(3,2) = 0.0008) · pivot card centre',
      ),
      (
        'Depth',
        'scale 1 → .96 → 1 · shadow blur 34 → 18 → 34 · edge shade up to 34% at 90°',
      ),
      (
        'Haptic',
        'HapticFeedback.lightImpact on tap (flip start), once per flip',
      ),
      ('Hint', '“Tap the card to flip” under the card; hides after 2 flips'),
      ('Reduce motion', '150ms crossfade, no rotation · haptic still fires'),
      (
        'A11y',
        'Announce “Showing back of card” · toggle is the non-gesture path',
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: G6Palette.ink90,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text.rich(
            TextSpan(
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: G6Type.px11,
                height: 1.4,
                color: SoftColors.white,
              ),
              children: [
                TextSpan(
                  text: 'Flip motion spec',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: SoftColors.avatarStart,
                  ),
                ),
                TextSpan(text: ' · tap card or Front | Back toggle'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: G6Type.px11,
                        fontWeight: FontWeight.w500,
                        color: SoftColors.avatarStart,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: G6Type.px11,
                        height: 1.35,
                        color: SoftColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: CustomPaint(
              painter: _FlipTimelinePainter(progress.clamp(0, 1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlipTimelinePainter extends CustomPainter {
  final double progress;
  _FlipTimelinePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    const y = 8.0;
    final track = RRect.fromLTRBR(
      0,
      y,
      size.width,
      y + 4,
      const Radius.circular(99),
    );
    canvas.drawRRect(track, Paint()..color = G6Palette.white18);
    canvas.drawRRect(
      RRect.fromLTRBR(
        0,
        y,
        size.width * progress,
        y + 4,
        const Radius.circular(99),
      ),
      Paint()..color = SoftColors.gold,
    );
    final tick = Paint()..color = G6Palette.white55;
    for (final x in [1.0, size.width * 0.5, size.width - 1]) {
      canvas.drawRRect(
        RRect.fromLTRBR(x - 1, 4, x + 1, 18, const Radius.circular(1)),
        tick,
      );
    }
    _label(canvas, '0 · tap', 0, size.width);
    _label(canvas, '210 · swap', size.width * 0.5, size.width);
    _label(canvas, '420 · settle', size.width - 4, size.width, right: true);
  }

  void _label(
    Canvas canvas,
    String text,
    double x,
    double width, {
    bool right = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: G6Type.px9_5,
          color: G6Palette.white72,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = x - painter.width / 2;
    if (right) dx = width - painter.width;
    if (dx < 0) dx = 0;
    painter.paint(canvas, Offset(dx, 20));
  }

  @override
  bool shouldRepaint(covariant _FlipTimelinePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Landscape presentation inside the portrait bezel. The device orientation
/// stays put so a portrait screenshot can still show this frame.
class DigitalIdFullscreenPage extends StatefulWidget {
  final DigitalIdData data;
  final bool initiallyBack;

  const DigitalIdFullscreenPage({
    super.key,
    required this.data,
    this.initiallyBack = false,
  });

  @override
  State<DigitalIdFullscreenPage> createState() =>
      _DigitalIdFullscreenPageState();
}

class _DigitalIdFullscreenPageState extends State<DigitalIdFullscreenPage> {
  final GlobalKey<DigitalIdCardState> _cardKey =
      GlobalKey<DigitalIdCardState>();
  late bool _showingBack = widget.initiallyBack;

  void _flip() => _cardKey.currentState?.flip();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return SoftWash(
      child: Scaffold(
        backgroundColor: SoftColors.page,
        body: Center(
          child: RotatedBox(
            quarterTurns: 1,
            child: SizedBox(
              width: size.height,
              height: size.width,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        G6CloseButton(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Digital ID',
                            textAlign: TextAlign.center,
                            style: SoftType.pageTitle,
                          ),
                        ),
                        _MiniToggle(showingBack: _showingBack, onFlip: _flip),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 358 * 1.2,
                        height: 226 * 1.2,
                        child: DigitalIdCard(
                          key: _cardKey,
                          data: widget.data,
                          initiallyBack: widget.initiallyBack,
                          onChanged: () {
                            final showing =
                                _cardKey.currentState?.showingBack ??
                                _showingBack;
                            if (showing != _showingBack && mounted) {
                              setState(() => _showingBack = showing);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      'Screen stays awake and bright while open · tap card to flip · mock card, not a government ID',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: G6Type.px11,
                        color: SoftColors.muted,
                      ),
                    ),
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

class _MiniToggle extends StatelessWidget {
  final bool showingBack;
  final VoidCallback onFlip;
  const _MiniToggle({required this.showingBack, required this.onFlip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: SoftColors.line),
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
        padding: const EdgeInsets.symmetric(horizontal: 12),
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

class _LockedPage extends StatelessWidget {
  const _LockedPage();

  @override
  Widget build(BuildContext context) {
    return G6Shell(
      title: 'Digital ID',
      footer: G6Footer(
        child: G6Button(
          label: 'Continue verification',
          onPressed: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: const [
          _UnverifiedPill(),
          SizedBox(height: 10),
          Text('Your Digital ID is locked', style: SoftType.h1),
          SizedBox(height: 6),
          Text(
            'It unlocks after the Municipality of Teresa, Rizal verifies your resident account.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: G6Type.px13,
              height: 1.4,
              color: SoftColors.muted,
            ),
          ),
          SizedBox(height: 14),
          _LockedSkeleton(),
          SizedBox(height: 14),
          _VerifyChecklist(),
          G6Honesty(
            lead: 'Mock card.',
            rest:
                'Verification here is simulated. No civil registry or PhilSys check.',
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _UnverifiedPill extends StatelessWidget {
  const _UnverifiedPill();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: G6Palette.cream,
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: SoftColors.endedInk,
                shape: BoxShape.circle,
              ),
              child: SizedBox(width: 6, height: 6),
            ),
            SizedBox(width: 6),
            Text(
              'Unverified',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: G6Type.px11,
                fontWeight: FontWeight.w500,
                color: SoftColors.endedInk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedSkeleton extends StatelessWidget {
  const _LockedSkeleton();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 358 / 226,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: G6Palette.mist,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const SizedBox.expand(),
          ),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: SoftColors.white,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: SoftColors.blue,
                    size: 20,
                  ),
                ),
              ),
              SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: SoftColors.white,
                  borderRadius: BorderRadius.all(Radius.circular(99)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'Locked until verified',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: G6Type.px12,
                      fontWeight: FontWeight.w500,
                      color: SoftColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerifyChecklist extends StatelessWidget {
  const _VerifyChecklist();

  @override
  Widget build(BuildContext context) {
    const rows = <(IconData, Color, String, String, Color)>[
      (
        Icons.check_rounded,
        SoftColors.verifiedInk,
        'Personal information',
        'Done',
        SoftColors.muted,
      ),
      (
        Icons.check_rounded,
        SoftColors.verifiedInk,
        'Valid ID upload',
        'Done',
        SoftColors.muted,
      ),
      (
        Icons.more_horiz_rounded,
        SoftColors.endedInk,
        'Face check',
        'Next',
        SoftColors.endedInk,
      ),
      (
        Icons.schedule_rounded,
        SoftColors.muted,
        'LGU review',
        'After submit',
        SoftColors.muted,
      ),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      decoration: BoxDecoration(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        border: Border.all(color: SoftColors.lineSoft),
        boxShadow: SoftShadows.cardSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('Finish verification', style: SoftType.name),
          ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(row.$1, size: 16, color: row.$2),
                  const SizedBox(width: 10),
                  Expanded(child: Text(row.$3, style: SoftType.cellValue)),
                  Text(
                    row.$4,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: G6Type.px12,
                      fontWeight: FontWeight.w500,
                      color: row.$5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
