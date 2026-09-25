import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/main.dart';
import 'package:ebpco_mobile/screens/splash/splash_screen.dart';

void main() {
  testWidgets('app boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EbpcoMobileApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.image(const AssetImage('assets/images/ebpco_seal.png')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
