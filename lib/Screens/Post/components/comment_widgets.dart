import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/models/comment_model.dart';
import 'package:igit_connects/core/providers/comment_provider.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentsSection extends ConsumerWidget {
  final int postId;

  const CommentsSection({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(commentProvider(postId));
    final colors = AppColors.of(context);

    if (notifier.isLoading && notifier.comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: CircularProgressIndicator(color: colors.primaryText),
        ),
      );
    }

    if (notifier.error != null && notifier.comments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          "Error loading comments: ${notifier.error}",
          style: TextStyle(color: colors.secondaryText),
        ),
      );
    }

    final comments = notifier.comments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Comments (${comments.length})",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colors.primaryText,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (comments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                "No comments yet. Be the first to comment!",
                style: TextStyle(color: colors.secondaryText),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return CommentTile(
                      comment: comments[index],
                      colors: colors,
                    );
                  },
                ),

                // Load more button
                if (notifier.hasMore)
                  TextButton(
                    onPressed: () {
                      ref.read(commentProvider(postId)).loadMoreComments();
                    },
                    child: notifier.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Load more comments"),
                  ),

                // Bottom padding to avoid hiding behind the fixed input bar
                const SizedBox(height: 80),
              ],
            ),
          ),
      ],
    );
  }
}

class CommentTile extends ConsumerWidget {
  final CommentModel comment;
  final AppColors colors;

  const CommentTile({super.key, required this.comment, required this.colors});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyComment = currentUser?.uid == comment.userId;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colors.borderColor,
          backgroundImage: comment.userPhoto.isNotEmpty
              ? NetworkImage(comment.userPhoto)
              : null,
          child: comment.userPhoto.isEmpty
              ? Icon(Icons.person, color: colors.secondaryText, size: 20)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade900
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              comment.userName,
                              style: TextStyle(
                                color: colors.primaryText,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (comment.isVerified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 14,
                            ),
                          ],
                          if (comment.isFacultyVerified &&
                              comment.userType.toLowerCase() == "faculty") ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.gpp_good_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 14,
                            ),
                          ],
                          if (comment.role.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              comment.role,
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (isMyComment)
                      GestureDetector(
                        onTap: () {
                          _showDeleteOptions(context, ref);
                        },
                        child: Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: colors.secondaryText,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),
                Text(
                  comment.commentText,
                  style: TextStyle(color: colors.primaryText, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  timeago.format(comment.createdAt),
                  style: TextStyle(color: colors.secondaryText, fontSize: 8),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                if (currentUser == null) return;
                ref
                    .read(commentProvider(comment.postId))
                    .toggleLike(comment.id, currentUser.uid);
              },
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  bottom: 4.0,
                  left: 4.0,
                  right: 4.0,
                ),
                child: Icon(
                  comment.likedBy.contains(currentUser?.uid)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: comment.likedBy.contains(currentUser?.uid)
                      ? Colors.red
                      : colors.secondaryText,
                  size: 16,
                ),
              ),
            ),
            if (comment.likesCount > 0)
              Text(
                '${comment.likesCount}',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  void _showDeleteOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    "Delete Comment",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _confirmDelete(context, ref);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Comment",
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this comment?",
          style: TextStyle(color: colors.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: colors.primaryText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // Optimistic deletion
              final notifier = ref.read(commentProvider(comment.postId));
              notifier.removeCommentLocally(comment.id);

              try {
                await ref
                    .read(commentServiceProvider)
                    .deleteComment(
                      commentId: comment.id,
                      userId: comment.userId,
                    );
                // Realtime will ensure it stays deleted
              } catch (e) {
                // Revert optimistic delete if it fails
                notifier.addCommentLocally(comment);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting comment: $e")),
                  );
                }
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class CommentInputBar extends ConsumerStatefulWidget {
  final int postId;
  final FocusNode? focusNode;

  const CommentInputBar({super.key, required this.postId, this.focusNode});

  @override
  ConsumerState<CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends ConsumerState<CommentInputBar> {
  final _controller = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isPosting = true;
    });

    try {
      final newComment = await ref
          .read(commentServiceProvider)
          .addComment(
            postId: widget.postId,
            userId: currentUser.uid,
            commentText: text,
          );

      ref.read(commentProvider(widget.postId)).addCommentLocally(newComment);

      _controller.clear();
      // Keyboard can stay open for more comments
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error posting comment: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: BoxDecoration(
        color: colors.bgColor,
        border: Border(top: BorderSide(color: colors.borderColor, width: 1)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.borderColor,
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? Icon(Icons.person, color: colors.secondaryText, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              //maxLength: 300,
              controller: _controller,
              focusNode: widget.focusNode,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: "Write a comment...",
                hintStyle: TextStyle(color: colors.secondaryText),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade900
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _isPosting
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: _submitComment,
                  icon: const Icon(Icons.send_rounded),
                  color: Colors.blue,
                ),
        ],
      ),
    );
  }
}

void showCommentsModal(BuildContext context, int postId, AppColors colors) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colors.bgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.secondaryText.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    "Comments",
                    style: TextStyle(
                      color: colors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  //const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: CommentsSection(postId: postId),
                    ),
                  ),
                  CommentInputBar(postId: postId),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
