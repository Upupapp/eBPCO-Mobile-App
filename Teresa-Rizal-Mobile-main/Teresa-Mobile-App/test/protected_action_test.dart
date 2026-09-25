// Verifies the Teresa-styled explanation dialog shown before any
// protected device access (camera / photos / document) — correct
// title/message/buttons per action, and that "Not Now" cleanly returns to
// the form without ever attempting the actual system picker. The
// "Continue" -> real image_picker/file_picker/permission_handler path
// isn't exercised here: those plugins have no platform-channel handler
// under `flutter test` (true of this whole project already — no existing
// test taps through to a real picker call either), so that half of the
// flow is manual/device-QA territory, same as it always was for the
// underlying pickers themselves.
//
// These tests used to reach the picker sheet through `AttachmentPicker`,
// which no screen ever rendered — so they proved the permission dialogs
// worked in a widget no citizen could open, and would not have caught the
// shipping widget wiring a different message to the wrong action. They now
// host on `RequirementUploader`, which is what Dokyu and Tulong actually
// render. `AttachmentPicker` was deleted with FE 08.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:teresa_rizal/theme/app_colors.dart';
import 'package:teresa_rizal/utils/requirement_document_type.dart';
import 'package:teresa_rizal/widgets/requirement_uploader.dart';

const _requirement = RequirementInfo(
  label: 'Valid ID',
  documentType: 'Valid ID',
  isRequired: true,
  requiresUpload: true,
);

Widget _host({void Function()? onAttach}) => MaterialApp(
      home: Scaffold(
        body: RequirementUploader(
          requirement: _requirement,
          attachment: null,
          accent: AppColors.brand600,
          existingMasterDoc: null,
          onAttachNew: (_) => onAttach?.call(),
          onUseExisting: () {},
          onRemove: () {},
        ),
      ),
    );

/// Opens the requirement's own upload sheet — the real entry point a citizen
/// taps, labelled per requirement rather than generically.
Future<void> _openPickerSheet(WidgetTester tester, {void Function()? onAttach}) async {
  await tester.pumpWidget(_host(onAttach: onAttach));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Upload Valid ID'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Take Photo shows the Camera Access Required explanation before anything else', (tester) async {
    await _openPickerSheet(tester);

    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();

    expect(find.text('Camera Access Required'), findsOneWidget);
    expect(
      find.text('Teresa, Rizal needs access to your camera so you can take a photo and attach it to your request.'),
      findsOneWidget,
    );
    expect(find.text('Not Now'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Choose Image shows the Photo Access Required explanation', (tester) async {
    await _openPickerSheet(tester);

    await tester.tap(find.text('Choose Image'));
    await tester.pumpAndSettle();

    expect(find.text('Photo Access Required'), findsOneWidget);
    expect(
      find.text('Teresa, Rizal needs access to your photos so you can select an image to attach to your request.'),
      findsOneWidget,
    );
    expect(find.text('Not Now'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Choose File / PDF shows the Document Access explanation, never a broad storage warning', (tester) async {
    await _openPickerSheet(tester);

    await tester.tap(find.text('Choose File / PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Document Access'), findsOneWidget);
    expect(
      find.text('Teresa, Rizal needs permission to let you choose a document to attach to your request.'),
      findsOneWidget,
    );
    expect(find.textContaining('all your files'), findsNothing);
    expect(find.text('Not Now'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Not Now closes the explanation and returns to the form untouched — no attachment added, no error', (tester) async {
    var attached = false;
    await _openPickerSheet(tester, onAttach: () => attached = true);

    await tester.tap(find.text('Take Photo'));
    await tester.pumpAndSettle();
    expect(find.text('Camera Access Required'), findsOneWidget);

    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();

    expect(find.text('Camera Access Required'), findsNothing);
    // Back on the plain empty-uploader form — not a broken/blocked screen.
    expect(find.text('Upload Valid ID'), findsOneWidget);
    expect(attached, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the explanation dialog uses the existing Teresa, Rizal confirm-sheet styling (rounded sheet, primary/secondary buttons)', (tester) async {
    await _openPickerSheet(tester);
    await tester.tap(find.text('Choose File / PDF'));
    await tester.pumpAndSettle();

    // Same bottom-sheet shell every other Teresa, Rizal confirmation uses
    // (AppDialogs.confirm), not a bespoke error-style AlertDialog.
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
