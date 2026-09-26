import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// A picked photo made ready for `PUT /me/photo`.
typedef PreparedPhoto = ({Uint8List bytes, String fileName});

/// Turns a picked photo into what the server should keep: upright, no
/// larger than [maxSide] pixels, and with no metadata.
///
/// Upright matters because the server strips every EXIF block before storing
/// a photo (`metadata-scrubber.ts`) — including the orientation tag a phone
/// camera relies on — so a portrait shot would otherwise be kept sideways.
/// The rotation is baked into the pixels here instead, and the rest of the
/// EXIF (GPS, device) never leaves the phone.
///
/// JPEG out, except an image with transparency stays PNG so its see-through
/// parts do not turn black. Null when the bytes are not an image.
PreparedPhoto? prepareProfilePhoto(Uint8List original, {int maxSide = 800}) {
  final img.Image? decoded;
  try {
    decoded = img.decodeImage(original);
  } catch (_) {
    // Tries every format it knows; a file none of them read can throw.
    return null;
  }
  if (decoded == null) return null;

  var upright = img.bakeOrientation(decoded);
  if (upright.width > maxSide || upright.height > maxSide) {
    upright = upright.width >= upright.height
        ? img.copyResize(upright, width: maxSide, interpolation: img.Interpolation.average)
        : img.copyResize(upright, height: maxSide, interpolation: img.Interpolation.average);
  }
  upright.exif = img.ExifData();

  return upright.hasAlpha
      ? (bytes: img.encodePng(upright), fileName: 'profile-photo.png')
      : (bytes: img.encodeJpg(upright, quality: 85), fileName: 'profile-photo.jpg');
}
