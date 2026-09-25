import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/requests/pack_d/pack_d_flow.dart';
import 'package:teresa_rizal/screens/requests/pack_d/pack_d_frame.dart';
import 'package:teresa_rizal/screens/shared/service_catalog_screen.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/theme/app_theme.dart';
import 'package:teresa_rizal/theme/soft_widget.dart';
import 'package:teresa_rizal/widgets/soft_chrome.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: home,
  );
}

BoxDecoration _payTileDecoration(WidgetTester tester, String title) {
  final container = tester.widget<Container>(
    find
        .ancestor(
          of: find.text(title),
          matching: find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final decoration = widget.decoration;
            return decoration is BoxDecoration &&
                decoration.color != null &&
                decoration.border != null;
          }),
        )
        .first,
  );
  return container.decoration! as BoxDecoration;
}

List<BoxShadow> _boxShadows(WidgetTester tester, Finder of) {
  return tester
      .widgetList<DecoratedBox>(
        find.descendant(of: of, matching: find.byType(DecoratedBox)),
      )
      .map((box) => box.decoration)
      .whereType<BoxDecoration>()
      .expand((decoration) => decoration.boxShadow ?? const <BoxShadow>[])
      .toList();
}

Widget _frame(
  PackDFrame frame, {
  ValueChanged<PackDFrame>? onGo,
  VoidCallback? onOpenSettings,
  VoidCallback? onViewReceipt,
  VoidCallback? onCancelRequest,
  bool settingsHandoff = false,
}) {
  return _app(
    PackDFrameScreen(
      frame: frame,
      onBack: () {},
      onGo: onGo ?? (_) {},
      onSex: (_) {},
      onPayMethod: (_) {},
      onOpenSettings: onOpenSettings ?? () {},
      onViewReceipt: onViewReceipt ?? () {},
      onCancelRequest: onCancelRequest ?? () {},
      settingsHandoff: settingsHandoff,
    ),
  );
}

