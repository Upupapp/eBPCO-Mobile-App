import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Builds the right [ImageProvider] for a picked file across every
/// platform this app ships to — the single place platform-specific
/// attachment/photo preview logic lives, so screens never need their own
/// `kIsWeb` branches.
///
/// Prefers in-memory [bytes] (works everywhere, including Flutter Web,
/// where a picked file's `path` is a blob: URL or entirely absent).
/// `dart:io`'s `File` cannot open a blob: URL — passing one into `File()`
/// and then reading it (e.g. via `Image.file`/`FileImage`) is exactly what
/// throws `Unsupported operation: _Namespace` on web. So [path] is only
/// ever used as a fallback, and only on native platforms (Android/iOS/
/// desktop) — e.g. a path restored from a previous session where bytes
/// weren't persisted but the real file may still be on disk.
///
/// Returns null when neither is usable, so callers show a plain
/// placeholder instead of crashing.
ImageProvider? pickedFileImageProvider({Uint8List? bytes, String? path}) {
  if (bytes != null) return MemoryImage(bytes);
  if (!kIsWeb && path != null && path.isNotEmpty) {
    return FileImage(File(path));
  }
  return null;
}
