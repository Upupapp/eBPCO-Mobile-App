import 'package:flutter/material.dart';

/// Inbox filter. Guest hides [requests].
enum InboxChannel { requests, balita, events, advisories }

/// Kind line and icon disc on a G5 inbox tile.
class InboxTileStyle {
  final String label;
  final Color labelColor;
  final Color iconColor;
  final Color wash;
  final bool urgent;
  final bool muted;

  const InboxTileStyle({
    required this.label,
    required this.labelColor,
    required this.iconColor,
    required this.wash,
    this.urgent = false,
    this.muted = false,
  });
}
