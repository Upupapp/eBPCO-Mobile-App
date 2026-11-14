import 'package:flutter/foundation.dart';

import '../core/api/citizen_api.dart';
import '../domain/models.dart';
import 'live_updates.dart';

/// The citizen's real notification feed (`GET /notifications`) — the record
/// of every status change. Push (`PushService`) only announces them; a
/// muted category or an unreachable phone still lands here.
class NotificationsService extends ChangeNotifier {
  final _api = CitizenApi.instance;

  bool _loading = false;
  String? _error;
  List<NotificationEntry> _items = [];

  /// Numbers each read, so an answer landing after a newer one (or after
  /// [clear], at sign-out) is dropped instead of shown.
  int _reads = 0;
  int _shownRead = 0;

  bool get loading => _loading;
  String? get error => _error;
  List<NotificationEntry> get items => _items;

  /// Same definition as the citizen portal's badge (`readAt == null`). Not
  /// the API's `unresolvedCount`, which counts only action-required items.
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> refresh() async {
    final read = ++_reads;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.notifications();
      if (read > _shownRead) {
        _shownRead = read;
        _items = result.data;
      }
    } catch (e) {
      if (read > _shownRead) _error = 'Could not load your notifications. Pull down to try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  late final _quietly = SerialRefresh(() async {
    final read = ++_reads;
    final result = await _api.notifications();
    if (read <= _shownRead) return;
    _shownRead = read;
    _items = result.data;
    _error = null;
    notifyListeners();
  });

  /// Reads the feed (and so the badge) again in the background (live
  /// updates): no spinner, and a failed read keeps what is on screen.
  Future<void> refreshQuietly() => _quietly();

  Future<void> markRead(String id) async {
    await _api.markNotificationRead(id);
    await refresh();
  }

  /// The portal's `markAllReadReal`: one request per unread item, each allowed
  /// to fail on its own, then a single refresh.
  Future<void> markAllRead() async {
    final unread = _items.where((n) => !n.isRead).toList();
    await Future.wait(unread.map((n) => _api.markNotificationRead(n.id).catchError((_) {})));
    await refresh();
  }

  void clear() {
    _shownRead = ++_reads;
    _items = [];
    _error = null;
    notifyListeners();
  }
}
