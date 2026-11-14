import 'dart:async';
import 'dart:convert';

import 'package:ebpco_mobile/core/api/api_client.dart';
import 'package:ebpco_mobile/core/api/token_store.dart';
import 'package:ebpco_mobile/services/live_updates.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// `GET /me/changes` as the server answers it.
Map<String, Object?> _answer(String v, {String a = 'a1', String p = 'p1', String n = 'n1', String u = 'u1'}) => {
      'v': v,
      't': {'applications': a, 'payments': p, 'notifications': n, 'account': u},
    };

/// The check LiveUpdates makes, answered by the test: [next] (an
/// [Exception] is thrown), or held open on [hold] while it is set.
class _Server {
  Object? next;
  Completer<Object?>? hold;
  int calls = 0;

  Future<Object?> check() async {
    calls++;
    final held = hold;
    if (held != null) return held.future;
    final answer = next;
    if (answer is Exception) throw answer;
    return answer;
  }
}

void main() {
  group('LiveUpdates', () {
    late _Server server;
    late LiveUpdates live;
    late List<Set<LiveTopic>> heard;

    void setUpLive({bool Function()? canCheck}) {
      server = _Server()..next = _answer('1');
      live = LiveUpdates(check: server.check, canCheck: canCheck);
      heard = [];
      live.addListener(() => heard.add(live.changed));
    }

    testWidgets('the first answer is the baseline, and an equal v notifies nothing', (tester) async {
      setUpLive();
      live.start();
      await tester.pump();
      expect(server.calls, 1);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(server.calls, 3);
      expect(heard, isEmpty);
      live.dispose();
    });

    testWidgets('a changed topic notifies with the topics that moved', (tester) async {
      setUpLive();
      live.start();
      await tester.pump();
      server.next = _answer('2', p: 'p2');
      await tester.pump(const Duration(seconds: 1));
      server.next = _answer('3', p: 'p2', a: 'a2', n: 'n2');
      await tester.pump(const Duration(seconds: 1));
      expect(heard, [
        {LiveTopic.payments},
        {LiveTopic.applications, LiveTopic.notifications},
      ]);
      live.dispose();
    });

    testWidgets('an answer in a { data } envelope reads the same; one without stamps moves every topic', (tester) async {
      setUpLive();
      server.next = {'data': _answer('1')};
      live.start();
      await tester.pump();
      server.next = {'data': _answer('2', u: 'u2')};
      await tester.pump(const Duration(seconds: 1));
      server.next = {'v': '3'};
      await tester.pump(const Duration(seconds: 1));
      expect(heard, [
        {LiveTopic.account},
        LiveTopic.values.toSet(),
      ]);
      live.dispose();
    });

    testWidgets('failed checks are ignored and the checks go on', (tester) async {
      setUpLive();
      live.start();
      await tester.pump();
      server.next = null; // what quietGet answers for a 401, a 5xx or no signal
      await tester.pump(const Duration(seconds: 1));
      server.next = Exception('no signal');
      await tester.pump(const Duration(seconds: 1));
      final failedSoFar = server.calls;
      server.next = _answer('2', n: 'n2');
      for (var second = 0; second < 10 && heard.isEmpty; second++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(failedSoFar, 3);
      expect(heard, [
        {LiveTopic.notifications},
      ]);
      live.dispose();
    });

    testWidgets('paused, nothing is sent; resumed, it checks at once and reports what changed meanwhile', (tester) async {
      setUpLive();
      live.start();
      await tester.pump();
      live.stop();
      server.next = _answer('2', a: 'a2');
      await tester.pump(const Duration(seconds: 30));
      expect(server.calls, 1);
      live.start();
      await tester.pump();
      expect(server.calls, 2);
      expect(heard, [
        {LiveTopic.applications},
      ]);
      live.dispose();
    });

    testWidgets('one check out at a time; an answer from before a pause is dropped', (tester) async {
      setUpLive();
      live.start();
      await tester.pump();
      final held = server.hold = Completer<Object?>();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 5));
      expect(server.calls, 2);
      // Backgrounded and back while that check is still out: no second one.
      live
        ..stop()
        ..start();
      await tester.pump();
      expect(server.calls, 2);
      server.hold = null;
      server.next = _answer('2', p: 'p2');
      held.complete(_answer('9', a: 'a9'));
      await tester.pump(Duration.zero);
      expect(server.calls, 3);
      expect(heard, [
        {LiveTopic.payments},
      ]);
      live.dispose();
    });

    testWidgets('signed out: nothing is sent, and the next citizen starts from a new baseline', (tester) async {
      var signedIn = false;
      setUpLive(canCheck: () => signedIn);
      live.start();
      await tester.pump(const Duration(seconds: 3));
      expect(server.calls, 0);
      signedIn = true;
      await tester.pump(const Duration(seconds: 1));
      expect(server.calls, 1);
      live.reset();
      server.next = _answer('7', a: 'a7', n: 'n7');
      live.start();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(server.calls, 3);
      expect(heard, isEmpty);
      live.dispose();
    });
  });

  group('the check through ApiClient (fake HTTP client)', () {
    late List<String> sent;
    late int signedOut;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      await TokenStore.instance.clear();
      sent = [];
      signedOut = 0;
      ApiClient.instance.onSessionExpired = () => signedOut++;
    });

    tearDown(() => ApiClient.instance.onSessionExpired = null);

    void serve(http.Response Function(http.Request request) answer) {
      ApiClient.instance.httpClient = MockClient((request) async {
        sent.add('${request.method} ${request.url.path} ${request.headers['Authorization'] ?? ''}'.trim());
        return answer(request);
      });
    }

    testWidgets('a 401, a 5xx or no signal never signs out, and the checks go on', (tester) async {
      await TokenStore.instance.save(accessToken: 'token-1', refreshToken: 'refresh-1', expiresInSeconds: 900);
      var calls = 0;
      serve((request) {
        calls++;
        return switch (calls) {
          1 => http.Response(jsonEncode(_answer('1')), 200),
          2 => http.Response('{"status":401}', 401),
          3 => throw http.ClientException('no signal'),
          4 => http.Response('', 503),
          _ => http.Response(jsonEncode({'data': _answer('2', a: 'a2')}), 200),
        };
      });
      final live = LiveUpdates();
      final heard = <Set<LiveTopic>>[];
      live.addListener(() => heard.add(live.changed));
      live.start();
      for (var second = 0; second < 20 && heard.isEmpty; second++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(signedOut, 0);
      expect(heard, [
        {LiveTopic.applications},
      ]);
      expect(sent.toSet(), {'GET /me/changes Bearer token-1'});
      expect(calls, 5);
      live.dispose();
    });

    test('the check sends the token kept in memory, and nothing once signed out', () async {
      await TokenStore.instance.save(accessToken: 'token-1', expiresInSeconds: 900);
      // The keychain no longer holds it: the check does not read it from there.
      FlutterSecureStorage.setMockInitialValues({});
      serve((_) => http.Response(jsonEncode(_answer('1')), 200));
      expect(parseLiveChanges(await ApiClient.instance.quietGet('/me/changes'))?.version, '1');
      await TokenStore.instance.clear();
      expect(await ApiClient.instance.quietGet('/me/changes'), isNull);
      expect(sent, ['GET /me/changes Bearer token-1']);
    });

    test('while the token is about to expire, the usual refresh runs first', () async {
      await TokenStore.instance.save(accessToken: 'old', refreshToken: 'refresh-1', expiresInSeconds: 10);
      serve((request) => request.url.path == '/auth/token/refresh'
          ? http.Response(jsonEncode({'accessToken': 'new', 'refreshToken': 'refresh-2', 'expiresIn': 900}), 200)
          : http.Response(jsonEncode(_answer('1')), 200));
      expect(await ApiClient.instance.quietGet('/me/changes'), isNotNull);
      expect(sent, ['POST /auth/token/refresh', 'GET /me/changes Bearer new']);
      expect(await TokenStore.instance.accessToken(), 'new');
      expect(signedOut, 0);
    });
  });

  test('SerialRefresh: one read for the callers of one change, one more for a call while it is out', () async {
    final out = <Completer<void>>[];
    final refresh = SerialRefresh(() {
      final read = Completer<void>();
      out.add(read);
      return read.future;
    });
    final first = refresh();
    final second = refresh();
    await Future<void>.delayed(Duration.zero);
    expect(out, hasLength(1));
    final third = refresh();
    refresh();
    out.single.complete();
    await Future<void>.delayed(Duration.zero);
    expect(out, hasLength(2));
    out.last.complete();
    await Future.wait([first, second, third]);
    expect(out, hasLength(2));
  });
}
