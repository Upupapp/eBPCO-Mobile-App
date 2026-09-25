import 'package:flutter/material.dart';

import '../theme/soft_widget.dart';

/// Says what the Digital ID in this app is. The wallet art is a local
/// demonstration. It is not an issued government identification.
class DigitalIdHonestyPanel extends StatelessWidget {
  final VoidCallback? onOpenDemonstration;

  const DigitalIdHonestyPanel({super.key, this.onOpenDemonstration});

  static const message =
      'A demonstration stored on this device. It is not an official '
      'government ID, and it is not connected to PhilSys, PhilHealth, or '
      'a Teresa, Rizal registry.';

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('digital-id-honesty'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: SoftColors.blueWash,
        borderRadius: BorderRadius.circular(SoftRadius.md),
        border: Border.all(color: SoftColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _HonestyTile(),
              SizedBox(width: 12),
              Expanded(child: Text('Digital ID', style: SoftType.name)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(message, style: SoftType.body),
          if (onOpenDemonstration != null) ...[
            const SizedBox(height: 4),
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: SoftColors.blue,
              ),
              onPressed: onOpenDemonstration,
              child: const Text(
                'View demonstration',
                style: SoftType.sectionLink,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HonestyTile extends StatelessWidget {
  const _HonestyTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SoftColors.blueSoft,
        borderRadius: BorderRadius.circular(SoftRadius.sm),
      ),
      child: const Icon(Icons.badge_outlined, size: 18, color: SoftColors.blue),
    );
  }
}
