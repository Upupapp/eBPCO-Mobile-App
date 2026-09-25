import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/access_level.dart';
import '../../models/announcement.dart';
import '../../services/citizen_session_service.dart';
import '../../theme/soft_widget.dart';
import '../auth/register_screen.dart';
import '../../widgets/restricted_feature_notice.dart';

/// Comments for one Balita post. Signed-in verified residents get the list
/// and a composer. Guests see a one-comment preview and a Sign in CTA in
/// place of the composer. Unverified accounts keep the list, with the
/// composer replaced by a verification CTA. The sheet pads for the keyboard
/// so the field and the send control stay on screen.
class CommentsSheet extends StatefulWidget {
  final Announcement post;
  final ValueChanged<PostComment> onSubmit;

  const CommentsSheet({super.key, required this.post, required this.onSubmit});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller = TextEditingController();
  late final List<PostComment> _comments = List.of(widget.post.comments);
  late int _count = widget.post.commentCount;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final account = context.read<CitizenSessionService>().account;
    final comment = PostComment(author: account?.fullName ?? 'You', body: text);
    setState(() {
      _comments.add(comment);
      _count += 1;
    });
    widget.onSubmit(comment);
    _controller.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _leaveGuest({required bool register}) async {
    final nav = Navigator.of(context, rootNavigator: true);
    await context.read<CitizenSessionService>().endGuestSession();
    if (!mounted) return;
    nav.popUntil((route) => route.isFirst);
    if (register) {
      nav.push(MaterialPageRoute(builder: (_) => const RegisterScreen()));
    }
  }

  void _continueVerification() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RestrictedFeatureNotice(
          reason: RestrictionReason.needsVerification,
          featureName: 'Commenting on Balita posts',
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final level = context.watch<CitizenSessionService>().accessLevel;
    final canCompose = level == AccessLevel.verified;
    final isGuest = level == AccessLevel.guest;
    final visible = isGuest ? _comments.take(1).toList() : _comments;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.78;
    final subtitle = canCompose
        ? '$_count comment${_count == 1 ? '' : 's'} · local only'
        : isGuest
            ? 'Sign in to join the conversation'
            : 'Verify your account to join the conversation';

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: const BoxDecoration(
            color: SoftColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(SoftRadius.xl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Comments', style: SoftType.h1),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(subtitle, style: SoftType.body),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: visible.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                        child: Text(
                          'No comments yet. Be the first to comment.',
                          textAlign: TextAlign.center,
                          style: SoftType.body,
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                        itemCount: visible.length,
                        itemBuilder: (context, i) {
                          final c = visible[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      decoration: const BoxDecoration(
                                        color: SoftColors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        _initials(c.author),
                                        style: SoftType.sectionLink.copyWith(
                                          color: SoftColors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  c.author,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: SoftType.cellValue.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(c.time, style: SoftType.cellLabel),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            c.body,
                                            style: SoftType.body.copyWith(height: 1.4),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: SoftColors.line),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              if (canCompose)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          style: SoftType.body.copyWith(color: SoftColors.ink),
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            hintStyle: SoftType.body,
                            filled: true,
                            fillColor: SoftColors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(SoftRadius.pill),
                              borderSide: const BorderSide(color: SoftColors.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(SoftRadius.pill),
                              borderSide: const BorderSide(color: SoftColors.blue),
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: SoftColors.blue,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _send,
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Icon(Icons.send_rounded, size: 18, color: SoftColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (isGuest)
                _GuestCommentGate(
                  onSignIn: () {
                    _leaveGuest(register: false);
                  },
                  onCreateAccount: () {
                    _leaveGuest(register: true);
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _SheetPill(
                    label: 'Continue verification',
                    filled: true,
                    onTap: _continueVerification,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestCommentGate extends StatelessWidget {
  final VoidCallback onSignIn;
  final VoidCallback onCreateAccount;

  const _GuestCommentGate({
    required this.onSignIn,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: SoftColors.blueWash,
          borderRadius: BorderRadius.circular(SoftRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guest view',
              style: SoftType.cellValue.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Likes, comments, and share need a signed-in account.',
              style: SoftType.body,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SheetPill(
                    label: 'Sign in',
                    filled: true,
                    onTap: onSignIn,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SheetPill(
                    label: 'Create account',
                    filled: false,
                    onTap: onCreateAccount,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetPill extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _SheetPill({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? SoftColors.blue : SoftColors.white,
      borderRadius: BorderRadius.circular(SoftRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(SoftRadius.pill),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SoftRadius.pill),
            border: Border.all(color: filled ? SoftColors.blue : SoftColors.line),
          ),
          child: Text(
            label,
            style: SoftType.sectionLink.copyWith(
              color: filled ? SoftColors.white : SoftColors.blue,
            ),
          ),
        ),
      ),
    );
  }
}
