// Headless capture of the three welcome pages at 390×844 with the real Inter
// face. `flutter test` forces the Ahem test font, which draws skeleton boxes,
// so this entrypoint is run on flutter_tester with asset fonts left on:
//
//   flutter_tester --disable-vm-service --enable-software-rendering \
//     --non-interactive --run-forever \
//     --flutter-assets-dir=build/unit_test_assets welcome_shot.dill
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:teresa_rizal/screens/onboarding/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  stdout.writeln('SHOT START');
  await stdout.flush();
  runApp(const _ShotApp());
}

class _ShotApp extends StatefulWidget {
  const _ShotApp();

  @override
  State<_ShotApp> createState() => _ShotAppState();
}

class _ShotAppState extends State<_ShotApp> {
  final _boundaryKey = GlobalKey();
  var _page = 0;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureAll());
  }

  Future<void> _captureAll() async {
    if (_busy) return;
    _busy = true;
    try {
      const outDir = '/opt/cursor/artifacts/welcome-review';
      await Directory(outDir).create(recursive: true);
      for (var page = 0; page < 3; page++) {
        setState(() => _page = page);
        await _nextFrame();
        await _nextFrame();
        await Future<void>.delayed(const Duration(milliseconds: 500));
        final boundary =
            _boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$outDir/welcome_page_${page + 1}.png');
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        stdout.writeln('WROTE ${file.path} ${image.width}x${image.height}');
        await stdout.flush();
      }
      exit(0);
    } catch (error, stack) {
      stdout.writeln('SHOT FAIL $error\n$stack');
      await stdout.flush();
      exit(1);
    }
  }

  Future<void> _nextFrame() {
    final done = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) => done.complete());
    WidgetsBinding.instance.scheduleFrame();
    return done.future;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: const Color(0xFF101010),
        child: FittedBox(
          child: SizedBox(
            width: 390,
            height: 844,
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                devicePixelRatio: 1,
              ),
              child: RepaintBoundary(
                key: _boundaryKey,
                child: OnboardingScreen(
                  key: ValueKey(_page),
                  initialPage: _page,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
