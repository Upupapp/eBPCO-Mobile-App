import 'package:ebpco_mobile/widgets/message_bar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a short message keeps the usual 4 seconds', () {
    expect(readingTime('Sent to the Municipality.'), const Duration(seconds: 4));
  });

  test('a two-sentence guidance message stays long enough to read', () {
    const reuse = 'You already had "BFP-FSEC.pdf" in My Documents, so that copy was used. '
        'Next time, choose it from your documents instead of the device.';
    expect(readingTime(reuse).inMilliseconds, greaterThanOrEqualTo(6000));
  });

  test('no message stays longer than 12 seconds', () {
    expect(readingTime('word ' * 200), const Duration(seconds: 12));
  });
}
