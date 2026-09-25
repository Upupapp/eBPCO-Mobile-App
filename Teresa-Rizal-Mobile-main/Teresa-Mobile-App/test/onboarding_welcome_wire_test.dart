import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teresa_rizal/screens/onboarding/onboarding_page_data.dart';
import 'package:teresa_rizal/screens/onboarding/onboarding_screen.dart';
import 'package:teresa_rizal/screens/onboarding/widgets/onboarding_orb.dart';
import 'package:teresa_rizal/utils/teresa_rizal_seal.dart';

void main() {
  test('brand spelling is Munisipalidad', () {
    expect(onboardingBrandName, 'Munisipalidad ng Teresa, Rizal');
    expect(onboardingBrandName, isNot(contains('Municipalidad')));
  });

  test('orb scale path is small, bigger mid-swipe, then smaller', () {
    final rest = OnboardingOrbPose.lerp(0);
    final mid12 = OnboardingOrbPose.lerp(0.5);
    final page2 = OnboardingOrbPose.lerp(1);
    final mid23 = OnboardingOrbPose.lerp(1.5);
    final page3 = OnboardingOrbPose.lerp(2);

    expect(rest.scale, closeTo(0.55, 0.001));
    expect(rest.widthFraction, inInclusiveRange(0.18, 0.24));
    expect(mid12.scale, closeTo(OnboardingOrbPose.travelPeakScale, 0.001));
    expect(mid12.scale, greaterThan(rest.scale));

    expect(page2.widthFraction, inInclusiveRange(0.12, 0.16));
    expect(page2.scale, lessThan(rest.scale));
    expect(page2.yaw, closeTo(18 * math.pi / 180, 0.001));
    expect(page2.fx, greaterThan(0.6));

    expect(mid23.scale, closeTo(OnboardingOrbPose.travelPeakScale, 0.001));
    expect(mid23.scale, greaterThan(page2.scale));

    expect(page3.widthFraction, inInclusiveRange(0.12, 0.16));
    expect(page3.scale, lessThan(rest.scale));
    expect(page3.pitch, closeTo(-8 * math.pi / 180, 0.001));
    expect(page3.fx, lessThan(0.4));
    expect(page2.opacity, inInclusiveRange(0.85, 1));
    expect(page3.opacity, inInclusiveRange(0.85, 1));
  });

  testWidgets('welcome sheet shows Flutter copy and exactly one real seal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pumpAndSettle();

    expect(find.text(onboardingBrandName), findsOneWidget);
    expect(find.text('Municipalidad ng Teresa, Rizal'), findsNothing);
    expect(find.byKey(const Key('onboarding_orb')), findsOneWidget);

    final images = tester.widgetList<Image>(find.byType(Image));
    final names = images.map((image) {
      final provider = image.image;
      final asset = provider is ResizeImage ? provider.imageProvider : provider;
      return asset is AssetImage ? asset.assetName : '';
    });
    expect(
      names.where((name) => name == teresaRizalSealAsset),
      hasLength(1),
      reason: 'the real seal is composited once, not stacked on a plate seal',
    );
    expect(names, contains(onboardingOrbAsset));
    expect(names, contains(onboardingScenes[0].backgroundAsset));

    expect(
      find.descendant(
        of: find.byKey(const Key('onboarding_chips')),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('onboarding_chips')),
        matching: find.byType(TextButton),
      ),
      findsNothing,
    );
  });
}
