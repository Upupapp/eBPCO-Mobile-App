import 'package:flutter/material.dart';

/// One first-run scene: a photograph, two lines of headline, and a promise the
/// app can keep.
///
/// Structured after the Servana client's `WelcomeSceneSpec` — copy, assets and
/// screen-reader descriptions live here rather than inside animation widgets,
/// so the words can be reviewed without reading a layout.
///
/// **What is deliberately absent.** The retired composite artwork advertised
/// "Business Permit — Approved" on screen two. Business permits are a real
/// Dokyu service; an onboarding screen implying one has been *approved* is not,
/// because nothing in this app approves anything — there is no backend. Every
/// line below is one the frontend can keep.
@immutable
class OnboardingSceneSpec {
  const OnboardingSceneSpec({
    required this.id,
    required this.headline,
    required this.subtext,
    required this.backgroundAsset,
    required this.semanticDescription,
    required this.features,
    this.note,
  });

  /// Stable id, used for widget keys.
  final String id;

  /// Two short lines. The break is authored, not left to the layout — these
  /// are the words a citizen reads first and they should break where they were
  /// meant to.
  final String headline;

  /// One sentence of detail. Must not describe anything the app cannot do.
  final String subtext;

  final String backgroundAsset;

  /// What the photograph shows, for a screen reader.
  final String semanticDescription;

  /// Up to three capability chips shown above the headline.
  ///
  /// Labels only — they are not buttons and do not navigate.
  final List<OnboardingFeature> features;

  /// A limit rather than a promise — page two's access caveat. Shown on its
  /// own line, because a limit folded into a sentence reads as a feature.
  final String? note;
}

@immutable
class OnboardingFeature {
  const OnboardingFeature({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// The three scenes.
///
/// **Copy language.** Filipino headline, English supporting line. That is the
/// split the app already uses — its home hero greets in Filipino ("Magandang
/// araw") over an English interface — and it is the split the municipality's
/// own campaign artwork uses. The hook lands in the language a citizen thinks
/// in; the detail stays in the language the rest of the interface is written
/// in.
///
/// **Structure.** Each headline is a benefit, not a feature list, and page two
/// leads with the single strongest one an LGU app has: not queueing.
const onboardingScenes = <OnboardingSceneSpec>[
  OnboardingSceneSpec(
    id: 'scene_bayan',
    headline: 'Ang Teresa, Rizal,\nnasa iyong kamay.',
    subtext:
        'Municipal services, local news, and your resident account — all in one app.',
    backgroundAsset: 'assets/images/welcome/page_1_bg.jpg',
    semanticDescription: 'Page 1 of 3: the Teresa, Rizal coastline at sunrise',
    features: [
      OnboardingFeature(icon: Icons.person_outline, label: 'Resident Profile'),
      OnboardingFeature(icon: Icons.badge_outlined, label: 'Digital ID'),
      OnboardingFeature(icon: Icons.grid_view_rounded, label: 'LGU Services'),
    ],
  ),
  OnboardingSceneSpec(
    id: 'scene_serbisyo',
    headline: 'Mag-request.\nHindi na pumila.',
    subtext:
        'Send Dokyu and Tulong requests, upload your requirements, and follow every update from your phone.',
    note: 'Dokyu and Tulong are available to verified residents.',
    backgroundAsset: 'assets/images/welcome/page_2_bg.jpg',
    semanticDescription:
        'Page 2 of 3: a resident being handed a document at the municipal services counter',
    features: [
      OnboardingFeature(
        icon: Icons.description_outlined,
        label: 'Submit Requirements',
      ),
      OnboardingFeature(icon: Icons.search, label: 'Track Status'),
      OnboardingFeature(
        icon: Icons.notifications_none_rounded,
        label: 'View Updates',
      ),
    ],
  ),
  OnboardingSceneSpec(
    id: 'scene_handa',
    headline: 'Laging alam.\nLaging handa.',
    subtext:
        'Official news and events, emergency hotlines, evacuation centers, and incident reporting — ready when you need them.',
    backgroundAsset: 'assets/images/welcome/page_3_bg.jpg',
    semanticDescription:
        'Page 3 of 3: an emergency response team assisting a family during a flood',
    features: [
      OnboardingFeature(
        icon: Icons.newspaper_outlined,
        label: 'Official Balita',
      ),
      OnboardingFeature(
        icon: Icons.calendar_today_outlined,
        label: 'Upcoming Events',
      ),
      OnboardingFeature(icon: Icons.call_outlined, label: 'Emergency Help'),
    ],
  ),
];

/// Wordmark, centered on the white sheet. The seal is separate chrome,
/// upper-right over the photograph.
const onboardingBrandName = 'Munisipalidad ng Teresa, Rizal';

/// Shared civic-light orb. One asset, morphed across the three scenes.
const onboardingOrbAsset = 'assets/images/welcome/welcome_hero_orb.png';

/// How far each depth travels, as a fraction of viewport width per page of
/// swipe. Servana's own scale, which reads as depth without ever becoming a
/// ride:
///
///   0.05 – atmospheric, barely moves
///   0.15 – the photograph
///   0.35 – mid-ground content
///   0.55 – interface cards
///
/// The photograph moves *against* the swipe at [background], which is what
/// makes it sit behind the glass; the copy moves with the page and needs no
/// factor of its own.
class OnboardingParallax {
  OnboardingParallax._();

  static const double background = 0.15;
  static const double backgroundVertical = 0.02;
  static const double chips = 0.35;
}

/// `rectangle_cityhall.jpg` must not appear in this app. The hall facade
/// reads another municipality. It is not an onboarding plate and it is not
/// Balita media.
const onboardingExcludedAsset = 'assets/images/rectangle_cityhall.jpg';