void main() {
  testWidgets('permission sheets keep Pack D honesty and local actions', (
    tester,
  ) async {
    _phone(tester);
    PackDFrame? next;
    await tester.pumpWidget(
      _frame(PackDFrame.permCamera, onGo: (frame) => next = frame),
    );
    await tester.pumpAndSettle();

    expect(find.text('Allow camera access?'), findsOneWidget);
    expect(find.textContaining('no live LGU camera pipeline'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Allow camera'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    expect(next, PackDFrame.permDenied);

    await tester.pumpWidget(_frame(PackDFrame.permPhotos));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('not uploaded to a live LGU server'),
      findsOneWidget,
    );
    expect(find.text('Allow photos'), findsOneWidget);

    await tester.pumpWidget(_frame(PackDFrame.permDocuments));
    await tester.pumpAndSettle();
    expect(find.textContaining('no municipal document vault'), findsOneWidget);
    expect(find.text('Allow files'), findsOneWidget);
  });

  testWidgets('denied camera offers Open Settings and a gallery fallback', (
    tester,
  ) async {
    _phone(tester);
    var opened = false;
    PackDFrame? next;
    await tester.pumpWidget(
      _frame(
        PackDFrame.permDenied,
        onOpenSettings: () => opened = true,
        onGo: (frame) => next = frame,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Camera access is off'), findsOneWidget);
    expect(find.text('Open Settings'), findsOneWidget);
    expect(find.textContaining('still a local preview'), findsOneWidget);
    expect(find.text('Use Gallery or File instead'), findsOneWidget);

    await tester.tap(find.text('Open Settings'));
    expect(opened, isTrue);
    await tester.tap(find.text('Use Gallery or File instead'));
    expect(next, PackDFrame.attachSource);
  });

  testWidgets('attachment source and master-file reuse stay on-device', (
    tester,
  ) async {
    _phone(tester);
    final seen = <PackDFrame>[];
    await tester.pumpWidget(_frame(PackDFrame.attachSource, onGo: seen.add));
    await tester.pumpAndSettle();

    expect(find.text('Add attachment'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Valid ID · pick a source'), findsOneWidget);

    await tester.tap(find.text('Gallery'));
    expect(seen, [PackDFrame.permPhotos]);

    await tester.pumpWidget(_frame(PackDFrame.attachUseExisting));
    await tester.pumpAndSettle();
    expect(find.text('PhilSys ID · front'), findsOneWidget);
    expect(find.textContaining('not a live LGU vault lookup'), findsOneWidget);
    expect(find.text('Take new'), findsOneWidget);
    expect(find.text('Use existing'), findsOneWidget);
  });

  testWidgets('wizard steps 2/4 through 4/4 carry honesty and DEMO payment', (
    tester,
  ) async {
    _phone(tester);
    final seen = <PackDFrame>[];
    await tester.pumpWidget(_frame(PackDFrame.applicant, onGo: seen.add));
    await tester.pumpAndSettle();

    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.text('Ana Marie Santos'), findsOneWidget);
    expect(find.text('Dalig'), findsOneWidget);
    expect(
      find.textContaining('not a live civil registry pull'),
      findsOneWidget,
    );
    await tester.tap(find.text('Continue'));
    expect(seen, [PackDFrame.review]);

    await tester.pumpWidget(_frame(PackDFrame.review, onGo: seen.add));
    await tester.pumpAndSettle();
    expect(find.text('3 / 4'), findsOneWidget);
    expect(
      find.textContaining('No live LGU ticket is created'),
      findsOneWidget,
    );
    expect(find.text('Edit'), findsNWidgets(3));
    await tester.tap(find.text('Continue to payment'));
    expect(seen.last, PackDFrame.payment);

    await tester.pumpWidget(_frame(PackDFrame.payment));
    await tester.pumpAndSettle();
    expect(find.text('4 / 4'), findsOneWidget);
    expect(find.text('DEMO'), findsNWidgets(3));
    expect(find.text('GCash'), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Cash at window'), findsOneWidget);
    expect(find.textContaining('Not live LGU money.'), findsOneWidget);
    expect(find.textContaining('No real GCash/Maya charge'), findsOneWidget);
    expect(find.text('Confirm Payment'), findsOneWidget);

    final selected = _payTileDecoration(tester, 'GCash');
    expect(selected.color, SoftColors.blueWash);
    final selectedBorder = selected.border! as Border;
    expect(selectedBorder.top.color, SoftColors.blue);
    expect(selectedBorder.top.width, 1.5);
    expect(selected.boxShadow, SoftShadows.cardSm);

    final unselected = _payTileDecoration(tester, 'Maya');
    expect(unselected.color, SoftColors.white);
    final unselectedBorder = unselected.border! as Border;
    expect(unselectedBorder.top.color, SoftColors.line);
    expect(unselectedBorder.top.width, 1);
    expect(unselected.boxShadow, SoftShadows.cardSm);

    final confirm = find.widgetWithText(SoftPillButton, 'Confirm Payment');
    expect(_boxShadows(tester, confirm), SoftShadows.primary);
  });

  testWidgets('detail states match correction, wait, cancel, and release', (
    tester,
  ) async {
    _phone(tester);

    await tester.pumpWidget(_frame(PackDFrame.rejected));
    await tester.pumpAndSettle();
    expect(find.text('Rejected'), findsWidgets);
    expect(find.text('Apply Again'), findsOneWidget);
    expect(find.textContaining('no live LGU officer decision'), findsOneWidget);

    await tester.pumpWidget(_frame(PackDFrame.correction));
    await tester.pumpAndSettle();
    expect(find.text('Needs correction'), findsOneWidget);
    expect(find.text('Flagged'), findsOneWidget);
    expect(find.text('Replace document'), findsOneWidget);
    expect(find.text('Resubmit'), findsOneWidget);
    expect(find.text('philsys-front.jpg'), findsOneWidget);
    expect(find.textContaining('not a live officer queue'), findsOneWidget);

    await tester.pumpWidget(_frame(PackDFrame.manual));
    await tester.pumpAndSettle();
    expect(find.text('Manual verification'), findsWidgets);
    expect(find.text('Under manual review'), findsOneWidget);
    expect(
      find.widgetWithText(SoftPillButton, 'Replace document'),
      findsNothing,
    );
    expect(find.widgetWithText(SoftPillButton, 'Resubmit'), findsNothing);
    expect(find.textContaining('no Replace / Resubmit CTA'), findsOneWidget);
    expect(find.text('Back to My requests'), findsOneWidget);

    var cancelled = false;
    await tester.pumpWidget(
      _frame(PackDFrame.cancel, onCancelRequest: () => cancelled = true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cancel this request?'), findsOneWidget);
    expect(find.text('Keep request'), findsOneWidget);
    expect(
      find.textContaining('not refunded in this frontend demo'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel request'));
    expect(cancelled, isTrue);

    var receipt = false;
    await tester.pumpWidget(
      _frame(PackDFrame.approved, onViewReceipt: () => receipt = true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Released'), findsWidgets);
    await tester.scrollUntilVisible(find.text('View payment record'), 200);
    expect(find.text('View payment record'), findsOneWidget);
    expect(find.text('DEMO-PAY-0012'), findsOneWidget);
    expect(find.text('Paid in demo'), findsOneWidget);
    expect(find.textContaining('Payment record and claim instructions are simulated'), findsOneWidget);
    expect(find.textContaining('not a live treasury release'), findsOneWidget);
    await tester.tap(find.text('View payment record'));
    expect(receipt, isTrue);
  });

  testWidgets('preview flow walks camera denial into the local wizard', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(_app(const PackDRequestFlow()));
    await tester.pumpAndSettle();

    expect(find.textContaining('do not create a live request'), findsOneWidget);
    await tester.tap(find.text('Allow camera'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Open Settings'), findsOneWidget);

    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('system Settings stays closed in this build'),
      findsOneWidget,
    );

    await tester.tap(find.text('Use Gallery or File instead'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('File'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Allow files'));
    await tester.pumpAndSettle();
    expect(find.textContaining('not a live LGU vault lookup'), findsOneWidget);
    await tester.tap(find.text('Use existing'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 4'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 4'), findsOneWidget);
    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();
    expect(find.text('DEMO'), findsNWidgets(3));
    await tester.tap(find.text('Maya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm Payment'));
    await tester.pumpAndSettle();
    expect(find.text('Released'), findsWidgets);
    expect(find.textContaining('not a live treasury release'), findsOneWidget);
  });

  testWidgets('Dokyu catalog keeps the wizard entry and adds the preview', (
    tester,
  ) async {
    _phone(tester);
    await tester.pumpWidget(
      _app(
        const ServiceCatalogScreen(
          category: ServiceCategory.dokyu,
          title: 'Dokyu',
          catalog: MockCatalog.documentTypes,
          accent: SoftColors.blue,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Preview request states'), findsOneWidget);
    expect(find.text('Barangay clearance'), findsOneWidget);

    await tester.tap(find.text('Preview request states'));
    await tester.pumpAndSettle();
    expect(find.text('Request preview'), findsOneWidget);
    expect(find.byType(PackDRequestFlow), findsOneWidget);
  });
}
