// Coverage for the relocated "Submitted Government ID" section — moved
// from Digital ID (see digital_id_screen.dart and
// nicanor_anacleto_media_test.dart / perlita_identity_migration_test.dart's
// now-trimmed Digital ID coverage) to Profile > Personal Information, since
// the physical ID a resident uploads during registration is a different
// concept from the Teresa, Rizal Digital ID (an issued credential). This
// reuses the same single-source-of-truth GovernmentIdRecord lookup and the
// same GovernmentIdViewer already used elsewhere — see
// utils/government_id.dart — never a second copy of either.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/access_level.dart';
import 'package:teresa_rizal/models/citizen_account.dart';
import 'package:teresa_rizal/screens/profile/government_id_viewer.dart';
import 'package:teresa_rizal/screens/profile/resident_profile/personal_information_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';

Future<CitizenSessionService> _pumpPersonalInformation(WidgetTester tester, CitizenAccount account) async {
  SharedPreferences.setMockInitialValues({});
  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(account);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<ResidentProfileService>(create: (_) => ResidentProfileService()),
      ],
      child: const MaterialApp(home: PersonalInformationScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return session;
}

Future<void> _scrollToBottom(WidgetTester tester) async {
  final scrollable = find.byType(Scrollable).first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(
    tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Submitted Government ID on Personal Information', () {
    testWidgets('Perlita (Verified): her demo ID is at the very bottom of the page and is viewable', (tester) async {
      await _pumpPersonalInformation(tester, MockCatalog.demoAccounts.last);
      await _scrollToBottom(tester);

      expect(find.text('Submitted Government ID'), findsOneWidget);
      expect(find.text('Postal ID (PHLPost)'), findsOneWidget);
      expect(find.text('On File'), findsOneWidget);
      expect(find.text('View ID'), findsOneWidget);

      await tester.tap(find.text('View ID'));
      await tester.pumpAndSettle();
      expect(find.byType(GovernmentIdViewer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Nicanor (Unverified): his demo ID is still visible here, and he remains Unverified', (tester) async {
      final session = await _pumpPersonalInformation(tester, MockCatalog.demoAccounts.first);
      await _scrollToBottom(tester);

      expect(find.text('Submitted Government ID'), findsOneWidget);
      expect(find.text('Teresa, Rizal Resident ID'), findsOneWidget);

      await tester.tap(find.text('View ID'));
      await tester.pumpAndSettle();
      expect(find.byType(GovernmentIdViewer), findsOneWidget);

      // Being visible here never implies verification — it shows what was
      // submitted, not something the LGU has issued.
      expect(session.account!.status, 'Pending Review');
      expect(session.accessLevel, AccessLevel.unverified);
    });

    testWidgets('Anacleto Account A (Unverified duplicate): his demo ID is visible here too', (tester) async {
      final session = await _pumpPersonalInformation(tester, MockCatalog.unverifiedDuplicateAccountA);
      await _scrollToBottom(tester);

      expect(find.text('Submitted Government ID'), findsOneWidget);
      expect(find.text('Teresa, Rizal Resident ID'), findsOneWidget);
      expect(session.accessLevel, AccessLevel.unverified);
    });

    testWidgets('Anacleto Account B (Unverified duplicate): the same demo ID is visible here', (tester) async {
      final session = await _pumpPersonalInformation(tester, MockCatalog.unverifiedDuplicateAccountB);
      await _scrollToBottom(tester);

      expect(find.text('Submitted Government ID'), findsOneWidget);
      expect(find.text('Teresa, Rizal Resident ID'), findsOneWidget);
      expect(session.accessLevel, AccessLevel.unverified);
    });
  });
}
