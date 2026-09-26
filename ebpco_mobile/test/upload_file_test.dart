import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:ebpco_mobile/domain/upload_file.dart';

Uint8List _pdf(int size) => Uint8List.fromList([
      ...'%PDF-1.4\n'.codeUnits,
      ...List.filled(size, 0x41),
      ...'\n%%EOF\n'.codeUnits,
    ]);

/// A photo that compresses badly, like a real one does.
img.Image _busyPhoto(int width, int height) {
  final random = math.Random(7);
  final photo = img.Image(width: width, height: height);
  for (final pixel in photo) {
    pixel
      ..r = random.nextInt(256)
      ..g = (pixel.x * 255) ~/ width
      ..b = (pixel.y * 255) ~/ height;
  }
  return photo;
}

ReadyUpload _prepare(String name, Uint8List bytes, int maxFileBytes) =>
    prepareUpload((fileName: name, bytes: bytes, maxFileBytes: maxFileBytes));

void main() {
  test('a PDF that fits is sent exactly as it is', () {
    final pdf = _pdf(1000);
    final ready = _prepare('plan.pdf', pdf, 750000);
    expect(ready.bytes, same(pdf));
    expect(ready.fileName, 'plan.pdf');
  });

  test('a PDF over the limit is refused with both sizes, before anything is sent', () {
    expect(
      () => _prepare('plan.pdf', _pdf(2 * 1024 * 1024), 750000),
      throwsA(isA<UploadRefused>().having((e) => e.message, 'message', allOf(contains('2.0 MB'), contains('732 KB')))),
    );
  });

  test('something that is not a PDF, JPG or PNG is refused by its bytes, whatever its name', () {
    expect(() => _prepare('plan.pdf', Uint8List.fromList('PK\x03\x04 a zip'.codeUnits), 750000), throwsA(isA<UploadRefused>()));
  });

  test('a sideways camera photo is turned upright, since the server drops the orientation tag', () {
    // Small enough to go untouched, which is exactly the case that slipped:
    // the decoder applies the tag and drops it, so only the file shows it.
    final photo = img.Image(width: 400, height: 200)..exif.imageIfd.orientation = 6;
    photo.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(12, 1);
    final original = img.encodeJpg(photo);
    final ready = _prepare('IMG_0001.jpg', original, 750000);

    expect(ready.bytes, isNot(same(original)));
    // The pixels themselves are upright, with no tag left to (mis)read.
    final raw = img.decodeJpgExif(ready.bytes);
    expect(raw?.imageIfd.hasOrientation ?? false, isFalse);
    expect(raw?.gpsIfd.isEmpty ?? true, isTrue);
    final result = img.decodeJpg(ready.bytes)!;
    expect((result.width, result.height), (200, 400));
  });

  test('a photo over the limit is shrunk until it fits', () {
    final original = img.encodeJpg(_busyPhoto(3600, 2400), quality: 95);
    const limit = 400000;
    expect(original.length, greaterThan(limit), reason: 'the test needs a photo that does not fit as it is');

    final ready = _prepare('IMG_0002.jpeg', original, limit);
    final result = img.decodeJpg(ready.bytes)!;
    expect(ready.bytes.length, lessThanOrEqualTo(limit));
    expect(math.max(result.width, result.height), lessThanOrEqualTo(3200));
    expect(ready.fileName, 'IMG_0002.jpeg');
  });

  test('a screenshot with transparency becomes a JPEG on white, not black', () {
    final shot = img.Image(width: 600, height: 600, numChannels: 4);
    final random = math.Random(3);
    for (final pixel in shot) {
      // Left half see-through; right half noise, so it does not fit as it is.
      if (pixel.x < 300) {
        pixel.a = 0;
      } else {
        pixel
          ..r = random.nextInt(256)
          ..g = random.nextInt(256)
          ..b = random.nextInt(256)
          ..a = 255;
      }
    }
    final png = img.encodePng(shot);
    final ready = _prepare('screenshot.png', png, png.length ~/ 2);

    expect(ready.fileName, 'screenshot.jpg');
    final corner = img.decodeJpg(ready.bytes)!.getPixel(10, 10);
    expect([corner.r, corner.g, corner.b].every((c) => c > 240), isTrue);
  });

  test('a PNG saved with a .jpg name is renamed, which the server would otherwise refuse', () {
    final png = img.encodePng(img.Image(width: 20, height: 20));
    final ready = _prepare('scan.jpg', png, 750000);
    expect(ready.fileName, 'scan.png');
    expect(ready.bytes, same(png));
  });

  test('an upright photo that fits is not touched', () {
    final jpeg = img.encodeJpg(img.Image(width: 300, height: 200));
    expect(_prepare('id.jpg', jpeg, 750000).bytes, same(jpeg));
  });

  test('sizes read the way the server states its own limit', () {
    expect(describeSize(750000), '732 KB');
    expect(describeSize(3565158), '3.4 MB');
    expect(describeSize(20 * 1024 * 1024), '20 MB');
  });
}
