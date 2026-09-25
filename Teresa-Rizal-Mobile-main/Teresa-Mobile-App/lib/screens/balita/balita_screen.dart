import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../services/balita_service.dart';
import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';
import '../home/root_shell.dart';
import 'post_card.dart';

/// Balita ("news" in Filipino) — a community social feed. The mobile app is
/// consumption-only: there is no composer for any account state. Liking,
/// commenting, and sharing stay a local simulation in [BalitaService].
class BalitaScreen extends StatefulWidget {
  const BalitaScreen({super.key});

  @override
  State<BalitaScreen> createState() => _BalitaScreenState();
}

class _BalitaScreenState extends State<BalitaScreen> {
  static const _chips = ['Lahat', 'Abiso', 'Programa'];
  String _chip = 'Lahat';

  List<Announcement> _visible(List<Announcement> posts) {
    if (_chip == 'Lahat') return posts;
    return posts.where((p) => p.kind == _chip).toList();
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaService>();
    final posts = _visible(balita.posts);
    final bottom = MediaQuery.paddingOf(context).bottom;

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
          title: const Text('Balita', style: SoftType.pageTitle),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(child: AlertsAction()),
            ),
          ],
        ),
        body: balita.posts.isEmpty
            ? Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + bottom),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BalitaHeader(showChips: false),
                    Expanded(child: _BalitaEmpty()),
                  ],
                ),
              )
            : ListView.builder(
          key: const ValueKey('balita-feed'),
          padding: EdgeInsets.fromLTRB(16, 4, 16, 24 + bottom),
          itemCount: posts.isEmpty ? 2 : posts.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _BalitaHeader(
                  showChips: true,
                  chip: _chip,
                  chips: _chips,
                  onChip: (label) => setState(() => _chip = label),
                ),
              );
            }
            if (posts.isEmpty) {
              return const QuietWashNote(
                'No announcements in this filter yet. Check back for updates from Teresa, Rizal.',
              );
            }
            final p = posts[i - 1];
            return PostCard(
              key: ValueKey(p.id),
              post: p,
              onLike: () => balita.toggleLike(p.id),
              onComment: (c) => balita.addComment(p.id, c),
              onShare: () => balita.share(p.id),
            );
          },
        ),
      ),
    );
  }
}

class _BalitaHeader extends StatelessWidget {
  final bool showChips;
  final String chip;
  final List<String> chips;
  final ValueChanged<String> onChip;

  const _BalitaHeader({
    required this.showChips,
    this.chip = 'Lahat',
    this.chips = const [],
    this.onChip = _noop,
  });

  static void _noop(String _) {}

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Municipal news', style: SoftType.eyebrow),
        const SizedBox(height: 4),
        const Text('Balita', style: SoftType.h1),
        if (showChips) ...[
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < chips.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  _PillChip(
                    label: chips[i],
                    selected: chip == chips[i],
                    onTap: () => onChip(chips[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BalitaEmpty extends StatelessWidget {
  const _BalitaEmpty();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: SoftColors.blueSoft,
              borderRadius: BorderRadius.circular(SoftRadius.lg),
            ),
            child: const Icon(Icons.notes_rounded, color: SoftColors.blue, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: SoftType.section.copyWith(
              fontWeight: FontWeight.w600,
              color: SoftColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Announcements from Teresa, Rizal will appear here when published.',
            textAlign: TextAlign.center,
            style: SoftType.body,
          ),
        ],
      ),
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
            border: Border.all(
              color: selected ? SoftColors.blue : SoftColors.line,
            ),
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
