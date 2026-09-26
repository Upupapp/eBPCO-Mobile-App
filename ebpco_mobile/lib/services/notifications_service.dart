import 'package:flutter/foundation.dart';

import '../core/api/citizen_api.dart';
import '../domain/models.dart';

/// The citizen's real notification feed (`GET /notifications`) — the record
/// of every status change. Push (`PushService`) only announces them; a
/// muted category or an unreachable phone still lands here.
class NotificationsService extends ChangeNotifier {
  final _api = CitizenApi.instance;

  bool _loading = false;
  String? _error;
  List<NotificationEntry> _items = [];

  bool get loading => _loading;
  String? get error => _error;
  List<NotificationEntry> get items => _items;

  /// Same definition as the citizen portal's badge (`readAt == null`). Not
  /// the API's `unresolvedCount`, which counts only action-required items.
  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _api.notifications();
      _items = result.data;
    } catch (e) {
      _error = 'Could not load your notifications. Pull down to try again.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

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
    _items = [];
    _error = null;
    notifyListeners();
  }
}
