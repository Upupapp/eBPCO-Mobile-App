import 'package:flutter/material.dart';
import '../../models/announcement.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/soft_widget.dart';
import '../../utils/balita_post_actions.dart';
import '../../utils/cross_platform_image.dart';
import '../../widgets/app_card.dart';
import '../../widgets/balita_share_sheet.dart';
import '../../widgets/soft_chrome.dart';
import 'balita_post_detail_screen.dart';
import 'comments_sheet.dart';
import 'post_image_viewer.dart';

/// A single Balita feed post — header (avatar/author/verified badge/
/// barangay/timestamp/overflow menu), body text, optional image, an
/// engagement summary row, and a Like / Comment / Share action row. All
/// interactions are local-state simulations driven by the callbacks passed
/// in from BalitaScreen — there is no backend for the social feed.
///
/// Tapping the image opens [PostImageViewer] by `post.id` only (not a
/// snapshot of this [post]) so the viewer always reads the *live* post
/// straight from BalitaService — the same single source of truth this
/// card itself is built from — which is what keeps like/comment/share
/// state trivially synchronized between the feed and the viewer without
/// any manual prop-passing back and forth.
class PostCard extends StatelessWidget {
  final Announcement post;
  final VoidCallback onLike;
  final ValueChanged<PostComment> onComment;
  final VoidCallback onShare;

  const PostCard({super.key, required this.post, required this.onLike, required this.onComment, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        onTap: () => BalitaPostDetailScreen.open(context, post.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.media != null) ...[
              _PostMedia(post: post),
              const SizedBox(height: 12),
            ],
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: post.kind,
                    style: SoftType.sectionLink.copyWith(color: SoftColors.blue),
                  ),
                  TextSpan(
                    text: ' · ${post.time}',
                    style: SoftType.eyebrow.copyWith(color: SoftColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.displayTitle,
              style: SoftType.section.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: SoftColors.ink,
              ),
            ),
            if (post.displayBody.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(post.displayBody, style: SoftType.body.copyWith(height: 1.45)),
            ],
            const SizedBox(height: 2),
            BalitaEngagementRow(
              post: post,
              onLike: () => requireAccountForBalita(
                context,
                'Reacting to Balita posts',
                onLike,
              ),
              onComment: () => openBalitaComments(context, post, onComment),
              onShare: () => engageBalitaShare(
                context,
                () => BalitaShareSheet.show(context, post, onShare),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostMedia extends StatelessWidget {
  final Announcement post;
  const _PostMedia({required this.post});

  @override
  Widget build(BuildContext context) {
    final media = post.media!;
    final opensViewer = media.type == PostMediaType.image;
    final child = media.path == balitaPhotoSlotPath
        ? const DashedBannerSlot(
            label: 'Photo slot',
            caption: '16:9 · art pending',
          )
        : AspectRatio(
            aspectRatio: 16 / 9,
            child: PostMediaView(media: media),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(SoftRadius.md),
      child: opensViewer
          ? InkWell(
              key: ValueKey('balita-media-${post.id}'),
              onTap: () => PostImageViewer.open(context, post.id),
              child: child,
            )
          : child,
    );
  }
}

/// Opens the shared [CommentsSheet] bottom sheet — reused as-is by both
/// [PostCard] and [PostImageViewer] rather than either owning its own
/// comment UI, per the "do not create a separate comment system for the
/// viewer" requirement.
void openBalitaComments(BuildContext context, Announcement post, ValueChanged<PostComment> onSubmit) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentsSheet(post: post, onSubmit: onSubmit),
  );
}

/// Renders a post's attached [PostMedia] — a seed/bundled asset or a real
/// file the citizen picked, or a video attachment card (no video_player
/// dependency in this project, so a clear "this is a video" preview
/// stands in for actual playback, per the simulation scope for Balita).
/// Public (not `PostCard`-private) so [PostImageViewer] renders the exact
/// same image — including the same cross-platform-safe loading/error
/// handling — at a different [fit] rather than duplicating that logic.
class PostMediaView extends StatelessWidget {
  final PostMedia media;
  final BoxFit fit;
  const PostMediaView({super.key, required this.media, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (media.path == balitaPhotoSlotPath) {
      return const DashedBannerSlot(
        label: 'Photo slot',
        caption: '16:9 · art pending',
      );
    }
    if (media.type == PostMediaType.image) {
      // Some bundled seed images (e.g. the aerial/city-hall shots) are
      // several megapixels — far more than a feed card or the viewer ever
      // displays. LayoutBuilder reads the actual bounded width this
      // instance is being laid out at (feed card vs. the taller viewer
      // each pass a different constraint) so the decoder only produces a
      // bitmap sized for what's really on screen, in either context,
      // without hardcoding either one's size here.
      if (media.isAsset) {
        return LayoutBuilder(
          builder: (context, constraints) => Image.asset(
            media.path,
            fit: fit,
            width: double.infinity,
            cacheWidth: constraints.hasBoundedWidth
                ? (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context)).round()
                : null,
          ),
        );
      }
      // A citizen-picked photo's `path` is only ever safe to read via
      // dart:io on native platforms — see cross_platform_image.dart. No
      // current flow constructs a non-asset PostMedia, but this guards the
      // same crash the attachment picker had if/when post composing ships.
      final provider = pickedFileImageProvider(path: media.path);
      if (provider == null) {
        return Container(
          color: AppColors.slate100,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.slate400, size: 28),
        );
      }
      return Image(
        image: provider,
        fit: fit,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.slate100,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined, color: AppColors.slate400, size: 28),
        ),
      );
    }
    return Container(
      color: AppColors.navy900,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Text(
              media.fileName ?? 'Video attached',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Like, comment, and share controls under a Balita card. The filled heart
/// uses [SoftColors.danger] (`#e5484d`). View count stays internal.
class BalitaEngagementRow extends StatelessWidget {
  final Announcement post;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const BalitaEngagementRow({
    super.key,
    required this.post,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final liked = post.liked;
    return Row(
      children: [
        _MetricButton(
          tooltip: 'Like',
          icon: liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: liked ? SoftColors.danger : SoftColors.muted,
          label: '${post.likes}',
          labelColor: SoftColors.ink,
          onTap: onLike,
        ),
        const SizedBox(width: 16),
        _MetricButton(
          tooltip: 'Comment',
          icon: Icons.chat_bubble_outline_rounded,
          iconColor: SoftColors.muted,
          label: '${post.commentCount}',
          labelColor: SoftColors.muted,
          onTap: onComment,
        ),
        const SizedBox(width: 16),
        _MetricButton(
          tooltip: 'Share',
          icon: Icons.share_outlined,
          iconColor: SoftColors.muted,
          label: 'Share',
          labelColor: SoftColors.muted,
          onTap: onShare,
        ),
      ],
    );
  }
}

class _MetricButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  const _MetricButton({
    required this.tooltip,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: SoftType.cellValue.copyWith(color: labelColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
