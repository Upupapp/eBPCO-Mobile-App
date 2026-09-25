import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/app_dialogs.dart';

/// The kind of protected device resource an action needs — drives which
/// explanation copy/permission this goes through. Every screen in the app
/// that touches the camera, photo library, or a document picker routes
/// through the two functions below ([pickImageProtected] /
/// [pickDocumentProtected]) rather than calling `image_picker`/
/// `file_picker` directly, so this one file is the only place permission
/// logic lives — never duplicated per screen.
enum ProtectedResource { camera, photos, document }

class _ResourceCopy {
  final String title;
  final String explanation;
  final String deniedMessage;
  const _ResourceCopy({required this.title, required this.explanation, required this.deniedMessage});
}

const _copy = <ProtectedResource, _ResourceCopy>{
  ProtectedResource.camera: _ResourceCopy(
    title: 'Camera Access Required',
    explanation: 'Teresa, Rizal needs access to your camera so you can take a photo and attach it to your request.',
    deniedMessage: 'Permission was not granted. You can continue using the app, but this feature requires access to your camera.',
  ),
  ProtectedResource.photos: _ResourceCopy(
    title: 'Photo Access Required',
    explanation: 'Teresa, Rizal needs access to your photos so you can select an image to attach to your request.',
    deniedMessage: 'Permission was not granted. You can continue using the app, but this feature requires access to your photos.',
  ),
  ProtectedResource.document: _ResourceCopy(
    title: 'Document Access',
    explanation: 'Teresa, Rizal needs permission to let you choose a document to attach to your request.',
    deniedMessage: 'Permission was not granted. You can continue using the app, but this feature requires access to choose a document.',
  ),
};

/// Explanation dialogs are only ever shown in direct response to the
/// citizen tapping a specific protected action (Take a photo / Choose from
/// gallery / Choose a document) — never at startup, splash, onboarding, or
/// merely opening a tab/form. Acknowledged once per resource *for this
/// app session* (plain in-memory Set, not persisted) so re-attaching a
/// second photo to the same or a different form doesn't re-explain
/// something the citizen already said yes to a moment ago — resets
/// naturally on a full relaunch, same "session-only" pattern already used
/// elsewhere in this app (see SectionBanner/PromotionalBannerDialog).
final Set<ProtectedResource> _acknowledgedThisSession = {};

/// Shows the Teresa-styled explanation dialog (Not Now / Continue) for
/// [resource], skipping it if already acknowledged this session. Returns
/// true only if the citizen tapped Continue.
Future<bool> _confirmExplanation(BuildContext context, ProtectedResource resource) async {
  if (_acknowledgedThisSession.contains(resource)) return true;
  final copy = _copy[resource]!;
  final proceed = await AppDialogs.confirm(
    context,
    title: copy.title,
    message: copy.explanation,
    cancelLabel: 'Not Now',
    confirmLabel: 'Continue',
  );
  if (proceed) _acknowledgedThisSession.add(resource);
  return proceed;
}

Future<void> _showPermanentlyDeniedDialog(BuildContext context) async {
  final openSettings = await AppDialogs.confirm(
    context,
    title: 'Permission Required',
    message: 'This permission is currently disabled. You can enable it from your device settings.',
    cancelLabel: 'Not Now',
    confirmLabel: 'Open Settings',
  );
  if (openSettings) await openAppSettings();
}

Future<void> _showDeniedDialog(BuildContext context, ProtectedResource resource) {
  return AppDialogs.info(context, title: _copy[resource]!.title, message: _copy[resource]!.deniedMessage);
}

/// Camera or gallery, gated by the explanation dialog and (native
/// platforms only) the actual runtime permission. Returns the picked
/// file, or null if the citizen declined the explanation, cancelled the
/// picker, or the permission wasn't available.
///
/// Deliberately does *not* force a `Permission.request()` call up front on
/// every attempt — `image_picker` already manages the native prompt
/// itself where one is actually required (and, on Android 13+ gallery
/// picks in particular, the OS Photo Picker needs no runtime permission
/// grant at all — forcing one anyway would be exactly the "broad/
/// unrestricted access" this must avoid). `permission_handler` is used
/// only to (a) short-circuit straight to the "permanently denied ->
/// Open Settings" dialog when that's already the known state, so the
/// picker isn't attempted only to silently fail, and (b) after a null
/// result, distinguish "the citizen just cancelled the picker" (do
/// nothing, exactly like today) from "the permission was actually denied"
/// (show the friendly denied message).
Future<XFile?> pickImageProtected(BuildContext context, {required ImageSource source}) async {
  final resource = source == ImageSource.camera ? ProtectedResource.camera : ProtectedResource.photos;
  if (!await _confirmExplanation(context, resource)) return null;
  if (!context.mounted) return null;

  // Flutter Web has no native runtime permission model to query — the
  // browser handles its own camera/file-access prompts as part of the
  // picker call itself, so permission_handler is skipped entirely here.
  if (kIsWeb) {
    return ImagePicker().pickImage(source: source, imageQuality: 85);
  }

  final permission = source == ImageSource.camera ? Permission.camera : Permission.photos;
  final preStatus = await permission.status;
  if (preStatus.isPermanentlyDenied) {
    if (context.mounted) await _showPermanentlyDeniedDialog(context);
    return null;
  }

  final file = await ImagePicker().pickImage(source: source, imageQuality: 85);
  if (file != null) return file;
  if (!context.mounted) return null;

  final postStatus = await permission.status;
  if (postStatus.isPermanentlyDenied) {
    if (context.mounted) await _showPermanentlyDeniedDialog(context);
  } else if (postStatus.isDenied) {
    if (context.mounted) await _showDeniedDialog(context, resource);
  }
  // Otherwise the permission is fine and the citizen simply cancelled the
  // picker — return to the form without any error, exactly as before.
  return null;
}

/// Document/PDF/DOCX picker, gated only by the explanation dialog — the
/// OS's own secure document picker (Storage Access Framework on Android,
/// UIDocumentPickerViewController on iOS, a native `<input type=file>` on
/// Web) grants access to just the file the citizen chooses without ever
/// needing a broad filesystem/storage permission, so there is nothing for
/// permission_handler to check here at all.
Future<FilePickerResult?> pickDocumentProtected(
  BuildContext context, {
  required List<String> allowedExtensions,
  bool withData = true,
}) async {
  if (!await _confirmExplanation(context, ProtectedResource.document)) return null;
  if (!context.mounted) return null;
  return FilePicker.pickFiles(type: FileType.custom, allowedExtensions: allowedExtensions, withData: withData);
}
