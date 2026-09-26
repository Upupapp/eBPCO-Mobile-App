import 'package:flutter_test/flutter_test.dart';

import 'package:ebpco_mobile/services/push_service.dart';

void main() {
  test('reads both ids the server puts in the push data', () {
    final notice = TappedNotice.fromData({'notificationId': 'n1', 'type': 'application-submitted', 'applicationId': 'a1'});
    expect(notice?.notificationId, 'n1');
    expect(notice?.applicationId, 'a1');
  });

  test('a notice about the account, not an application, still opens', () {
    final notice = TappedNotice.fromData({'notificationId': 'n1', 'applicationId': ''});
    expect(notice?.notificationId, 'n1');
    expect(notice?.applicationId, isNull);
  });

  test('data with neither id is not ours', () {
    expect(TappedNotice.fromData({'type': 'x'}), isNull);
    expect(TappedNotice.fromData({}), isNull);
  });
}
