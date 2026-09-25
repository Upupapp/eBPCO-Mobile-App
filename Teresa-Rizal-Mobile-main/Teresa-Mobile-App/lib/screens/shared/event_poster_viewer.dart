import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';

/// Full-screen event poster. Pinch-to-zoom uses [InteractiveViewer].
/// When Teresa, Rizal poster art is missing, the stand-in is a dashed
/// 16:9 slot — the same slot the list card uses.
class EventPosterViewer extends StatelessWidget {
  final EventItem event;
  const EventPosterViewer({super.key, required this.event});

  static void open(BuildContext context, EventItem event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventPosterViewer(event: event),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width - 32;
    final slotHeight = width * 9 / 16;

    return SoftWash(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                child: Row(
                  children: [
                    SoftCircleButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SoftType.name,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: SizedBox(
                      width: width,
                      height: event.imagePath == null ? slotHeight : null,
                      child: event.imagePath == null
                          ? const DashedBannerSlot(
                              label: 'Poster slot',
                              caption: '16:9 · art pending',
                            )
                          : Image.asset(event.imagePath!, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.date, style: SoftType.name),
                    const SizedBox(height: 4),
                    Text('${event.time} · ${event.venue}', style: SoftType.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
