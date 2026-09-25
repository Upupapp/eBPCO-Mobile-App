import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/access_level.dart';
import '../../models/announcement.dart';
import '../../services/balita_service.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/app_typography.dart';
import '../../theme/soft_widget.dart';
import '../../utils/balita_post_actions.dart';
import '../../widgets/balita_share_sheet.dart';
import '../../widgets/soft_chrome.dart';
import '../auth/register_screen.dart';
import '../shared/detail_chrome.dart';
import 'comments_sheet.dart';

/// Pack C Balita post. Reading is open. Guests get an inline sign-in gate
/// on the social row, not the full Restricted page and not the guest sheet.
///
/// [openedFromNotification] paints the deep-link eyebrow. The ambulance
/// inbox row sets it. Other inbox rows do not.
class BalitaPostDetailScreen extends StatelessWidget {
  final String postId;
  final bool openedFromNotification;

  const BalitaPostDetailScreen({
    super.key,
    required this.postId,
    this.openedFromNotification = false,
  });

  static void open(
    BuildContext context,
    String postId, {
    bool openedFromNotification = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BalitaPostDetailScreen(
          postId: postId,
          openedFromNotification: openedFromNotification,
        ),
      ),
    );
  }

  /// Inbox landing for the ambulance Balita row. Same post, eyebrow on.
  static void openFromNotification(BuildContext context, String postId) {
    open(context, postId, openedFromNotification: true);
  }

  @override
  Widget build(BuildContext context) {
    final posts = context.watch<BalitaService>().posts;
    Announcement? post;
    for (final candidate in posts) {
      if (candidate.id == postId) {
        post = candidate;
        break;
      }
    }
    final guest =
        context.watch<CitizenSessionService>().accessLevel == AccessLevel.guest;
    final paragraphs = post == null ? const <String>[] : _body(post, guest);

    return DetailScaffold(
      title: 'Balita',
      openedFromNotification: openedFromNotification,
      onBack: () => Navigator.of(context).maybePop(),
      onShare: () {
        if (post == null) return;
        _share(context, post, guest);
      },
      children: [
        if (post == null)
          const Text(
            'This announcement is not in the local preview.',
            style: detailBody,
          )
        else ...[
          _Hero(post: post),
          const SizedBox(height: 14),
          Row(
            children: [
              DetailChip(
                label: post.kind,
                background: SoftColors.blueSoft,
                foreground: SoftColors.blueDeep,
              ),
              const SizedBox(width: 8),
              Text(
                post.time,
                style: detailBody.copyWith(fontSize: 12, height: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.displayTitle, style: detailHeadline),
          const SizedBox(height: 8),
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Text(paragraphs[i], style: detailBody),
          ],
          const SizedBox(height: 12),
          SoftPanel(
            child: Row(
              children: [
                Expanded(
                  child: _Meta(
                    label: 'Source',
                    value: post.official.isNotEmpty
                        ? post.official
                        : post.author,
                  ),
                ),
                Expanded(
                  child: _Meta(
                    label: 'Barangay',
                    value:
                        post.barangay == null || post.barangay!.trim().isEmpty
                        ? 'Town-wide'
                        : post.barangay!,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SoftPanel(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: _SocialRow(post: post, guest: guest),
          ),
          const SizedBox(height: 12),
          if (guest) const _GuestGate() else _CommentsPreview(post: post),
        ],
      ],
    );
  }

  /// Guest fold is shorter so the inline gate stays on the first screen.
  /// Signed-in and notification landings share the catalog article.
  List<String> _body(Announcement post, bool guest) {
    if (guest && post.id == balitaAmbulancePostId) {
      return const [
        'The Municipality of Teresa, Rizal unveiled a new ambulance unit to strengthen emergency response for barangays across town.',
        'Mayor Rodel N. Dela Cruz thanked community partners. Guests may read; liking and commenting need an account.',
      ];
    }
    return post.paragraphs;
  }

  void _share(BuildContext context, Announcement post, bool guest) {
    if (guest) return;
    requireAccountForBalita(context, 'Sharing Balita posts', () {
      BalitaShareSheet.show(
        context,
        post,
        () => context.read<BalitaService>().share(post.id),
      );
    });
  }
}

class _Hero extends StatelessWidget {
  final Announcement post;
  const _Hero({required this.post});

  @override
  Widget build(BuildContext context) {
    final media = post.media;
    final ambulance = post.id == balitaAmbulancePostId;
    return ClipRRect(
      borderRadius: BorderRadius.circular(SoftRadius.lg),
      child: AspectRatio(
        aspectRatio: 16 / 8.2,
        child: ambulance
            ? const _AmbulancePhoto()
            : media == null ||
                  media.path == balitaPhotoSlotPath ||
                  !media.isAsset ||
                  media.type != PostMediaType.image
            ? const DashedBannerSlot(
                label: 'Photo slot',
                caption: '16:9 · art pending',
              )
            : Image.asset(media.path, fit: BoxFit.cover),
      ),
    );
  }
}

/// Ambulance hero. The parent clip supplies the radius. Compact 16:8.2.
///
/// Paints [balitaAmbulanceAsset]. The soft wash is only the missing-file
/// fallback while [balitaAmbulanceAssetBundled] is false.
class _AmbulancePhoto extends StatelessWidget {
  const _AmbulancePhoto();

  @override
  Widget build(BuildContext context) {
    if (!balitaAmbulanceAssetBundled) {
      return const ColoredBox(
        key: ValueKey('balita-ambulance-hero'),
        color: SoftColors.blueWash,
      );
    }
    return Image.asset(
      balitaAmbulanceAsset,
      key: const ValueKey('balita-ambulance-hero'),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const ColoredBox(color: SoftColors.blueWash),
    );
  }
}

const String balitaAmbulancePostId = 'bal-ambulance';

/// Bundle path for the Pack C hero.
const String balitaAmbulanceAsset = 'assets/images/balita/lgu-ambulance.jpg';

/// True while [balitaAmbulanceAsset] is declared in pubspec and present
/// on disk. Image.asset is not called while this is false — a missing
/// asset fails the widget test even when an error builder is set.
const bool balitaAmbulanceAssetBundled = true;

class _Meta extends StatelessWidget {
  final String label;
  final String value;
  const _Meta({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: SoftType.cellLabel),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppTypography.sans,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.26,
            color: SoftColors.ink,
            fontFeatures: SoftType.features,
          ),
        ),
      ],
    );
  }
}

class _SocialRow extends StatelessWidget {
  final Announcement post;
  final bool guest;
  const _SocialRow({required this.post, required this.guest});

  @override
  Widget build(BuildContext context) {
    if (guest) {
      return const Row(
        children: [
          Expanded(
            child: _SocialAct(
              icon: Icons.favorite_border_rounded,
              label: 'Like',
              muted: true,
            ),
          ),
          Expanded(
            child: _SocialAct(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Comment',
              muted: true,
            ),
          ),
          Expanded(
            child: _SocialAct(
              icon: Icons.ios_share_rounded,
              label: 'Share',
              muted: true,
            ),
          ),
        ],
      );
    }
    final liked = post.liked;
    return Row(
      children: [
        Expanded(
          child: _SocialAct(
            icon: liked
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: '${post.likes}',
            color: liked ? SoftColors.danger : SoftColors.ink,
            onTap: () => requireAccountForBalita(
              context,
              'Reacting to Balita posts',
              () => context.read<BalitaService>().toggleLike(post.id),
            ),
          ),
        ),
        Expanded(
          child: _SocialAct(
            icon: Icons.chat_bubble_outline_rounded,
            label: '${post.shownCommentCount}',
            onTap: () => _openComments(context, post),
          ),
        ),
        Expanded(
          child: _SocialAct(
            icon: Icons.ios_share_rounded,
            label: 'Share',
            onTap: () {
              requireAccountForBalita(context, 'Sharing Balita posts', () {
                BalitaShareSheet.show(
                  context,
                  post,
                  () => context.read<BalitaService>().share(post.id),
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

class _SocialAct extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool muted;
  final VoidCallback? onTap;

  const _SocialAct({
    required this.icon,
    required this.label,
    this.color = SoftColors.ink,
    this.muted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = muted ? SoftColors.muted : color;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.sans,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.195,
                  color: fg,
                  fontFeatures: SoftType.features,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsPreview extends StatelessWidget {
  final Announcement post;
  const _CommentsPreview({required this.post});

  @override
  Widget build(BuildContext context) {
    final preview = post.comments.take(2).toList();
    return SoftPanel(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Comments · ${post.shownCommentCount}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTypography.sans,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.28,
                    color: SoftColors.ink,
                    fontFeatures: SoftType.features,
                  ),
                ),
              ),
              InkWell(
                onTap: () => _openComments(context, post),
                child: const Text('View comments', style: SoftType.sectionLink),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < preview.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: 1, color: SoftColors.line),
            _CommentLine(comment: preview[i]),
          ],
        ],
      ),
    );
  }
}

class _CommentLine extends StatelessWidget {
  final PostComment comment;
  const _CommentLine({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SoftColors.avatarGradient,
            ),
            child: Text(
              _initials(comment.author),
              style: const TextStyle(
                fontFamily: AppTypography.sans,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SoftColors.white,
                fontFeatures: SoftType.features,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: comment.author,
                        style: const TextStyle(
                          fontFamily: AppTypography.sans,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: SoftColors.ink,
                          fontFeatures: SoftType.features,
                        ),
                      ),
                      TextSpan(
                        text: '  ${comment.time}',
                        style: SoftType.cellLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  comment.body,
                  style: const TextStyle(
                    fontFamily: AppTypography.sans,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w400,
                    color: SoftColors.ink,
                    fontFeatures: SoftType.features,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestGate extends StatelessWidget {
  const _GuestGate();

  @override
  Widget build(BuildContext context) {
    return SoftPanel(
      tone: SoftPanelTone.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Reading is open to guests',
            style: TextStyle(
              fontFamily: AppTypography.sans,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.26,
              color: SoftColors.ink,
              fontFeatures: SoftType.features,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Like, comment, and share need a signed-in account. This is a local preview gate — not the full Restricted page.',
            style: detailBody,
          ),
          const SizedBox(height: 10),
          DetailPillButton(
            label: 'Sign in to like & comment',
            primary: true,
            onPressed: () => _leaveGuest(context, register: false),
          ),
          const SizedBox(height: 8),
          DetailPillButton(
            label: 'Create account',
            onPressed: () => _leaveGuest(context, register: true),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGuest(
    BuildContext context, {
    required bool register,
  }) async {
    final nav = Navigator.of(context, rootNavigator: true);
    await context.read<CitizenSessionService>().endGuestSession();
    nav.popUntil((route) => route.isFirst);
    if (register) {
      nav.push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    }
  }
}

void _openComments(BuildContext context, Announcement post) {
  final level = context.read<CitizenSessionService>().accessLevel;
  if (level != AccessLevel.verified) {
    requireAccountForBalita(context, 'Commenting on Balita posts', () {});
    return;
  }
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CommentsSheet(
      post: post,
      onSubmit: (comment) =>
          context.read<BalitaService>().addComment(post.id, comment),
    ),
  );
}

String _initials(String name) {
  final parts = name
      .split(RegExp(r'\s+'))
      .map((p) => p.replaceAll('.', ''))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
