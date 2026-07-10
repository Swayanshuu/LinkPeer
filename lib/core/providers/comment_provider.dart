import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igit_connects/core/models/comment_model.dart';
import 'package:igit_connects/core/services/comment_service.dart';

final commentServiceProvider = Provider<CommentService>(
  (ref) => CommentService(),
);

class CommentNotifier extends ChangeNotifier {
  final Ref ref;
  final int postId;
  RealtimeChannel? _channel;
  bool hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  List<CommentModel> comments = [];
  bool isLoading = true;
  String? error;

  CommentNotifier(this.ref, this.postId) {
    _init();
  }

  Future<void> _init() async {
    _setupSubscription();
    await fetchInitialComments();
  }

  void _setupSubscription() {
    _channel?.unsubscribe();
    final commentService = ref.read(commentServiceProvider);

    _channel = commentService.subscribeToComments(postId, (payload) async {
      if (payload.eventType == PostgresChangeEvent.insert) {
        final newCommentId = payload.newRecord['id'];

        try {
          final data = await Supabase.instance.client
              .from('post_comments')
              .select(
                '*, users!post_comments_user_id_fkey(name, photo_url, is_verified, role)',
              )
              .eq('id', newCommentId)
              .single();

          final newComment = CommentModel.fromJson(data);
          addCommentLocally(newComment);
        } catch (_) {}
      } else if (payload.eventType == PostgresChangeEvent.delete) {
        final deletedId = payload.oldRecord['id'];
        removeCommentLocally(deletedId);
      }
    });
  }

  void addCommentLocally(CommentModel newComment) {
    if (!comments.any((c) => c.id == newComment.id)) {
      comments.insert(0, newComment);
      _offset++;
      notifyListeners();
    }
  }

  void removeCommentLocally(int commentId) {
    comments.removeWhere((c) => c.id == commentId);
    _offset--;
    notifyListeners();
  }

  Future<void> fetchInitialComments() async {
    final commentService = ref.read(commentServiceProvider);
    _offset = 0;
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final fetchedComments = await commentService.getComments(
        postId: postId,
        offset: _offset,
        limit: _limit,
      );

      if (fetchedComments.length < _limit) {
        hasMore = false;
      }
      _offset += fetchedComments.length;
      comments = fetchedComments;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreComments() async {
    if (!hasMore || isLoading) return;

    final commentService = ref.read(commentServiceProvider);
    isLoading = true;
    notifyListeners();

    try {
      final moreComments = await commentService.getComments(
        postId: postId,
        offset: _offset,
        limit: _limit,
      );

      if (moreComments.length < _limit) {
        hasMore = false;
      }

      _offset += moreComments.length;
      comments.addAll(moreComments);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int commentId, String userId) async {
    final index = comments.indexWhere((c) => c.id == commentId);
    if (index == -1) return;

    final comment = comments[index];
    final isLiked = comment.likedBy.contains(userId);
    
    // Optimistic update
    final newLikedBy = List<String>.from(comment.likedBy);
    if (isLiked) {
      newLikedBy.remove(userId);
    } else {
      newLikedBy.add(userId);
    }
    
    final newComment = comment.copyWith(
      likedBy: newLikedBy,
      likesCount: comment.likesCount + (isLiked ? -1 : 1),
    );
    
    comments[index] = newComment;
    
    // Resort comments: likes desc, then created_at desc
    comments.sort((a, b) {
      if (a.likesCount != b.likesCount) {
        return b.likesCount.compareTo(a.likesCount);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    
    notifyListeners();

    try {
      final commentService = ref.read(commentServiceProvider);
      await commentService.toggleLike(commentId: commentId, userId: userId);
    } catch (e) {
      // Revert if failed
      final revertIndex = comments.indexWhere((c) => c.id == commentId);
      if (revertIndex != -1) {
        comments[revertIndex] = comment;
        comments.sort((a, b) {
          if (a.likesCount != b.likesCount) {
            return b.likesCount.compareTo(a.likesCount);
          }
          return b.createdAt.compareTo(a.createdAt);
        });
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final commentProvider = ChangeNotifierProvider.family<CommentNotifier, int>(
  (ref, postId) => CommentNotifier(ref, postId),
);
