// Emergency hub and center detail. No distance and no nearest badge.
// Centers sort by the signed-in profile barangay, then by name. The preview
// shows one sample center; the rest of the list opens with See all. A center
// in the profile barangay may show a neutral "Your barangay" chip.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/data/service_catalog_mock.dart';
import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/models/evacuation_center.dart';
import 'package:teresa_rizal/screens/sakuna/evacuation_center_detail_screen.dart';
import 'package:teresa_rizal/screens/sakuna/sakuna_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';

void main() {
  Future<void> pumpSakuna(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CitizenSessionService()),
          ChangeNotifierProvider(create: (_) => NotificationsService()),
          ChangeNotifierProvider(create: (_) => RequestsService()),
          ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ],
        child: const MaterialApp(home: SakunaScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapCenter(WidgetTester tester, String name) async {
    final item = find.text(name);
    final scrollable = find.descendant(
      of: find.byType(SakunaScreen),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(item, 250, scrollable: scrollable);
    await tester.pumpAndSettle();
    final height = tester.view.physicalSize.height / tester.view.devicePixelRatio;
    for (var i = 0; i < 8; i++) {
      final rect = tester.getRect(item);
      if (rect.top >= 0 && rect.bottom <= height) break;
      await tester.drag(scrollable, Offset(0, rect.bottom > height ? -120 : 120));
      await tester.pumpAndSettle();
    }
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  Future<void> seeAll(WidgetTester tester) async {
    final button = find.byKey(const Key('evac-see-all'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  List<String?> listedOrder(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .where((data) =>
          data == 'Dalig Elementary School' ||
          data == 'Poblacion Covered Court' ||
          data == 'San Roque Barangay Hall')
      .toList();

  test('centers sort by profile barangay, then name A to Z', () {
    List<String> names(String? barangay) {
      final centers = [...MockCatalog.evacuationCenters]
        ..sort((a, b) => EvacuationCenter.compareByProfileBarangay(a, b, barangay));
      return centers.map((c) => c.name).toList();
    }

    expect(names(null), [
      'Dalig Elementary School',
      'Poblacion Covered Court',
      'San Roque Barangay Hall',
    ]);
    expect(names('Bagumbayan'), [
      'Dalig Elementary School',
      'Poblacion Covered Court',
      'San Roque Barangay Hall',
    ]);
    expect(names('Poblacion'), [
      'Poblacion Covered Court',
      'Dalig Elementary School',
      'San Roque Barangay Hall',
    ]);
  });

  testWidgets('the hub shows one sample center and no distance', (tester) async {
    await pumpSakuna(tester);

    expect(find.text('Emergency'), findsWidgets);
    expect(find.text('Nearest'), findsNothing);
    expect(find.textContaining('km'), findsNothing);
    expect(find.text('Your barangay'), findsNothing);
    expect(find.text('Sample center'), findsOneWidget);
    // With no profile the preview is the first center A to Z.
    expect(find.text('Dalig Elementary School'), findsOneWidget);
    expect(find.text('Poblacion Covered Court'), findsNothing);
    expect(find.text(ServiceCatalogMock.mdrrmoNumber), findsOneWidget);
    expect(find.text('Report an incident'), findsOneWidget);

    await seeAll(tester);
    expect(listedOrder(tester), [
      'Dalig Elementary School',
      'Poblacion Covered Court',
      'San Roque Barangay Hall',
    ]);
    expect(find.text('Your barangay'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a center opens the sample detail', (tester) async {
    await pumpSakuna(tester);

    await tapCenter(tester, 'Dalig Elementary School');

    expect(find.byType(EvacuationCenterDetailScreen), findsOneWidget);
    expect(find.text('Center detail'), findsOneWidget);
    expect(find.text('Nearest Evacuation Center'), findsNothing);
    expect(find.text('Your barangay'), findsNothing);
    expect(find.text('Sample center'), findsWidgets);
    expect(find.text('Open'), findsWidgets);
    expect(find.textContaining('km'), findsNothing);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text(ServiceCatalogMock.mdrrmoNumber), findsWidgets);
    expect(find.text(ServiceCatalogMock.evacHonesty), findsOneWidget);
    expect(find.text('Directions'), findsNothing);
    expect(find.text('Call'), findsNothing);
    expect(find.textContaining('Currently occupied'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a center detail never shows a distance', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: EvacuationCenterDetailScreen(
          center: EvacuationCenter(name: 'Fallback Center', barangay: 'Test', totalCapacity: 50),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('km'), findsNothing);
    expect(find.text('Nearest'), findsNothing);
    expect(find.text('Your barangay'), findsNothing);
    expect(find.text('Sample center'), findsOneWidget);
    expect(find.text(ServiceCatalogMock.evacHonesty), findsOneWidget);
    expect(find.text('50 / 50'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a center in the signed-in profile barangay is listed first and shows Your barangay', (tester) async {
    await pumpSakuna(tester);
    final session = tester.element(find.byType(SakunaScreen)).read<CitizenSessionService>();
    await tester.runAsync(() => session.login(_poblacionAccount));
    await tester.pumpAndSettle();

    // The preview is now the profile barangay's center.
    expect(find.text('Nearest'), findsNothing);
    expect(find.text('Poblacion Covered Court'), findsOneWidget);
    expect(find.text('Dalig Elementary School'), findsNothing);
    expect(find.text('Your barangay'), findsOneWidget);

    await seeAll(tester);
    expect(listedOrder(tester), [
      'Poblacion Covered Court',
      'Dalig Elementary School',
      'San Roque Barangay Hall',
    ]);
    expect(find.text('Your barangay'), findsOneWidget);

    await tapCenter(tester, 'Poblacion Covered Court');
    expect(find.text('Your barangay'), findsOneWidget);
    expect(find.text('Poblacion, Teresa, Rizal'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapCenter(tester, 'Dalig Elementary School');
    expect(find.text('Your barangay'), findsNothing);
    expect(find.text('Dalig, Teresa, Rizal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final _poblacionAccount = CitizenAccount(
  id: 'ESP-RES-TEST-9101',
  firstName: 'Demo',
  lastName: 'Resident',
  email: 'demo.resident@example.com',
  mobile: '0919 000 9101',
  barangay: 'Poblacion',
  purok: 'Purok 1',
  address: 'Purok 1, Barangay Poblacion, Teresa, Rizal',
  birthdate: 'January 1, 1995',
  sex: 'Female',
  civilStatus: 'Single',
  occupation: 'Teacher',
  profileCompleteness: 80,
  status: 'Approved',
);
