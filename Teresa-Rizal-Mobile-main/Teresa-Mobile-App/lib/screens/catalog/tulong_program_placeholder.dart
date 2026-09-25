import 'package:flutter/material.dart';

import '../../theme/soft_widget.dart';
import '../../widgets/soft_chrome.dart';

/// TODO(PR-E): g5-tulong-program replaces this screen.
class TulongProgramPlaceholder extends StatelessWidget {
  const TulongProgramPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoftColors.page,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: SoftCircleButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text('Educational Assistance', style: SoftType.h1),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Frontend preview. This landing is a stand-in until the program screen is provided.',
                style: CatalogType.honesty,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// TODO(Pack J): My reports list and report detail replace this screen.
class MyReportsPlaceholder extends StatelessWidget {
  const MyReportsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SoftColors.page,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: SoftCircleButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text('My reports', style: SoftType.h1),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                'Saved on this device. The reports list is not in this preview.',
                style: CatalogType.honesty,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
