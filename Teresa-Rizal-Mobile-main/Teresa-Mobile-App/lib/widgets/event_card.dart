import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/shared/event_poster_viewer.dart';
import '../theme/app_colors.dart';
import '../theme/soft_widget.dart';
import 'app_card.dart';
import 'soft_chrome.dart';

/// One event as its own independent card — used on both Home's "Upcoming
/// Events" preview ([compact]) and the dedicated Events list. Never
/// stacks multiple events into one shared container: each [EventCard]
/// renders exactly one [EventItem].
///
/// The poster (when present) is shown with `BoxFit.contain` inside a
/// full-width box — never `BoxFit.cover` — so dates/times/team names
/// printed on the poster are never cropped off; any letterboxing just
/// shows a neutral background rather than losing content. Tapping the
/// card opens [EventDetailScreen]. "View poster" still opens
/// [EventPosterViewer].
class EventCard extends StatelessWidget {
  final EventItem event;
  final bool compact;

  const EventCard({super.key, required this.event, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 10 : 18),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => EventDetailScreen.open(context, event),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imagePath == null)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: DashedBannerSlot(
                  label: 'Poster slot',
                  caption: '16:9 · art pending',
                ),
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Container(
                  color: AppColors.slate100,
                  constraints: BoxConstraints(maxHeight: compact ? 220 : 420),
                  width: double.infinity,
                  // Decode at the card's actual bounded width rather than
                  // the source poster's full resolution — BoxFit.contain
                  // never crops, so scaling decode to width alone (letting
                  // height follow proportionally) can't distort or crop it.
                  child: LayoutBuilder(
                    builder: (context, constraints) => Image.asset(
                      event.imagePath!,
                      fit: BoxFit.contain,
                      cacheWidth: constraints.hasBoundedWidth
                          ? (constraints.maxWidth *
                                    MediaQuery.devicePixelRatioOf(context))
                                .round()
                          : null,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: SoftType.name,
                        ),
                      ),
                      if (event.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: SoftColors.blueWash,
                            borderRadius: BorderRadius.circular(SoftRadius.pill),
                          ),
                          child: Text(
                            event.category!,
                            style: SoftType.cellLabel.copyWith(
                              color: SoftColors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  _MetaRow(
                    icon: Icons.calendar_today_rounded,
                    text: event.date,
                  ),
                  const SizedBox(height: 4),
                  _MetaRow(icon: Icons.schedule_rounded, text: event.time),
                  const SizedBox(height: 4),
                  _MetaRow(icon: Icons.place_outlined, text: event.venue),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => EventPosterViewer.open(context, event),
                    child: const Row(
                      children: [
                        Flexible(
                          child: Text(
                            'View poster',
                            textWidthBasis: TextWidthBasis.longestLine,
                            overflow: TextOverflow.ellipsis,
                            style: SoftType.sectionLink,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.open_in_full_rounded,
                          size: 12,
                          color: SoftColors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: SoftColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: SoftType.cellLabel.copyWith(height: 1.3),
          ),
        ),
      ],
    );
  }
}
