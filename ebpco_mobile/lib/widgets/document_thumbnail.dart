import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

import '../core/api/citizen_api.dart';
import '../domain/models.dart';
import '../theme/soft_widget.dart';
import 'soft_card.dart';

/// A small picture of the document itself in place of a generic file icon:
/// the first page of a PDF, or the image, cropped to the tile from the top so
/// the heading of a form or clearance is what shows.
///
/// The file icon stays while the picture loads, and for good when there is
/// nothing to show (a file still being scanned, one quarantined, or no
/// connection). Each file is fetched and drawn once per session: a filed
/// document never changes, so a scroll or a rebuild costs nothing.
class DocumentThumbnail extends StatefulWidget {
  final DocumentEntry doc;
  final double size;

  const DocumentThumbnail({super.key, required this.doc, this.size = 44});

  @override
  State<DocumentThumbnail> createState() => _DocumentThumbnailState();
}

class _DocumentThumbnailState extends State<DocumentThumbnail> {
  late Future<Uint8List?> _picture;

  @override
  void initState() {
    super.initState();
    _picture = thumbnailFor(widget.doc);
  }

  @override
  void didUpdateWidget(DocumentThumbnail old) {
    super.didUpdateWidget(old);
    if (old.doc.id != widget.doc.id) _picture = thumbnailFor(widget.doc);
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = widget.doc.contentType.toLowerCase().contains('pdf');
    final icon = SoftIconTile(
      icon: isPdf ? Icons.picture_as_pdf_outlined : Icons.image_outlined,
      size: widget.size,
    );
    return FutureBuilder<Uint8List?>(
      future: _picture,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null) return icon;
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: SoftColors.white,
            borderRadius: BorderRadius.circular(SoftRadius.sm),
            border: Border.all(color: SoftColors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            // Decoded at tile size, not the photo's full resolution.
            cacheWidth: (widget.size * MediaQuery.devicePixelRatioOf(context) * 2).round(),
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => icon,
          ),
        );
      },
    );
  }
}

/// One picture per document for the life of the app. A failed attempt is
/// forgotten, so the next time the list is shown it tries again.
final Map<String, Future<Uint8List?>> _pictures = {};

Future<Uint8List?> thumbnailFor(DocumentEntry doc) {
  if (doc.quarantined) return Future.value(null);
  return _pictures.putIfAbsent(doc.id, () {
    final future = _queued(() => _draw(doc));
    unawaited(future.then((bytes) {
      if (bytes == null) _pictures.remove(doc.id);
    }));
    return future;
  });
}

/// At most three files fetched at once, so a long list does not open a dozen
/// downloads on a phone connection.
const int _maxAtOnce = 3;
int _running = 0;
final Queue<Completer<void>> _waiting = Queue();

Future<T> _queued<T>(Future<T> Function() task) async {
  if (_running >= _maxAtOnce) {
    final turn = Completer<void>();
    _waiting.add(turn);
    await turn.future;
  }
  _running++;
  try {
    return await task();
  } finally {
    _running--;
    if (_waiting.isNotEmpty) _waiting.removeFirst().complete();
  }
}

Future<Uint8List?> _draw(DocumentEntry doc) async {
  try {
    final url = await CitizenApi.instance.getDocumentContent(doc.id);
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;
    final type = (response.headers['content-type'] ?? doc.contentType).toLowerCase();
    if (type.startsWith('image/')) return response.bodyBytes;
    if (!type.contains('pdf')) return null;

    final pdf = await PdfDocument.openData(response.bodyBytes);
    try {
      final page = await pdf.getPage(1);
      try {
        const width = 180.0;
        final height = width * page.height / page.width;
        final image = await page.render(
          width: width,
          height: height,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        return image?.bytes;
      } finally {
        await page.close();
      }
    } finally {
      await pdf.close();
    }
  } catch (_) {
    return null;
  }
}
