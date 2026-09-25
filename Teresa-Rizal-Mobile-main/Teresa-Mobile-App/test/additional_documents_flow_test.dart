// Coverage for the "Flagged for Replacement" / correction simulation —
// distinct from a full rejectDemo(): the request stays active, one or more
// specific requirements are flagged, the resident replaces each flagged
// document individually via RequestDetailScreen (never auto-resubmitting),
// and only an explicit Resubmit Application call resumes the normal
// milestone sequence.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/attachment.dart';
import 'package:teresa_rizal/models/request_milestones.dart';
import 'package:teresa_rizal/models/service_request.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/mock_catalog.dart';
import 'package:teresa_rizal/services/notifications_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
import 'package:teresa_rizal/services/resident_profile_service.dart';
import 'package:teresa_rizal/widgets/app_button.dart';

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

void main() {
  group('RequestsService.flagAdditionalDocuments / replaceFlaggedRequirement / resubmitApplication', () {
    testWidgets('flagging sets Under Review + an unresolved FlaggedRequirement, distinct from rejectDemo', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: 'ESP-RES-2024-9002',
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Local Employment',
        expectedDays: '1-2 working days',
        attachments: [_fakeAttachment('id.pdf', 'One (1) valid government-issued ID')],
      );

      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'Proof of residency',
        reason: 'The submitted "Proof of residency" could not be verified.',
      );

      final flagged = requests.all.firstWhere((r) => r.id == request.id);
      expect(flagged.status, RequestMilestones.underReview);
      expect(flagged.status, isNot('Rejected'));
      expect(flagged.flaggedRequirements.length, 1);
      expect(flagged.flaggedRequirements.single.requirementLabel, 'Proof of residency');
      expect(flagged.flaggedRequirements.single.isResolved, isFalse);
      expect(flagged.adminRemarks, contains('Proof of residency'));
      expect(flagged.statusHistory.last.status, RequestMilestones.underReview);
      expect(flagged.statusHistory.last.actor, 'Demo Simulation');
    });

    testWidgets('replacing the document alone does NOT resubmit — only resubmitApplication moves to Under Verification', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: 'ESP-RES-2024-9002',
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Local Employment',
        expectedDays: '1-2 working days',
        attachments: [
          _fakeAttachment('id.pdf', 'One (1) valid government-issued ID'),
          _fakeAttachment('old-residency.pdf', 'Proof of residency'),
        ],
      );
      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'Proof of residency',
        reason: 'Please resubmit.',
      );
      final flaggedId = requests.all.firstWhere((r) => r.id == request.id).flaggedRequirements.single.id;

      final newAttachment = _fakeAttachment('new-residency.pdf', 'Proof of residency');
      await requests.replaceFlaggedRequirement(request.id, flaggedId: flaggedId, newAttachment: newAttachment);

      final replaced = requests.all.firstWhere((r) => r.id == request.id);
      // Still Under Review — replacing a document is not the same as
      // resubmitting the whole application.
      expect(replaced.status, RequestMilestones.underReview);
      expect(replaced.flaggedRequirements.single.isResolved, isTrue);
      expect(replaced.attachments.length, 2); // replaced, not appended
      expect(
        replaced.attachments.firstWhere((a) => a.documentTypeLabel == 'Proof of residency').fileName,
        'new-residency.pdf',
      );
      // The other requirement's attachment is completely untouched.
      expect(
        replaced.attachments.firstWhere((a) => a.documentTypeLabel == 'One (1) valid government-issued ID').fileName,
        'id.pdf',
      );
      expect(replaced.statusHistory.last.status, RequestMilestones.underReview); // no new entry from the replace alone

      // Now the explicit resubmit step.
      await requests.resubmitApplication(request.id);
      final resubmitted = requests.all.firstWhere((r) => r.id == request.id);
      expect(resubmitted.status, 'Under Verification');
      expect(resubmitted.statusHistory[resubmitted.statusHistory.length - 2].status, 'Resubmitted');
      expect(resubmitted.statusHistory[resubmitted.statusHistory.length - 2].actor, 'Citizen');
      expect(resubmitted.statusHistory.last.status, 'Under Verification');
      expect(resubmitted.statusHistory.last.actor, 'Demo Simulation');
    });

    testWidgets('resubmitApplication is a no-op while any flagged requirement is still unresolved', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: 'ESP-RES-2024-9002',
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Local Employment',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(request.id, requirementLabel: 'One (1) valid government-issued ID', reason: 'Unclear copy.');
      await requests.flagAdditionalDocuments(request.id, requirementLabel: 'Proof of residency', reason: 'Expired.');

      await requests.resubmitApplication(request.id);
      final stillUnderReview = requests.all.firstWhere((r) => r.id == request.id);
      expect(stillUnderReview.status, RequestMilestones.underReview); // no-op — 2 unresolved flags remain

      final flags = stillUnderReview.flaggedRequirements;
      await requests.replaceFlaggedRequirement(
        request.id,
        flaggedId: flags[0].id,
        newAttachment: _fakeAttachment('id-v2.pdf', 'One (1) valid government-issued ID'),
      );
      await requests.resubmitApplication(request.id);
      expect(requests.all.firstWhere((r) => r.id == request.id).status, RequestMilestones.underReview); // 1 still unresolved

      await requests.replaceFlaggedRequirement(
        request.id,
        flaggedId: flags[1].id,
        newAttachment: _fakeAttachment('residency-v2.pdf', 'Proof of residency'),
      );
      await requests.resubmitApplication(request.id);
      expect(requests.all.firstWhere((r) => r.id == request.id).status, 'Under Verification'); // all resolved now
    });
  });

  group('RequestDetailScreen — Application Needs Correction UI', () {
    Future<RequestsService> pumpDetail(WidgetTester tester, String requestId, RequestsService requests) async {
      tester.view.physicalSize = const Size(390, 844);
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
            ChangeNotifierProvider(create: (_) => NotificationsService()),
          ],
          child: MaterialApp(home: RequestDetailScreen(requestId: requestId)),
        ),
      );
      await tester.pumpAndSettle();
      return requests;
    }

    Future<void> scrollToBottom(WidgetTester tester) async {
      final scrollable = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(scrollable).position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
    }

    testWidgets('flagging via Demo Controls shows the correction panel, never the Rejected panel', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: 'ESP-RES-2024-9002',
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Local Employment',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await pumpDetail(tester, request.id, requests);
      await scrollToBottom(tester);

      await tester.tap(find.text('Request Additional Documents (Demo)'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Flag Document (Demo)'));
      await tester.pumpAndSettle();

      expect(find.text('Application Needs Correction'), findsOneWidget);
      expect(find.text('Application Rejected'), findsNothing);
      expect(find.textContaining('could not be verified'), findsWidgets);
      // Demo Controls disappear while flagged (canAdvance is false — the
      // flagged 'Under Review' entry isn't part of the fixed milestone
      // sequence), matching how they disappear once Rejected.
      expect(find.text('Next Demo Step'), findsNothing);
      // Not resubmittable yet — the flagged document hasn't been replaced.
      expect(tester.widget<AppButton>(find.widgetWithText(AppButton, 'Resubmit Application')).onPressed, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('replacing the flagged requirement enables Resubmit; pressing it resumes the timeline', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final requests = await _readyRequests(tester);
      final request = await requests.submit(
        applicantId: 'ESP-RES-2024-9002',
        applicantName: 'Perlita Quiambao',
        typeName: 'Barangay Clearance',
        category: ServiceCategory.dokyu,
        office: 'Barangay Hall',
        purpose: 'Local Employment',
        expectedDays: '1-2 working days',
        attachments: const [],
      );
      await requests.flagAdditionalDocuments(
        request.id,
        requirementLabel: 'One (1) valid government-issued ID',
        reason: 'Please upload a clearer copy.',
      );
      final flaggedId = requests.all.firstWhere((r) => r.id == request.id).flaggedRequirements.single.id;
      await pumpDetail(tester, request.id, requests);
      await scrollToBottom(tester);

      expect(find.text('Application Needs Correction'), findsOneWidget);

      await requests.replaceFlaggedRequirement(
        request.id,
        flaggedId: flaggedId,
        newAttachment: _fakeAttachment('new-id.pdf', 'One (1) valid government-issued ID'),
      );
      await tester.pumpAndSettle();

      // Still on the correction panel — replacing alone doesn't resubmit —
      // but Resubmit Application is now enabled.
      expect(find.text('Application Needs Correction'), findsOneWidget);
      expect(requests.all.firstWhere((r) => r.id == request.id).status, RequestMilestones.underReview);
      await scrollToBottom(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Resubmit Application'));
      await tester.pumpAndSettle();

      expect(find.text('Application Needs Correction'), findsNothing);
      final resumed = requests.all.firstWhere((r) => r.id == request.id);
      expect(resumed.status, 'Under Verification');
      expect(tester.takeException(), isNull);
    });
  });
}
