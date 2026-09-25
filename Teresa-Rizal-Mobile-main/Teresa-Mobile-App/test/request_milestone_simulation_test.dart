// Functional coverage for the Mobile-only final request-flow correction
// pass — the simplified 5-stage citizen tracking lifecycle (Submitted ->
// Under Verification -> Approved -> Ready for Pick Up -> Completed) and its
// two branches off Under Verification (Rejected, and Under Review with its
// re-verification loop). Payment now happens during the application's own
// submission flow (see RequestsService.submit), never as a tracking
// milestone here — there is no "Waiting for Payment" or "Choose Payment
// Method (Demo)" step anymore; see receipt_system_test.dart for
// payment/receipt coverage. Drives the real RequestDetailScreen (not just
// RequestMilestoneTimeline in isolation) so the demo controls and
// rejection/under-review cards are all exercised the way a presenter
// actually would.
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:teresa_rizal/models/attachment.dart';
import 'package:teresa_rizal/models/request_milestones.dart';
import 'package:teresa_rizal/screens/shared/request_detail_screen.dart';
import 'package:teresa_rizal/services/citizen_session_service.dart';
import 'package:teresa_rizal/services/master_file_service.dart';
import 'package:teresa_rizal/services/requests_service.dart';
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

Future<RequestsService> _pumpDetail(WidgetTester tester, String requestId) async {
  // The default 800x600 test canvas is unusually wide/short and leaves
  // this screen's lower content (the demo controls, well below the info
  // card + full timeline) outside the initial render/cache extent of the
  // ListView's Sliver — a realistic phone viewport avoids that, matching
  // every other functional suite in this app.
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final requests = RequestsService(seedDemoData: true);
  var attempts = 0;
  await tester.pumpWidget(const SizedBox.shrink());
  while (!requests.loaded) {
    attempts++;
    if (attempts > 100) throw StateError('RequestsService never finished loading.');
    await tester.pump(const Duration(milliseconds: 1));
  }

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<RequestsService>.value(value: requests),
        ChangeNotifierProvider(create: (_) => CitizenSessionService()),
        ChangeNotifierProvider(create: (_) => MasterFileService()),
      ],
      child: MaterialApp(home: RequestDetailScreen(requestId: requestId)),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}

Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  // Drives the ListView's ScrollPosition directly to the very bottom rather
  // than a gesture-based drag/scrollUntilVisible — both of those compute an
  // offset from the target's *current* on-screen rect, which is unreliable
  // once this screen's content is taller than a single scroll increment.
  final scrollable = find.byType(Scrollable).first;
  final position = tester.state<ScrollableState>(scrollable).position;
  position.jumpTo(position.maxScrollExtent);
  await tester.pumpAndSettle();
  await tester.tap(finder, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _tapNextDemoStep(WidgetTester tester) => _scrollToAndTap(tester, find.widgetWithText(AppButton, 'Next Demo Step'));

void main() {
  group('Free/no-payment path (Medical Assistance-style Tulong)', () {
    testWidgets('demo-tulong-medical advances Under Verification -> ... -> Released with no payment steps', (
      tester,
    ) async {
      final requests = await _pumpDetail(tester, 'demo-tulong-medical');

      expect(requests.all.firstWhere((r) => r.id == 'demo-tulong-medical').requiresPayment, isFalse);

      var guard = 0;
      while (requests.canAdvance('demo-tulong-medical')) {
        guard++;
        if (guard > 10) fail('Next Demo Step never reached the end of the sequence.');
        await _tapNextDemoStep(tester);
      }

      expect(find.text(RequestMilestones.released), findsWidgets);
      expect(find.text('Waiting for Payment'), findsNothing);
      expect(find.text('Choose Payment Method (Demo)'), findsNothing);
      expect(tester.takeException(), isNull);

      final finalRequest = requests.all.firstWhere((r) => r.id == 'demo-tulong-medical');
      expect(finalRequest.status, 'Released');
      expect(finalRequest.receipt, isNull); // Tulong never has a receipt
    });
  });

  group('Demonstration Controls — "Needs Manual Verification (Demo)" removed', () {
    testWidgets('shows exactly Next Demo Step, Request Additional Documents (Demo), and Reject Request (Demo)', (
      tester,
    ) async {
      final requests = await _pumpDetail(tester, 'demo-dokyu-business-permit');
      final scrollable = find.byType(Scrollable).first;
      tester.state<ScrollableState>(scrollable).position.jumpTo(
        tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppButton, 'Next Demo Step'), findsOneWidget);
      expect(find.text('Request Additional Documents (Demo)'), findsOneWidget);
      expect(find.text('Reject Request (Demo)'), findsOneWidget);
      expect(find.text('Needs Manual Verification (Demo)'), findsNothing);

      // The remaining controls still work: flagging still reaches Under
      // Review exactly as before removing the manual-verification trigger.
      await requests.flagAdditionalDocuments(
        'demo-dokyu-business-permit',
        requirementLabel: 'Proof of residency',
        reason: 'Needs a clearer copy.',
      );
      await tester.pumpAndSettle();
      expect(
        requests.all.firstWhere((r) => r.id == 'demo-dokyu-business-permit').status,
        RequestMilestones.underReview,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Paid Dokyu path (Barangay Clearance, ₱50.00) — payment already settled before tracking begins', () {
    testWidgets(
      'the seeded Approved request already has its receipt; tracking continues straight to Mark to Release -> Released',
      (tester) async {
        final requests = await _pumpDetail(tester, 'demo-dokyu-barangay-clearance');
        final seeded = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance');
        expect(seeded.requiresPayment, isTrue);
        expect(seeded.status, 'Approved');
        // Payment/receipt are settled at submission time now — never a
        // tracking milestone the citizen has to walk through here.
        expect(seeded.receipt, isNotNull);
        expect(seeded.paymentMethod, isNotNull);

        await _tapNextDemoStep(tester); // Approved -> Mark to Release
        expect(find.text(RequestMilestones.markToRelease), findsWidgets);

        await _tapNextDemoStep(tester); // Mark to Release -> Released

        final request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-barangay-clearance');
        expect(request.status, 'Released');
        expect(request.receipt, isNotNull); // survives to the end of the sequence
        expect(find.widgetWithText(AppButton, 'Next Demo Step'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Rejected branch', () {
    testWidgets('Reject (Demo) branches to Rejected and shows the reason card, no further advance possible', (
      tester,
    ) async {
      final requests = await _pumpDetail(tester, 'demo-tulong-financial');
      expect(requests.all.firstWhere((r) => r.id == 'demo-tulong-financial').status, 'Approved');

      await _scrollToAndTap(tester, find.text('Reject Request (Demo)'));
      expect(find.text('Reject this request? (Demo)'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Reject (Demo)'));
      await tester.pumpAndSettle();

      final request = requests.all.firstWhere((r) => r.id == 'demo-tulong-financial');
      expect(request.status, 'Rejected');
      // Financial Assistance (AICS) has its own realistic, service-specific
      // rejection reason (CatalogItem.demoRejectionReason) rather than the
      // generic ID-mismatch fallback other services without one still use.
      expect(request.adminRemarks, contains('social case study'));
      expect(find.text('Application Rejected'), findsOneWidget);
      expect(find.textContaining('social case study'), findsWidgets);
      // No demo controls remain once terminal.
      expect(find.widgetWithText(AppButton, 'Next Demo Step'), findsNothing);
      expect(find.text('Reject Request (Demo)'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Under Review / re-verification loop (Needs Additional Documents)', () {
    testWidgets(
      'flagging branches to Under Review outside the linear sequence; a wrong resubmission loops back to Under '
      'Review again (no hard-coded max), a correct one reaches Approved',
      (tester) async {
        final requests = await _pumpDetail(tester, 'demo-dokyu-business-permit');
        expect(requests.all.firstWhere((r) => r.id == 'demo-dokyu-business-permit').status, 'Under Verification');

        await requests.flagAdditionalDocuments(
          'demo-dokyu-business-permit',
          requirementLabel: 'Proof of residency',
          reason: 'The submitted "Proof of residency" could not be verified.',
        );
        await tester.pumpAndSettle();

        var request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-business-permit');
        expect(request.status, RequestMilestones.underReview);
        // A branch, not a linear step — Demo Controls' own "Next Demo Step"
        // never applies to Under Review.
        expect(requests.canAdvance('demo-dokyu-business-permit'), isFalse);
        expect(find.widgetWithText(AppButton, 'Next Demo Step'), findsNothing);

        // Still wrong on the first resubmission — replacing the document
        // alone doesn't resubmit; the explicit Resubmit Application step is
        // what actually loops back to Under Verification, then flagged
        // again, back to Under Review with no hard-coded maximum correction
        // count.
        var flaggedId = request.flaggedRequirements.single.id;
        await requests.replaceFlaggedRequirement(
          'demo-dokyu-business-permit',
          flaggedId: flaggedId,
          newAttachment: _fakeAttachment('residency-v2.pdf', 'Proof of residency'),
        );
        request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-business-permit');
        expect(request.status, RequestMilestones.underReview); // still — replacing alone never resubmits
        await requests.resubmitApplication('demo-dokyu-business-permit');
        request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-business-permit');
        expect(request.status, RequestMilestones.underVerification);

        await requests.flagAdditionalDocuments(
          'demo-dokyu-business-permit',
          requirementLabel: 'Proof of residency',
          reason: 'Still not legible enough.',
        );
        await tester.pumpAndSettle();
        request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-business-permit');
        expect(request.status, RequestMilestones.underReview); // looped back, exactly as before

        // Correct this time — resubmits and resumes at Under Verification,
        // from where it can now advance to Approved.
        flaggedId = request.flaggedRequirements.last.id;
        await requests.replaceFlaggedRequirement(
          'demo-dokyu-business-permit',
          flaggedId: flaggedId,
          newAttachment: _fakeAttachment('residency-v3.pdf', 'Proof of residency'),
        );
        await requests.resubmitApplication('demo-dokyu-business-permit');
        await tester.pumpAndSettle();
        expect(requests.canAdvance('demo-dokyu-business-permit'), isTrue);

        await _tapNextDemoStep(tester); // Under Verification -> Approved
        request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-business-permit');
        expect(request.status, 'Approved');
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('Under Review — manual verification flavor (no flagged requirement)', () {
    testWidgets(
      'flagManualVerification branches to Under Review with nothing for the citizen to upload; Continue '
      'Verification (Demo) resumes at Under Verification',
      (tester) async {
        final requests = await _pumpDetail(tester, 'demo-dokyu-business-permit');

        await requests.flagManualVerification('demo-dokyu-business-permit', reason: 'Needs a closer look by staff.');
        await tester.pumpAndSettle();

        var request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-business-permit');
        expect(request.status, RequestMilestones.underReview);
        expect(request.flaggedRequirements, isEmpty);
        // Never presented as a rejection, and never the document-upload card.
        expect(find.text('Application Rejected'), findsNothing);
        expect(find.text('Additional Document Needed'), findsNothing);
        expect(find.text('Under Review'), findsWidgets); // _ManualVerificationCard's own header

        // The button sits near the bottom of the list, below the fold — a
        // Sliver list only builds elements within the current viewport plus
        // cache extent, so it isn't findable until scrolled into view (same
        // reasoning as receipt_system_test.dart's own _scrollToTopAndTap).
        await _scrollToAndTap(tester, find.widgetWithText(AppButton, 'Continue Verification (Demo)'));

        request = requests.all.firstWhere((r) => r.id == 'demo-dokyu-business-permit');
        expect(request.status, RequestMilestones.underVerification);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
