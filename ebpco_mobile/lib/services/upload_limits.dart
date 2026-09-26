import 'package:flutter/foundation.dart';

import '../core/api/citizen_api.dart';
import '../domain/upload_file.dart';

/// How large a file the server takes — `GET /limits`, the same source the
/// portal's `UploadLimitsService` reads, so a limit raised on the server
/// reaches the app without a new release. Starts at the portal's own fallback
/// until the first answer arrives.
class UploadLimits {
  UploadLimits._();
  static final UploadLimits instance = UploadLimits._();

  int _maxFileBytes = 750000;
  bool _loaded = false;

  int get maxFileBytes => _maxFileBytes;

  /// The limit, asking the server the first time. A failed ask keeps the
  /// fallback and tries again next time.
  Future<int> current() async {
    if (_loaded) return _maxFileBytes;
    try {
      final upload = (await CitizenApi.instance.limits())['upload'] as Map<String, dynamic>?;
      final max = upload?['maxFileBytes'];
      if (max is int && max > 0) {
        _maxFileBytes = max;
        _loaded = true;
      }
    } catch (_) {
      // Offline or unreachable: the upload itself will say so.
    }
    return _maxFileBytes;
  }
}

/// A picked file made ready to send (`prepareUpload`), off the UI thread —
/// shrinking a camera photo takes a second or two. Throws [UploadRefused].
Future<ReadyUpload> readyForUpload(String fileName, Uint8List bytes) async {
  final maxFileBytes = await UploadLimits.instance.current();
  return compute(prepareUpload, (fileName: fileName, bytes: bytes, maxFileBytes: maxFileBytes));
}
