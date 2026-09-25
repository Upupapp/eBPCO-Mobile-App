import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';
import '../models/receipt.dart';

/// Captures [key]'s [RenderRepaintBoundary] as high-quality PNG bytes —
/// used to export a receipt widget exactly as it's displayed, without
/// needing a separate print-layout implementation.
Future<Uint8List> captureRepaintBoundary(GlobalKey key) async {
  final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  // 2.5x the logical pixel size — sharp enough to read clearly once saved
  // or shared, without producing an unreasonably large file for a receipt
  // card.
  final image = await boundary.toImage(pixelRatio: 2.5);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

/// `Teresa, Rizal_<Method>_<Service>_<RequestRef>.png`, sanitized to safe
/// filename characters only.
String receiptFilename(Receipt receipt) {
  final method = switch (receipt.type) {
    ReceiptType.gcash => 'GCash',
    ReceiptType.maya => 'Maya',
    ReceiptType.onsite => 'Onsite',
    ReceiptType.free => 'Free',
    // An exported receipt is the copy a citizen keeps or forwards, so this
    // must not name a method the build could not read. A word rather than
    // the on-screen em dash, because this one lands in a filename.
    ReceiptType.unknown => 'Unknown',
  };
  final service = _sanitize(receipt.serviceName);
  final ref = _sanitize(receipt.requestReferenceNumber);
  return 'Teresa, Rizal_${method}_${service}_$ref.png';
}

String _sanitize(String value) => value.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_').replaceAll(RegExp(r'_+'), '_');

/// Hands [bytes] to the platform as a real, named file — never a claimed
/// success without actually reaching the platform. share_plus already
/// covers the platform difference this needs: a native save/share sheet on
/// mobile, and on Flutter Web either the real Web Share API (browsers that
/// support sharing files — mostly mobile browsers) or, when that isn't
/// supported (desktop browsers, which is what this was verified against),
/// its own documented [ShareParams.downloadFallbackEnabled] fallback —
/// building a real `<a download>` anchor and clicking it, i.e. an actual
/// browser download, not a simulated one.
Future<void> exportReceiptBytes({required Uint8List bytes, required String filename}) async {
  final file = XFile.fromData(bytes, name: filename, mimeType: 'image/png');
  await SharePlus.instance.share(
    ShareParams(files: [file], fileNameOverrides: [filename], downloadFallbackEnabled: true),
  );
}
