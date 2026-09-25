import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One discarded payload, kept so the event is observable rather than silent.
///
/// Clearing a key is a **data loss event for that citizen** — whatever they had
/// saved under it is gone. It must never happen quietly, so every discard is
/// logged and recorded here.
@immutable
class DiscardedPayload {
  /// The service that could not read its own state, e.g. `RequestsService`.
  final String service;

  /// The exact preference keys that were removed — never a broader set.
  final List<String> keys;

  /// What the decode threw. Kept as `Object` because `jsonDecode`, a cast and a
  /// `fromJson` all fail differently.
  final Object error;

  const DiscardedPayload({required this.service, required this.keys, required this.error});

  @override
  String toString() => '$service discarded ${keys.join(', ')}: $error';
}

/// Recovery for a persisted payload this build can no longer decode.
///
/// The failure mode this exists for: every service kicks off `_restore()` from
/// its own constructor and nothing awaits that future, so a throw inside it is
/// unhandled — the load flag stays set, `notifyListeners()` never fires, and
/// `AuthGate` renders its spinner forever. Clearing app data was the only way
/// out. See `test/corrupt_persisted_state_recovery_test.dart`.
///
/// The realistic trigger is not corruption but **version skew**: a model or enum
/// that changed shape between builds. This app already ships five migrations for
/// exactly that, and every one of them runs *after* the decode that would throw.
class PersistenceRecovery {
  PersistenceRecovery._();

  /// Discards recorded this run, most recent last. Test-only: production code
  /// must not branch on this, or a diagnostic becomes a behaviour.
  @visibleForTesting
  static final List<DiscardedPayload> discards = <DiscardedPayload>[];

  @visibleForTesting
  static void resetForTest() => discards.clear();

  static const _maxRecordedDiscards = 20;

  /// Decodes a persisted collection **entry by entry**, keeping what is readable.
  ///
  /// [discardUnreadable] is all-or-nothing by design — it clears a whole key.
  /// For a collection that is a blunt instrument: one unreadable record costs a
  /// citizen every request they have ever filed. Their history is the part of
  /// this app they cannot reconstruct, so a decode failure should cost the
  /// record that failed and nothing else.
  ///
  /// A skip is reported through the same channel as a discard rather than
  /// silently shrinking the list — a restore that quietly loses half its
  /// records is its own defect. The caller keeps its `catch`: this handles a
  /// bad *entry*, while a payload that is not a collection at all still falls
  /// through to [discardUnreadable].
  ///
  /// Per-record failures remain reachable even though every persisted enum now
  /// carries an `orElse`: `ServiceRequest.fromJson` casts `statusHistory` and
  /// `attachments` with a bare `as List` and no default, unlike
  /// `flaggedRequirements` and `formFields`, so a record written before either
  /// field existed still throws.
  static List<T> decodeEach<T>(
    Iterable<dynamic> source,
    T Function(dynamic entry) decode, {
    required String what,
  }) {
    final decoded = <T>[];
    var skipped = 0;
    for (final entry in source) {
      try {
        decoded.add(decode(entry));
      } catch (error) {
        skipped++;
        developer.log('Skipping unreadable $what entry: $error', name: 'teresa_rizal.persistence', error: error);
      }
    }
    if (skipped > 0) {
      debugPrint('[teresa_rizal.persistence] skipped $skipped of ${skipped + decoded.length} $what entries');
    }
    return decoded;
  }

  /// [decodeEach] for a map payload keyed by id.
  static Map<String, V> decodeEntries<V>(
    Map<String, dynamic> source,
    V Function(dynamic value) decode, {
    required String what,
  }) {
    final decoded = <String, V>{};
    var skipped = 0;
    source.forEach((key, value) {
      try {
        decoded[key] = decode(value);
      } catch (error) {
        skipped++;
        developer.log('Skipping unreadable $what "$key": $error', name: 'teresa_rizal.persistence', error: error);
      }
    });
    if (skipped > 0) {
      debugPrint('[teresa_rizal.persistence] skipped $skipped of ${skipped + decoded.length} $what entries');
    }
    return decoded;
  }

  /// Logs the loss, then removes **only** [keys].
  ///
  /// Pass the narrowest set that can restore the boot — a service that cannot
  /// read one of its three keys should not destroy the other two. Never throws:
  /// it is called from a `catch`, and a failure here would resurrect the very
  /// hang it exists to prevent.
  static Future<void> discardUnreadable({
    required String service,
    required List<String> keys,
    required Object error,
  }) async {
    final record = DiscardedPayload(service: service, keys: keys, error: error);
    discards.add(record);
    // Bounded: a diagnostic must not become a leak if something re-fails.
    if (discards.length > _maxRecordedDiscards) discards.removeAt(0);

    // `developer.log` reaches the IDE and `flutter logs`; `debugPrint` reaches a
    // plain `adb logcat`, which is what is actually available when a citizen's
    // handset is the only reproduction.
    developer.log(
      'Discarding unreadable persisted state: $record',
      name: 'teresa_rizal.persistence',
      error: error,
    );
    debugPrint('[teresa_rizal.persistence] $record');

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (removalError) {
      // The fallback state the caller already applied still holds, so the app
      // boots either way; the next launch simply retakes this path.
      developer.log(
        'Could not clear ${keys.join(', ')} for $service',
        name: 'teresa_rizal.persistence',
        error: removalError,
      );
    }
  }
}
