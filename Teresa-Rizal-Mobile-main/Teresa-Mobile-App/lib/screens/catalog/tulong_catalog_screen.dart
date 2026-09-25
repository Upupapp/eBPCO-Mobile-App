import 'package:flutter/material.dart';

import '../../data/service_catalog_mock.dart';
import '../../data/tulong_program_route.dart';
import '../../theme/soft_widget.dart';
import 'catalog_chrome.dart';
import 'catalog_detail_screen.dart';
import 'tulong_program_placeholder.dart';

enum TulongAnchor { top, programs }

class TulongCatalogScreen extends StatelessWidget {
  final TulongAnchor anchor;
  final bool openOnly;

  const TulongCatalogScreen({
    super.key,
    this.anchor = TulongAnchor.top,
    this.openOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = openOnly
        ? ServiceCatalogMock.tulong.where((item) => item.window == ProgramWindow.open)
        : ServiceCatalogMock.tulong;
    return CatalogPage(
      title: 'Tulong',
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (openOnly)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text('Open programs', style: CatalogType.sectionLabel),
            )
          else
            const HonestyNote(text: ServiceCatalogMock.tulongHonesty),
          if (!openOnly && anchor == TulongAnchor.top) ...[
            _block('AICS', items.where((e) => e.section == TulongSection.aics)),
            _block(
              'Programs & IDs',
              items.where((e) => e.section == TulongSection.programs).take(1),
            ),
          ] else if (!openOnly) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('Closed programs stay visible.', style: CatalogType.meta),
            ),
            _block('Programs & IDs', items.where((e) => e.section == TulongSection.programs)),
            _block('Livelihood & training', items.where((e) => e.section == TulongSection.livelihood)),
          ] else
            for (final item in items) _TulongTile(item: item),
        ],
      ),
    );
  }

  Widget _block(String title, Iterable<TulongProgram> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
          child: Text(title, style: CatalogType.sectionLabel),
        ),
        for (final item in items) _TulongTile(item: item),
      ],
    );
  }
}

class _TulongTile extends StatelessWidget {
  final TulongProgram item;
  const _TulongTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = windowColors(item.window);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Material(
        color: SoftColors.white,
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(SoftRadius.lg),
          onTap: () {
            if (item.educationalLanding) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  settings: const RouteSettings(name: kTulongProgramRoute),
                  builder: (_) => const TulongProgramPlaceholder(),
                ),
              );
              return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TulongDetailScreen(program: item)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const IconDisc(
                  icon: Icons.volunteer_activism_outlined,
                  background: SoftColors.tulongSoft,
                  foreground: SoftColors.tulongInk,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: CatalogType.tileTitle),
                      const SizedBox(height: 2),
                      Text(item.eligibility, style: CatalogType.tileSub),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.$1,
                    borderRadius: BorderRadius.circular(SoftRadius.pill),
                  ),
                  child: Text(
                    windowLabel(item.window),
                    style: CatalogType.sample.copyWith(color: colors.$2),
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
