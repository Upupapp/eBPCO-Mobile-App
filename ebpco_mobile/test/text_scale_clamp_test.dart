import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/theme/text_scale_clamp.dart';

Future<double> _scaleUnder(WidgetTester tester, double system) async {
  late double seen;
  await tester.pumpWidget(MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(system)),
    child: TextScaleClamp(child: Builder(builder: (context) {
      seen = MediaQuery.textScalerOf(context).scale(10) / 10;
      return const SizedBox();
    })),
  ));
  return seen;
}

void main() {
  testWidgets('a text size between 0.9x and 2x is honoured as set', (tester) async {
    expect(await _scaleUnder(tester, 1.6), closeTo(1.6, 0.001));
  });

  testWidgets('the extremes are bounded', (tester) async {
    expect(await _scaleUnder(tester, 3.1), closeTo(2.0, 0.001));
    expect(await _scaleUnder(tester, 0.7), closeTo(0.9, 0.001));
  });
}
