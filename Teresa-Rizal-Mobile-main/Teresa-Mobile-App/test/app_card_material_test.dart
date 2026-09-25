// A card must give its children somewhere to paint ink.
//
// `AppCard` only wrapped itself in a `Material` when it had an `onTap`. A
// non-tappable card therefore gave its children no `Material` ancestor, and any
// `ListTile`-family widget inside one rendered with no ripple and no
// `tileColor`. Flutter says so out loud — "ListTile background color or ink
// splashes may be invisible" — but only at runtime while painting on a device.
//
// The visible case was Settings: two notification switches and two language
// radios, all inside a non-tappable `AppCard`, which changed value under the
// finger with no feedback whatsoever.
//
// Found by the FE 03 device walk (`integration_test/app_walk_test.dart`), which
// installs a `FlutterError.onError` hook and reported the error four times —
// exactly the number of tiles on that screen. The widget suite had 584 passing
// tests at the time and none of them saw it, because this is a *painting*
// fault: it needs a real render pass, not a pumped tree.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/widgets/app_card.dart';

void main() {
  testWidgets('a non-tappable AppCard still provides a Material ancestor', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCard(
            // No onTap — this is the case that had no Material.
            child: Text('content'),
          ),
        ),
      ),
    );

    final material = find.descendant(of: find.byType(AppCard), matching: find.byType(Material));
    expect(material, findsWidgets, reason: 'children need a Material to paint ink into');
  });

  testWidgets('a ListTile inside a non-tappable AppCard paints without complaint', (tester) async {
    // The exact shape of the Settings screen: tiles in a card with no onTap.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(value: true, onChanged: (_) {}, title: const Text('Push notifications')),
                ListTile(tileColor: Colors.amber.shade50, title: const Text('A tile with a background')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Before the fix this reported "ListTile background color or ink splashes
    // may be invisible" rather than throwing, so assert on the captured error
    // rather than expecting a crash.
    expect(tester.takeException(), isNull);
  });

  testWidgets('the card keeps its own decoration — the Material paints nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppCard(child: Text('content')))),
    );

    // MaterialType.transparency draws no surface of its own, so the card's
    // white fill, border and shadow are still the card's own Container.
    final material = tester.widget<Material>(
      find.descendant(of: find.byType(AppCard), matching: find.byType(Material)).first,
    );
    expect(material.type, MaterialType.transparency);
  });
}
