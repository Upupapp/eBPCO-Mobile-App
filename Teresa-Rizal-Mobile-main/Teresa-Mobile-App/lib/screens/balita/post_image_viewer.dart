import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/announcement.dart';
import '../../services/balita_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/soft_widget.dart';
import 'post_card.dart';

/// Full-bleed media for one Balita post. Close returns to the feed.
/// Like, comment, and share stay on the card — this surface is the photo.
class PostImageViewer extends StatelessWidget {
  final String postId;
  const PostImageViewer({super.key, required this.postId});

  static void open(BuildContext context, String postId) {
    // Counted here — the one place a citizen actually opens a post, not
    // merely scrolls past it in the feed. See BalitaService.recordView's
    // own doc comment for why this has no per-session dedup.
    context.read<BalitaService>().recordView(postId);
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PostImageViewer(postId: postId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balita = context.watch<BalitaService>();
    Announcement? post;
    for (final p in balita.posts) {
      if (p.id == postId) {
        post = p;
        break;
      }
    }

    if (post == null || post.media == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold(backgroundColor: AppColors.navy950, body: SizedBox.shrink());
    }

    final top = MediaQuery.paddingOf(context).top;
    final media = post.media!;
    return Scaffold(
      backgroundColor: AppColors.navy950,
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  height: MediaQuery.sizeOf(context).width * 9 / 16,
                  // No cacheWidth here. The feed precaches the AssetImage;
                  // a second decode size leaves the viewer blank for the
                  // frame the still is captured on.
                  child: _viewerMedia(media),
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 8,
            left: 12,
            child: Tooltip(
              message: 'Close',
              child: Material(
                color: AppColors.navy600,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(Icons.close_rounded, size: 18, color: SoftColors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 14,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Text(
                '1/1',
                textAlign: TextAlign.center,
                style: SoftType.pageTitle.copyWith(color: SoftColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _viewerMedia(PostMedia media) {
  final bundledPhoto = media.isAsset &&
      media.type == PostMediaType.image &&
      media.path != balitaPhotoSlotPath;
  if (!bundledPhoto) return PostMediaView(media: media, fit: BoxFit.contain);
  return Image.asset(
    media.path,
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
  );
}
