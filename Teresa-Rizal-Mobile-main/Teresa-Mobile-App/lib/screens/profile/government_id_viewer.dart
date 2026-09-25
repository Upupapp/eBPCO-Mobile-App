import 'package:flutter/material.dart';
import '../../models/government_id_record.dart';

/// Full-screen, pinch-to-zoomable view of a seeded government ID document —
/// same pattern as EventPosterViewer, built on Flutter's own
/// InteractiveViewer rather than a new dependency.
class GovernmentIdViewer extends StatelessWidget {
  final GovernmentIdRecord record;
  const GovernmentIdViewer({super.key, required this.record});

  static void open(BuildContext context, GovernmentIdRecord record) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => GovernmentIdViewer(record: record), fullscreenDialog: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        title: Text(record.idType),
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 1,
            maxScale: 4,
            child: Image.asset(record.assetPath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
