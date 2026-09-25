import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';

/// Filled Home banner carousel. Slide order is fixed: 01, then 02, then 03.
///
/// The slot is the artwork only. Nothing is painted on top of a slide — no
/// marketing line, and no municipal seal. The dashed "Banner slot / GPT art
/// pending" placeholder is not used once these slides are present.
///
/// Source frames are 1672×941 and are bundled at that size. [BoxFit.cover]
/// with [Alignment.center] fills the clipped 22px-radius slot.
class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  /// Shared by Guest, Unverified, and Verified Home. Do not reorder.
  static const slides = <HomeBannerSlide>[
    HomeBannerSlide(
      asset: 'assets/images/banners/home_banner_01.png',
      semanticLabel:
          'Home banner 1 of 3. Teresa, Rizal. One app for every service.',
    ),
    HomeBannerSlide(
      asset: 'assets/images/banners/home_banner_02.png',
      semanticLabel: 'Home banner 2 of 3. Municipal Hall.',
    ),
    HomeBannerSlide(
      asset: 'assets/images/banners/home_banner_03.png',
      semanticLabel: 'Home banner 3 of 3. Public services in one app.',
    ),
  ];

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class HomeBannerSlide {
  final String asset;
  final String semanticLabel;

  const HomeBannerSlide({required this.asset, required this.semanticLabel});
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1672 / 941,
      child: ClipRRect(
        // SoftRadius.lg is 22. Clip hides anything past that radius.
        borderRadius: BorderRadius.circular(SoftRadius.lg),
        clipBehavior: Clip.hardEdge,
        child: PageView.builder(
          controller: _controller,
          itemCount: HomeBannerCarousel.slides.length,
          itemBuilder: (context, index) {
            final slide = HomeBannerCarousel.slides[index];
            return Image.asset(
              slide.asset,
              key: ValueKey(slide.asset),
              fit: BoxFit.cover,
              alignment: Alignment.center,
              semanticLabel: slide.semanticLabel,
              gaplessPlayback: true,
            );
          },
        ),
      ),
    );
  }
}
