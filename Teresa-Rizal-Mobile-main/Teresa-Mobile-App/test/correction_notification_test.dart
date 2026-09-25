// Coverage for the "Application Needs Correction" notification feature —
// a Flagged for Replacement requirement must produce a real, linked
// notification in the existing Notifications feed (never a disconnected
// fake one), tapping the card opens the exact request, tapping "Replace
// Document" opens the exact flagged requirement, and the whole thing works
// identically for Dokyu and Tulong without duplicating notifications across
// app restarts or after the correction is resolved.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/attachment.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/notifications/notifications_screen.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';

const _verifiedDemoId = 'ESP-RES-2024-9002';

Future<RequestsService> _readyRequests(WidgetTester tester) async {
  final requests = RequestsService(seedDemoData: false);
  var attempts = 0;
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  return requests;
}

Future<void> _pumpNotifications(
  WidgetTester tester, {
  required RequestsService requests,
  NotificationsService? notificationsService,
}) async {
  // Tall enough that every notification card (however many this test seeds)
  // renders in a single pass — ListView.builder only builds what's within
  // the viewport + cache extent, and this suite cares about counting/
  // finding specific cards, not exercising the list's own scroll behavior.
  tester.view.physicalSize = const Size(390, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final session = CitizenSessionService();
  var attempts = 0;
  while (session.loading) {
    attempts++;
    if (attempts > 100) throw StateError('CitizenSessionService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }
  await session.login(MockCatalog.demoAccounts.last); // Perlita — verified
  final mf = MasterFileService();
  attempts = 0;
  while (!mf.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('MasterFileService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<CitizenSessionService>.value(value: session),
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider(create: (_) => ResidentProfileService()),
        ChangeNotifierProvider<MasterFileService>.value(value: mf),
        ChangeNotifierProvider<NotificationsService>.value(value: notificationsService ?? NotificationsService()),
      ],
      child: const MaterialApp(home: NotificationsScreen()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Single Dokyu requirement flagged', () {
    testWidgets('1-5: notification is generated, unread, opens the correct Request Detail, and Replace Document '
        'reaches the exact flagged requirement', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Proof of Residency',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'Barangay Certificate of Indigency',
        reason: 'Certificate is expired.',
      );
      final flaggedId = requests.all.firstWhere((r) => r.id == request.id).flaggedRequirements.single.id;
      final notifId = 'correction-${request.id}-$flaggedId';

      final notifService = NotificationsService();
      var attempts = 0;
      while (!notifService.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('NotificationsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await _pumpNotifications(tester, requests: requests, notificationsService: notifService);

      // 2. Generated, linked to the real request/requirement.
      expect(find.text('Application Needs Correction'), findsOneWidget);
      expect(find.textContaining('Barangay Certificate of Indigency'), findsWidgets);
      expect(find.textContaining('Certificate is expired.'), findsOneWidget);
      expect(find.text('Replace Document'), findsOneWidget);

      // 3. Unread before any interaction.
      expect(notifService.isRead(notifId), isFalse);

      // 4. Tapping the card body opens the correct Request Detail.
      await tester.tap(find.text('Application Needs Correction'));
      await tester.pumpAndSettle();
      expect(find.byType(RequestDetailScreen), findsOneWidget);
      expect(find.text(request.referenceNumber), findsOneWidget); // AppBar title
      expect(notifService.isRead(notifId), isTrue); // marked read by opening it
      Navigator.of(tester.element(find.byType(RequestDetailScreen))).pop();
      await tester.pumpAndSettle();

      // 5. "Replace Document" reaches the exact flagged requirement's own
      // uploader card (proven by the auto-scroll actually moving the
      // viewport) — tap while the tall canvas still has it on-screen, then
      // shrink to a normal phone size before the pushed route's first frame
      // settles, so RequestDetailScreen's own content genuinely needs
      // scrolling to reveal the target card.
      await tester.tap(find.text('Replace Document'));
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpAndSettle();
      expect(find.byType(RequestDetailScreen), findsOneWidget);
      expect(find.text('Barangay Certificate of Indigency'), findsWidgets);
      final scrollable = find.byType(Scrollable).first;
      expect(tester.state<ScrollableState>(scrollable).position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  });

  group('Two flagged requirements on the same request', () {
    testWidgets('10-11: a single combined notification lists both, with a Review Documents action reaching the '
        'shared correction panel where both requirements and their own reasons are shown', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Proof of Residency',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'One (1) valid government-issued ID',
        reason: 'Image is unreadable.',
      );
      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'Proof of residency',
        reason: 'Document is expired.',
      );

      await _pumpNotifications(tester, requests: requests);

      // ONE combined card for this request, not one per flagged item —
      // stacking two identically-titled "Application Needs Correction"
      // cards for the same request read as noisy/confusing rather than as
      // one coherent thing to act on. See _correctionNotifications' own
      // doc comment.
      expect(find.text('Application Needs Correction'), findsOneWidget);
      expect(find.textContaining('2 documents require correction.'), findsOneWidget);
      expect(find.text('Review Documents'), findsOneWidget);
      expect(find.text('Replace Document'), findsNothing);
      expect(find.textContaining('Image is unreadable.'), findsOneWidget);
      expect(find.textContaining('Document is expired.'), findsOneWidget);

      await tester.tap(find.text('Review Documents'));
      await tester.pumpAndSettle();
      // Both requirements and their own individual reasons are visible
      // together on the shared correction panel.
      expect(find.byType(RequestDetailScreen), findsOneWidget);
      expect(find.text('One (1) valid government-issued ID'), findsWidgets);
      expect(find.text('Proof of residency'), findsWidgets);
      expect(find.textContaining('Image is unreadable.'), findsOneWidget);
      expect(find.textContaining('Document is expired.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('resolving down to exactly one remaining flag switches back to a specific, single-item notification', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Proof of Residency',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'One (1) valid government-issued ID',
        reason: 'Image is unreadable.',
      );
      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'Proof of residency',
        reason: 'Document is expired.',
      );
      final idFlagId = requests.all
          .firstWhere((r) => r.id == request.id)
          .flaggedRequirements
          .firstWhere((f) => f.requirementLabel == 'One (1) valid government-issued ID')
          .id;
      await requests.replaceFlaggedRequirement(
        request.id,
        flaggedId: idFlagId,
        newAttachment: _fakeAttachment('new-id.pdf', 'One (1) valid government-issued ID'),
      );

      await _pumpNotifications(tester, requests: requests);

      // Back to exactly one unresolved flag -> the specific single-item
      // form, not the combined one.
      expect(find.text('Review Documents'), findsNothing);
      expect(find.text('Replace Document'), findsOneWidget);
      expect(find.textContaining('Document is expired.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('No duplicate notifications across app restarts', () {
    testWidgets('12: reopening the app (fresh NotificationsService reading the same persisted read-state) never '
        're-shows a resolved-as-unread duplicate', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Proof of Residency',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(request.id, requirementLabel: 'Proof of residency', reason: 'Expired.');

      final firstSessionNotifs = NotificationsService();
      var attempts = 0;
      while (!firstSessionNotifs.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('NotificationsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await _pumpNotifications(tester, requests: requests, notificationsService: firstSessionNotifs);
      await tester.tap(find.text('Application Needs Correction'));
      await tester.pumpAndSettle();

      // Simulate an app restart: a brand-new NotificationsService instance
      // that restores its read-ids from the same SharedPreferences (never
      // reset in this test), same RequestsService data untouched.
      final restarted = NotificationsService();
      attempts = 0;
      while (!restarted.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('NotificationsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await _pumpNotifications(tester, requests: requests, notificationsService: restarted);

      // Still exactly one correction card — same id, still remembered read.
      expect(find.text('Application Needs Correction'), findsOneWidget);
      final flaggedId = requests.all.firstWhere((r) => r.id == request.id).flaggedRequirements.single.id;
      expect(restarted.isRead('correction-${request.id}-$flaggedId'), isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('Re-flagged in a later verification cycle', () {
    testWidgets('13: a fresh correction event after resolve+resubmit is a genuinely new, unread notification', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Proof of Residency',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(request.id, requirementLabel: 'Proof of residency', reason: 'Expired.');
      final firstFlaggedId = requests.all.firstWhere((r) => r.id == request.id).flaggedRequirements.single.id;

      final notifService = NotificationsService();
      var attempts = 0;
      while (!notifService.loaded) {
        attempts++;
        if (attempts > 100) throw StateError('NotificationsService never finished loading.');
        await tester.pump(const Duration(milliseconds: 1));
      }
      await notifService.markRead('correction-${request.id}-$firstFlaggedId');

      // Resolve and resubmit — reaches a normal re-verification state.
      await requests.replaceFlaggedRequirement(
        request.id,
        flaggedId: firstFlaggedId,
        newAttachment: _fakeAttachment('residency-v2.pdf', 'Proof of residency'),
      );
      await requests.resubmitApplication(request.id);

      // Flagged again in this new cycle — a brand-new FlaggedRequirement.
      await requests.flagAdditionalDocuments(request.id, requirementLabel: 'Proof of residency', reason: 'Still unclear.');
      final secondFlaggedId = requests.all.firstWhere((r) => r.id == request.id).flaggedRequirements.last.id;
      expect(secondFlaggedId, isNot(firstFlaggedId));

      await _pumpNotifications(tester, requests: requests, notificationsService: notifService);

      // Both the resolved-and-read old one and the new unread one show up —
      // history isn't deleted (see AFTER RESUBMISSION requirement).
      expect(find.text('Application Needs Correction'), findsNWidgets(2));
      expect(notifService.isRead('correction-${request.id}-$firstFlaggedId'), isTrue);
      expect(notifService.isRead('correction-${request.id}-$secondFlaggedId'), isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('Tulong correction notification', () {
    testWidgets('14: works identically for a Tulong request (Educational Assistance)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Educational Assistance',
        category: ServiceCategory.tulong,
        office: 'Office of the Municipal Mayor',
        purpose: 'Scholarship program application.',
        expectedDays: '10-15 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'Certificate of Enrollment',
        reason: 'Does not match the current academic term.',
      );

      await _pumpNotifications(tester, requests: requests);

      expect(find.text('Application Needs Correction'), findsOneWidget);
      expect(find.textContaining('Educational Assistance'), findsWidgets);
      expect(find.textContaining('Certificate of Enrollment'), findsWidgets);
      await tester.tap(find.text('Replace Document'));
      await tester.pumpAndSettle();
      expect(find.byType(RequestDetailScreen), findsOneWidget);
      expect(find.text(request.referenceNumber), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Resolved correction cannot incorrectly allow another replacement', () {
    testWidgets('15: once replaced, the notification keeps existing (read-only) but offers no Replace Document', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Proof of Residency',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(request.id, requirementLabel: 'Proof of residency', reason: 'Expired.');
      final flaggedId = requests.all.firstWhere((r) => r.id == request.id).flaggedRequirements.single.id;
      await requests.replaceFlaggedRequirement(
        request.id,
        flaggedId: flaggedId,
        newAttachment: _fakeAttachment('residency-v2.pdf', 'Proof of residency'),
      );

      await _pumpNotifications(tester, requests: requests);

      // Still present as history, but no longer offers a replacement.
      expect(find.text('Application Needs Correction'), findsOneWidget);
      expect(find.text('Replace Document'), findsNothing);
      expect(find.textContaining('already been addressed'), findsOneWidget);

      // Tapping it still routes to the current Request Detail state.
      await tester.tap(find.text('Application Needs Correction'));
      await tester.pumpAndSettle();
      expect(find.byType(RequestDetailScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Rejected requests never expose correction actions', () {
    testWidgets('16: a request rejected after being flagged shows no Replace Document / Resubmit anywhere', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Proof of Residency',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(request.id, requirementLabel: 'Proof of residency', reason: 'Expired.');
      await requests.rejectDemo(request.id, reason: 'Could not verify the submitted documents.');

      await _pumpNotifications(tester, requests: requests);

      // The correction notification stays as history (same "don't delete
      // history" rule as a resolved one — see test 15) but is no longer
      // actionable at all once the request has moved past Under Review:
      // no Replace Document, and (per the Rejected/correction distinction)
      // no Resubmit Application either.
      expect(find.text('Application Needs Correction'), findsOneWidget);
      expect(find.text('Replace Document'), findsNothing);
      expect(find.text('Resubmit Application'), findsNothing);

      // Tapping it still routes to the Request Detail, which now shows the
      // Rejected panel — never a correction/resubmit affordance.
      await tester.tap(find.text('Application Needs Correction'));
      await tester.pumpAndSettle();
      expect(find.text('Application Rejected'), findsOneWidget);
      // findsWidgets, not findsOneWidget — the previous (Notifications)
      // route is still in the tree underneath this pushed one, and its own
      // generic "Rejected" status notification shares this same reason
      // text, which is expected and unrelated to what this test verifies.
      expect(find.textContaining('Could not verify the submitted documents.'), findsWidgets);
      expect(find.text('Resubmit Application'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Resubmission resolves the correction notification', () {
    testWidgets('after replacing the flag and resubmitting, the request ID is unchanged and the correction '
        'notification no longer presents as unresolved', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Proof of Residency',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      final originalId = request.id;
      final originalReference = request.referenceNumber;

      await requests.flagAdditionalDocuments(request.id, requirementLabel: 'Proof of residency', reason: 'Expired.');
      final flaggedId = requests.all.firstWhere((r) => r.id == request.id).flaggedRequirements.single.id;
      await requests.replaceFlaggedRequirement(
        request.id,
        flaggedId: flaggedId,
        newAttachment: _fakeAttachment('residency-v2.pdf', 'Proof of residency'),
      );
      await requests.resubmitApplication(request.id);

      final resubmitted = requests.all.firstWhere((r) => r.id == originalId);
      expect(resubmitted.id, originalId); // same request/reference throughout
      expect(resubmitted.referenceNumber, originalReference);
      expect(resubmitted.status, 'Under Verification'); // Under Review -> Resubmitted -> Under Verification

      await _pumpNotifications(tester, requests: requests);

      // The correction notification is still there as history, but no
      // longer offers a replacement action and no longer reads as an
      // open/unresolved correction.
      expect(find.text('Application Needs Correction'), findsOneWidget);
      expect(find.text('Replace Document'), findsNothing);
      expect(find.text('Resubmit Application'), findsNothing);
      expect(find.textContaining('already been addressed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Approved / Mark to Release / Released notifications still work', () {
    testWidgets('each stage of the normal success path still produces its own generic notification', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Proof of Residency',
        expectedDays: '1-2 working days',
        attachments: const [],
        requiresPayment: true,
        fee: '₱50.00',
        paymentMethod: 'GCash',
      );
      // Never flagged — this request only ever walks the plain forward
      // sequence, confirming the correction-notification changes above
      // never interfere with it.
      while (requests.canAdvance(request.id)) {
        await requests.advanceMilestone(request.id);
      }

      final finalRequest = requests.all.firstWhere((r) => r.id == request.id);
      expect(finalRequest.status, 'Released'); // Approved -> Mark to Release -> Released

      await _pumpNotifications(tester, requests: requests);

      expect(find.textContaining('Barangay Clearance — Approved'), findsOneWidget);
      expect(find.textContaining('Barangay Clearance — Mark to Release'), findsOneWidget);
      expect(find.textContaining('Barangay Clearance — Released'), findsOneWidget);
      // None of these are correction notifications.
      expect(find.text('Application Needs Correction'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Newest-first chronological sorting, not a manual pin', () {
    testWidgets('a freshly-flagged correction notification sorts above an older Approved update purely by '
        'timestamp', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);

      // An older request that reached Approved a while ago — a genuinely
      // "older" notification, per the same wording as the reported issue.
      final olderRequest = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Certificate of Residency',
        category: ServiceCategory.dokyu,
        office: 'Civil Registrar',
        purpose: 'Bank Requirement',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.advanceMilestone(olderRequest.id); // -> Under Verification
      await requests.advanceMilestone(olderRequest.id); // -> Approved, timestamped "now"

      // A brand-new correction event on a different request, created after
      // the above.
      final newerRequest = await requests.submit(
        applicantId: _verifiedDemoId,
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Proof of Residency',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(
        newerRequest.id,
        requirementLabel: 'One (1) valid government-issued ID',
        reason: 'The submitted "One (1) valid government-issued ID" could not be verified.',
      );

      await _pumpNotifications(tester, requests: requests);

      // No manual pin — plain chronological order. The just-created
      // correction notification is above the older Approved one because it
      // genuinely happened more recently, not because correction
      // notifications are special-cased to the top of the list.
      final correctionY = tester.getTopLeft(find.text('Application Needs Correction')).dy;
      final olderApprovedY = tester.getTopLeft(find.textContaining('Certificate of Residency — Approved')).dy;
      expect(correctionY, lessThan(olderApprovedY));
      expect(tester.takeException(), isNull);
    });
  });
}

Attachment _fakeAttachment(String fileName, String documentTypeLabel) {
  return Attachment(
    id: 'att-$fileName',
    fileName: fileName,
    category: AttachmentCategory.pdf,
    sizeBytes: 12345,
    bytes: Uint8List(0),
    addedAt: DateTime(2026, 1, 1),
    documentTypeLabel: documentTypeLabel,
  );
}
