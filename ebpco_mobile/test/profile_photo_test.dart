import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:ebpco_mobile/domain/profile_photo.dart';

/// A 40x20 camera-style JPEG that says "rotate 90° to display" (EXIF 6),
/// carrying a GPS position like a real phone photo.
Uint8List _sidewaysCameraJpeg() {
  final photo = img.Image(width: 40, height: 20);
  photo.exif.imageIfd.orientation = 6;
  photo.exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(12, 1);
  return img.encodeJpg(photo);
}

void main() {
  test('a camera photo is turned upright, since the server drops the orientation tag', () {
    final prepared = prepareProfilePhoto(_sidewaysCameraJpeg())!;
    final result = img.decodeImage(prepared.bytes)!;
    expect((result.width, result.height), (20, 40));
    expect(prepared.fileName, 'profile-photo.jpg');
  });

  test('no metadata leaves the phone', () {
    final result = img.decodeJpg(prepareProfilePhoto(_sidewaysCameraJpeg())!.bytes)!;
    expect(result.exif.imageIfd.hasOrientation, isFalse);
    expect(result.exif.gpsIfd.isEmpty, isTrue);
  });

  test('a large photo is scaled down to the longest side', () {
    final big = img.encodeJpg(img.Image(width: 3000, height: 1500));
    final result = img.decodeImage(prepareProfilePhoto(big)!.bytes)!;
    expect((result.width, result.height), (800, 400));
  });

  test('transparency stays PNG', () {
    final png = img.encodePng(img.Image(width: 10, height: 10, numChannels: 4));
    expect(prepareProfilePhoto(png)!.fileName, 'profile-photo.png');
  });

  test('bytes that are not an image are refused', () {
    expect(prepareProfilePhoto(Uint8List.fromList([1, 2, 3, 4])), isNull);
  });
}
