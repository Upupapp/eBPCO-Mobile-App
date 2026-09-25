import 'package:flutter/material.dart';

import '../../models/announcement.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/app_dialogs.dart';
import '../shared/detail_chrome.dart';

/// Pack C event landing. Calendar and RSVP are a local preview — nothing
/// is booked with the LGU. The poster well stays dashed until Teresa art
/// exists. Address is text only.
///
/// [openedFromNotification] paints the deep-link eyebrow. The Health
/// Caravan inbox row sets it. Other inbox rows do not.
///
/// "I'm interested" starts off for the upcoming frame and for the
/// notification landing. Past events keep the control disabled.
class EventDetailScreen extends StatefulWidget {
  final EventItem event;
  final bool openedFromNotification;

  const EventDetailScreen({
    super.key,
    required this.event,
    this.openedFromNotification = false,
  });

  static void open(
    BuildContext context,
    EventItem event, {
    bool openedFromNotification = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventDetailScreen(
          event: event,
          openedFromNotification: openedFromNotification,
        ),
      ),
    );
  }

  /// Inbox landing for the Health Caravan row. Same event, eyebrow on.
  static void openFromNotification(BuildContext context, EventItem event) {
    open(context, event, openedFromNotification: true);
  }

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  bool _interested = false;

  EventItem get event => widget.event;
  bool get past => !event.upcoming;

  @override
  Widget build(BuildContext context) {
    return DetailScaffold(
      title: 'Event',
      openedFromNotification: widget.openedFromNotification,
      onBack: () => Navigator.of(context).maybePop(),
      onShare: () => AppDialogs.toast(
        context,
        'Share is a local preview — nothing is posted outside this app.',
      ),
      children: [
        PendingPosterSlot(past: past),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (event.isFree)
              const DetailChip(
                label: 'Free',
                background: freeChipWash,
                foreground: SoftColors.verifiedInk,
              ),
            if (!past)
              const DetailChip(
                label: 'Upcoming',
                background: SoftColors.blueSoft,
                foreground: SoftColors.blueDeep,
              ),
            if (past) ...[
              const DetailChip(
                label: 'Past',
                background: pastChipWash,
                foreground: SoftColors.muted,
              ),
              const DetailChip(
                label: 'Ended',
                background: SoftColors.endedWash,
                foreground: endedInk,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(event.title, style: detailHeadline),
        if (!past && (event.summary ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(event.summary!, style: detailBody),
        ],
        if (past) ...[
          const SizedBox(height: 12),
          SoftPanel(
            tone: SoftPanelTone.gold,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This event has ended',
                  style: TextStyle(
                    fontFamily: AppTypography.sans,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.26,
                    color: endedInk,
                    fontFeatures: SoftType.features,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event.endedDetail ??
                      'RSVP and calendar add are unavailable for past events in this preview.',
                  style: detailBody.copyWith(fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        SoftPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Column(
            children: [
              _Fact(
                icon: Icons.calendar_today_outlined,
                label: 'When',
                value: event.whenLine,
                muted: past,
              ),
              const Divider(height: 1, thickness: 1, color: SoftColors.line),
              _Fact(
                icon: Icons.location_on_outlined,
                label: 'Where',
                value: event.venue,
                note: past ? null : event.whereNote,
                muted: past,
              ),
            ],
          ),
        ),
        if (event.agenda.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Agenda',
                style: TextStyle(
                  fontFamily: AppTypography.sans,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.28,
                  color: SoftColors.ink,
                  fontFeatures: SoftType.features,
                ),
              ),
            ),
          ),
          SoftPanel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < event.agenda.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: SoftColors.line,
                    ),
                  _AgendaLine(index: i + 1, text: event.agenda[i], muted: past),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        SoftPanel(
          tone: past ? SoftPanelTone.muted : SoftPanelTone.white,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: InkWell(
            onTap: past
                ? null
                : () => setState(() => _interested = !_interested),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "I'm interested",
                        style: TextStyle(
                          fontFamily: AppTypography.sans,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.28,
                          color: past ? SoftColors.muted : SoftColors.ink,
                          fontFeatures: SoftType.features,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        past
                            ? 'RSVP disabled — event has ended'
                            : 'Interest is local preview — not ticketed registration',
                        style: detailBody.copyWith(fontSize: 12, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InterestToggle(
                  key: const Key('interest-toggle'),
                  on: past ? false : _interested,
                  enabled: !past,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (past) ...[
          const DetailPillButton(
            key: Key('add-to-calendar'),
            label: 'Add to calendar',
            icon: Icons.calendar_today_outlined,
            muted: true,
          ),
          const SizedBox(height: 8),
          DetailPillButton(
            label: 'Share',
            icon: Icons.ios_share_rounded,
            onPressed: () => AppDialogs.toast(
              context,
              'Share is a local preview — nothing is posted outside this app.',
            ),
          ),
        ] else ...[
          Row(
            children: [
              Expanded(
                child: DetailPillButton(
                  key: const Key('add-to-calendar'),
                  label: 'Add to calendar',
                  icon: Icons.calendar_today_outlined,
                  primary: true,
                  onPressed: () => AppDialogs.toast(
                    context,
                    'Opens device calendar / local preview — not a live LGU booking.',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DetailPillButton(
                  label: 'Share',
                  icon: Icons.ios_share_rounded,
                  onPressed: () => AppDialogs.toast(
                    context,
                    'Share is a local preview — nothing is posted outside this app.',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Opens device calendar / local preview — not a live LGU booking.',
            textAlign: TextAlign.center,
            style: SoftType.cellLabel.copyWith(height: 1.3),
          ),
        ],
      ],
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? note;
  final bool muted;

  const _Fact({
    required this.icon,
    required this.label,
    required this.value,
    this.note,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = muted ? SoftColors.muted : SoftColors.blue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: muted ? pastChipWash : SoftColors.blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 16, color: iconColor),
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
                  style: TextStyle(
                    fontFamily: AppTypography.sans,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.28,
                    height: 1.3,
                    color: muted ? SoftColors.muted : SoftColors.ink,
                    fontFeatures: SoftType.features,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(note!, style: SoftType.cellLabel),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaLine extends StatelessWidget {
  final int index;
  final String text;
  final bool muted;

  const _AgendaLine({
    required this.index,
    required this.text,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: muted ? pastChipWash : SoftColors.blueSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontFamily: AppTypography.sans,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: muted ? SoftColors.muted : SoftColors.blueDeep,
                fontFeatures: SoftType.features,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTypography.sans,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
                letterSpacing: -0.13,
                color: muted ? SoftColors.muted : SoftColors.ink,
                fontFeatures: SoftType.features,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
