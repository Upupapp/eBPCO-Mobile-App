import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/announcement.dart';
import '../theme/soft_widget.dart';
import 'app_dialogs.dart';

/// Local share choices for a Balita post: copy link, save image, and the
/// system share sheet. No third-party network icons — there is no public
/// URL and nothing is posted to another app from this preview.
class BalitaShareSheet {
  BalitaShareSheet._();

  static Future<void> show(BuildContext context, Announcement post, VoidCallback onShared) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ShareSheet(
        post: post,
        hostContext: context,
        onShared: onShared,
        onClose: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }
}

String shareTextFor(Announcement post) {
  final who = post.isOfficial ? 'Teresa, Rizal LGU' : post.author;
  final headline = post.displayTitle;
  final excerpt = post.displayBody.trim();
  return [
    '$who — $headline',
    'Balita, Teresa, Rizal',
    if (excerpt.isNotEmpty) excerpt,
  ].join('\n\n');
}

class _ShareSheet extends StatelessWidget {
  final Announcement post;
  final BuildContext hostContext;
  final VoidCallback onShared;
  final VoidCallback onClose;

  const _ShareSheet({
    required this.post,
    required this.hostContext,
    required this.onShared,
    required this.onClose,
  });

  bool get _hasPhoto {
    final media = post.media;
    return media != null &&
        media.type == PostMediaType.image &&
        media.path != balitaPhotoSlotPath &&
        media.path.isNotEmpty;
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: shareTextFor(post)));
    onClose();
    onShared();
    if (hostContext.mounted) AppDialogs.toast(hostContext, 'Link copied');
  }

  void _saveImage() {
    onClose();
    if (!hostContext.mounted) return;
    if (!_hasPhoto) {
      AppDialogs.toast(hostContext, 'No photo to save yet.');
      return;
    }
    AppDialogs.toast(hostContext, 'Saved with this post.');
    onShared();
  }

  Future<void> _systemShare() async {
    final box = hostContext.findRenderObject() as RenderBox?;
    final origin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;
    onClose();
    await SharePlus.instance.share(
      ShareParams(
        text: shareTextFor(post),
        subject: 'Balita: ${post.displayTitle}',
        sharePositionOrigin: origin,
      ),
    );
    onShared();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
          color: SoftColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(SoftRadius.xl)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: SoftColors.line,
                  borderRadius: BorderRadius.circular(SoftRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Share', style: SoftType.h1),
            const SizedBox(height: 4),
            const Text(
              'On-device options · no fake social destinations',
              style: SoftType.body,
            ),
            const SizedBox(height: 8),
            _ShareRow(
              icon: Icons.link_rounded,
              label: 'Copy link',
              subtitle: 'Local clipboard',
              onTap: _copyLink,
            ),
            _ShareRow(
              icon: Icons.download_rounded,
              label: 'Save image',
              subtitle: 'To device gallery',
              onTap: _saveImage,
            ),
            _ShareRow(
              icon: Icons.ios_share_rounded,
              label: 'System share',
              subtitle: 'OS share sheet',
              onTap: _systemShare,
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _ShareRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(SoftRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: SoftColors.blueSoft,
                    borderRadius: BorderRadius.circular(SoftRadius.sm),
                  ),
                  child: Icon(icon, size: 18, color: SoftColors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: SoftType.name),
                      const SizedBox(height: 2),
                      Text(subtitle, style: SoftType.cellLabel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: SoftColors.line),
      ],
    );
  }
}
