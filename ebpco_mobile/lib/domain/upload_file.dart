import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A file made ready for `POST /documents` or a resubmission.
typedef ReadyUpload = ({Uint8List bytes, String fileName});

/// What [prepareUpload] works on — one value, so it can run on another isolate.
typedef UploadInput = ({String fileName, Uint8List bytes, int maxFileBytes});

/// Why a file cannot be sent, already worded for the citizen.
class UploadRefused implements Exception {
  final String message;
  const UploadRefused(this.message);

  @override
  String toString() => message;
}

/// A picked file whose bytes the phone would not hand over (typically a cloud
/// file that was never downloaded).
const unreadableFile = 'This file could not be read from your phone. Save it to the phone first, then attach it again.';

/// Photos above this are shrunk even when the server would take them: every
/// megabyte is minutes on a weak mobile signal, and a phone camera's full
/// resolution adds nothing an officer can read.
const _comfortBytes = 4 * 1024 * 1024;

/// Longest side and JPEG quality for a photo that has to be re-encoded, tried
/// in order until one fits. The first keeps about 270 dpi across an A4 page,
/// so the small print of a title or a plan stays readable; the rest are only
/// reached for a file that is still over the server's limit.
const _ladder = [(3200, 85), (2560, 80), (2048, 75), (1600, 70), (1280, 65)];

enum _Format { pdf, jpeg, png }

/// Identified by the bytes, never the name — the same way the server does
/// (content-inspection.ts), so what is refused here is what it would refuse.
_Format? _detect(Uint8List bytes) {
  bool startsWith(List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }

  if (startsWith(const [0x25, 0x50, 0x44, 0x46, 0x2d])) return _Format.pdf; // %PDF-
  if (startsWith(const [0xff, 0xd8, 0xff])) return _Format.jpeg;
  if (startsWith(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) return _Format.png;
  return null;
}

/// The server refuses a file whose extension disagrees with its bytes; a PNG
/// saved as ".jpg" by some other app is renamed here instead.
String _named(String fileName, _Format format) {
  final allowed = switch (format) {
    _Format.pdf => const ['pdf'],
    _Format.jpeg => const ['jpg', 'jpeg'],
    _Format.png => const ['png'],
  };
  final dot = fileName.lastIndexOf('.');
  final stem = dot > 0 ? fileName.substring(0, dot) : fileName;
  final extension = dot > 0 ? fileName.substring(dot + 1).toLowerCase() : '';
  return allowed.contains(extension) ? fileName : '$stem.${allowed.first}';
}

/// A JPEG's EXIF orientation (1 = as stored), or 1 when it has none.
int _orientationOf(Uint8List jpeg) {
  try {
    return img.decodeJpgExif(jpeg)?.imageIfd.orientation ?? 1;
  } catch (_) {
    return 1;
  }
}

/// "732 KB", "3.4 MB", "20 MB".
String describeSize(int bytes) {
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  final megabytes = bytes / (1024 * 1024);
  return '${megabytes >= 10 ? megabytes.round() : megabytes.toStringAsFixed(1)} MB';
}

/// Makes a picked file something the Municipality's system will accept, or
/// says why it cannot be.
///
/// A PDF is sent as it is, if it fits. A photo is turned upright — the server
/// strips every EXIF block, including the orientation tag a phone camera
/// relies on, so a portrait shot of a document would otherwise be kept
/// sideways — and shrunk when it is over the limit or needlessly large. Its
/// other metadata (GPS, device) never leaves the phone.
///
/// Throws [UploadRefused]; runs on another isolate (see `readyForUpload`).
ReadyUpload prepareUpload(UploadInput input) {
  final (:fileName, :bytes, :maxFileBytes) = input;

  final format = _detect(bytes);
  if (format == null) {
    throw UploadRefused('"$fileName" is not a PDF, JPG or PNG file. Only those can be uploaded.');
  }
  final name = _named(fileName, format);

  if (format == _Format.pdf) {
    if (bytes.length <= maxFileBytes) return (bytes: bytes, fileName: name);
    throw UploadRefused(
      '"$fileName" is ${describeSize(bytes.length)}, and the Municipality\'s system accepts files up to '
      '${describeSize(maxFileBytes)}. Save or scan it as a smaller PDF, or take photos of the pages instead.',
    );
  }

  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) {
    // Not something this phone can open; the server judges it by its own rules.
    if (bytes.length <= maxFileBytes) return (bytes: bytes, fileName: name);
    throw UploadRefused(
      '"$fileName" is ${describeSize(bytes.length)}, over the ${describeSize(maxFileBytes)} the Municipality\'s '
      'system accepts, and could not be made smaller here. Try a smaller photo.',
    );
  }

  // Read from the file itself: the decoder applies the orientation tag to the
  // pixels and then drops it, so the decoded image never shows a turned photo.
  final turned = format == _Format.jpeg && _orientationOf(bytes) > 1;
  final longest = math.max(decoded.width, decoded.height);
  if (!turned && bytes.length <= math.min(maxFileBytes, _comfortBytes) && longest <= _ladder.first.$1) {
    return (bytes: bytes, fileName: name);
  }

  // Already upright from the decoder (above); bakeOrientation is only a guard
  // for a format whose decoder does not.
  var upright = img.bakeOrientation(decoded);
  upright.exif = img.ExifData();
  if (upright.hasAlpha) {
    // JPEG has no transparency; see-through parts would otherwise turn black.
    final white = img.fill(img.Image(width: upright.width, height: upright.height), color: img.ColorRgb8(255, 255, 255));
    upright = img.compositeImage(white, upright);
  }

  for (final (side, quality) in _ladder) {
    final sized = math.max(upright.width, upright.height) <= side
        ? upright
        : upright.width >= upright.height
            ? img.copyResize(upright, width: side, interpolation: img.Interpolation.average)
            : img.copyResize(upright, height: side, interpolation: img.Interpolation.average);
    final jpeg = img.encodeJpg(sized, quality: quality);
    if (jpeg.length <= maxFileBytes) return (bytes: jpeg, fileName: _named(fileName, _Format.jpeg));
  }
  throw UploadRefused('"$fileName" is too large to upload, even after shrinking it. Try the photo again at a lower resolution.');
}
