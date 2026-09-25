import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../services/mock_catalog.dart';
import '../../screens/shared/event_poster_viewer.dart';
import 'event_detail_screen.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../../widgets/event_card.dart';
import '../home/root_shell.dart';

enum _EventFilter { upcoming, past, free }

/// Events branch. Cards keep the catalog titles. Posters that are not
/// Teresa, Rizal art stay a dashed 16:9 slot, including inside the poster
/// viewer.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  _EventFilter _filter = _EventFilter.upcoming;

  List<EventItem> _visible() {
    final events = MockCatalog.events;
    return switch (_filter) {
      _EventFilter.upcoming => events.where((e) => e.upcoming).toList(),
      _EventFilter.past => events.where((e) => !e.upcoming).toList(),
      _EventFilter.free => events.where((e) => e.isFree).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final events = _visible();
    final bottom = MediaQuery.paddingOf(context).bottom;
    final showNextUp = _filter == _EventFilter.upcoming && events.isNotEmpty;

    return SoftWash(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leadingWidth: 56,
          leading: Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SoftCircleButton(
                icon: Icons.menu_rounded,
                tooltip: 'Menu',
                onPressed: () => RootShell.openDrawer(context),
              ),
            ),
          ),
          title: const Text('Events', style: SoftType.pageTitle),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: AlertsAction()),
            ),
          ],
        ),
        body: ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + bottom),
          itemCount: 1 + (showNextUp ? 1 : 0) + (events.isEmpty ? 1 : events.length),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _EventsHeader(
                  filter: _filter,
                  onFilter: (next) => setState(() => _filter = next),
                ),
              );
            }
            var cursor = 1;
            if (showNextUp) {
              if (i == cursor) return _NextUp(event: events.first);
              cursor += 1;
            }
            if (events.isEmpty) {
              return const QuietWashNote(
                'Nothing on this list yet. Teresa, Rizal will post schedules here.',
              );
            }
            return EventCard(event: events[i - cursor]);
          },
        ),
      ),
    );
  }
}

class _EventsHeader extends StatelessWidget {
  final _EventFilter filter;
  final ValueChanged<_EventFilter> onFilter;

  const _EventsHeader({required this.filter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TERESA, RIZAL',
          style: SoftType.cellLabel.copyWith(letterSpacing: 0.22),
        ),
        const SizedBox(height: 4),
        const Text('Events', style: SoftType.h1),
        const SizedBox(height: 6),
        const Text(
          'Schedules and programs posted by Teresa, Rizal.',
          style: SoftType.body,
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PillChip(
                label: 'Upcoming',
                selected: filter == _EventFilter.upcoming,
                onTap: () => onFilter(_EventFilter.upcoming),
              ),
              const SizedBox(width: 8),
              _PillChip(
                label: 'Past',
                selected: filter == _EventFilter.past,
                onTap: () => onFilter(_EventFilter.past),
              ),
              const SizedBox(width: 8),
              _PillChip(
                label: 'Free',
                selected: filter == _EventFilter.free,
                onTap: () => onFilter(_EventFilter.free),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? SoftColors.blue : SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: onTap,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: Border.all(color: selected ? SoftColors.blue : SoftColors.line),
          ),
          child: Text(
            label,
            style: SoftType.sectionLink.copyWith(
              color: selected ? SoftColors.white : SoftColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

class _NextUp extends StatelessWidget {
  final EventItem event;
  const _NextUp({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(SoftRadius.lg),
          onTap: () => EventDetailScreen.open(context, event),
          child: Ink(
            decoration: BoxDecoration(
              gradient: SoftColors.primaryGradient,
              borderRadius: BorderRadius.circular(SoftRadius.lg),
              boxShadow: SoftShadows.primary,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Next up', style: SoftType.onFeatureEyebrow),
                const SizedBox(height: 6),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SoftType.onFeatureTitle,
                ),
                const SizedBox(height: 8),
                Text('${event.date} · ${event.time}', style: SoftType.onFeatureEyebrow),
                const SizedBox(height: 2),
                Text(event.venue, style: SoftType.onFeatureEyebrow),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => EventPosterViewer.open(context, event),
                  child: Text(
                    'View poster',
                    style: SoftType.sectionLink.copyWith(color: SoftColors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
