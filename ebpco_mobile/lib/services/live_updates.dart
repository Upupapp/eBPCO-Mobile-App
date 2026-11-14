import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';

/// What `GET /me/changes` keeps a stamp for.
enum LiveTopic { applications, payments, notifications, account }

/// One `GET /me/changes` answer: the overall stamp, and one per topic (null
/// when the answer had no `t`).
typedef LiveChanges = ({String version, Map<LiveTopic, String?>? stamps});

/// `{ "v": "…", "t": { "applications": "…", "payments": "…",
/// "notifications": "…", "account": "…" } }`, bare or in a `{ "data": … }`
/// envelope. Null for anything else (a failed check answers null).
LiveChanges? parseLiveChanges(Object? body) {
  var json = body;
  if (json is Map && !json.containsKey('v') && json['data'] is Map) json = json['data'];
  if (json is! Map) return null;
  final version = json['v'];
  if (version == null || version is Map || version is List) return null;
  final stamps = json['t'];
  return (
    version: '$version',
    stamps: stamps is Map ? {for (final topic in LiveTopic.values) topic: stamps[topic.name]?.toString()} : null,
  );
}

/// Keeps the open app current without pull-to-refresh, on iOS (which gets no
/// push) as on Android: while the app is in the foreground and a citizen is
/// signed in, asks `GET /me/changes` about once a second — never two at once
/// — and tells its listeners which topics moved since the last answer
/// ([changed]). An equal `v` means nothing changed.
///
/// The first answer after sign-in is only the baseline (the screens have just
/// loaded). Pausing keeps it, so coming back to the app reports whatever
/// changed while it was away; signing out forgets it ([reset]).
///
/// A failed check — no signal, a timeout, a 5xx, a 401 — is ignored: it never
/// signs the citizen out ([ApiClient.quietGet]) and the checks go on, spaced
/// out up to [maxInterval] while they keep failing.
///
/// Listeners read [changed] when called. The root shell starts and stops the
/// checks with the app's lifecycle and refreshes what is on screen.
class LiveUpdates extends ChangeNotifier {
  LiveUpdates({
    Future<Object?> Function()? check,
    bool Function()? canCheck,
    this.interval = const Duration(seconds: 1),
    this.maxInterval = const Duration(seconds: 8),
  })  : _check = check ?? (() => ApiClient.instance.quietGet('/me/changes')),
        _canCheck = canCheck ?? (() => true);

  final Future<Object?> Function() _check;

  /// Whether a citizen is signed in; no check goes out while not.
  final bool Function() _canCheck;

  final Duration interval;
  final Duration maxInterval;

  bool _running = false;
  bool _inFlight = false;
  Timer? _timer;
  int _failures = 0;

  /// Bumped by [stop], so an answer still out when the app was backgrounded
  /// or the citizen signed out is dropped.
  int _epoch = 0;

  String? _version;
  Map<LiveTopic, String?>? _stamps;
  Set<LiveTopic> _changed = const {};

  /// The topics the latest notification is about.
  Set<LiveTopic> get changed => _changed;

  bool get running => _running;

  /// In the foreground and signed in: check now, then about every [interval].
  void start() {
    if (_running) return;
    _running = true;
    _failures = 0;
    unawaited(_tick());
  }

  /// Backgrounded, or the signed-in shell is gone: no more checks, and an
  /// answer still out is dropped.
  void stop() {
    _running = false;
    _epoch++;
    _timer?.cancel();
    _timer = null;
  }

  /// Signed out: stops, and forgets the last answer, so the next citizen's
  /// first answer is a baseline rather than a change.
  void reset() {
    stop();
    _version = null;
    _stamps = null;
    _changed = const {};
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }

  void _schedule(Duration delay) {
    _timer?.cancel();
    _timer = _running ? Timer(delay, () => unawaited(_tick())) : null;
  }

  Future<void> _tick() async {
    _timer = null;
    if (!_running || _inFlight) return;
    if (!_canCheck()) {
      _schedule(interval);
      return;
    }
    _inFlight = true;
    final epoch = _epoch;
    Object? body;
    try {
      body = await _check();
    } catch (_) {
      body = null;
    } finally {
      _inFlight = false;
    }
    if (epoch != _epoch) {
      // Stopped while this was out. Started again meanwhile: that start could
      // not check while this one was out, so check now.
      if (_running) _schedule(Duration.zero);
      return;
    }
    final answer = parseLiveChanges(body);
    if (answer == null) {
      _failures++;
      _schedule(_backoff());
      return;
    }
    _failures = 0;
    _take(answer);
    _schedule(interval);
  }

  /// 1 s, 2 s, 4 s, then [maxInterval] while checks keep failing.
  Duration _backoff() {
    final spaced = interval * (1 << math.min(_failures - 1, 3));
    return spaced > maxInterval ? maxInterval : spaced;
  }

  void _take(LiveChanges answer) {
    final before = _version;
    final stampsBefore = _stamps;
    _version = answer.version;
    _stamps = answer.stamps;
    if (before == null || before == answer.version) return;
    final stamps = answer.stamps;
    // Without stamps to compare, any topic may have moved.
    final changed = stamps == null || stampsBefore == null
        ? LiveTopic.values.toSet()
        : {for (final topic in LiveTopic.values) if (stamps[topic] != stampsBefore[topic]) topic};
    if (changed.isEmpty) return;
    _changed = Set.unmodifiable(changed);
    notifyListeners();
  }
}

/// One background re-read at a time, for the lists live updates refresh: a
/// call while one is out is answered by one more read after it (however many
/// calls came in meanwhile), never by a second read alongside. So the screens
/// reacting to one change read once between them, and a change seen while a
/// read was out is still read.
class SerialRefresh {
  SerialRefresh(this._read);

  final Future<void> Function() _read;
  Future<void>? _running;
  bool _again = false;

  Future<void> call() {
    _again = true;
    return _running ??= _drain();
  }

  Future<void> _drain() async {
    try {
      while (_again) {
        // Every listener of one change asks in the same turn: they share this read.
        await Future<void>.value();
        _again = false;
        try {
          await _read();
        } catch (_) {
          // A background read that fails keeps what is on screen.
        }
      }
    } finally {
      _running = null;
    }
  }
}
