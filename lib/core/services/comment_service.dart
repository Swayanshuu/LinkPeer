import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igit_connects/core/models/comment_model.dart';
import 'package:igit_connects/utils/profanity_filter.dart';

class CommentService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Fetch paginated comments for a post
  Future<List<CommentModel>> getComments({
    required int postId,
    required int offset,
    required int limit,
  }) async {
    try {
      final data = await _client
          .from('post_comments')
          .select('*, users!post_comments_user_id_fkey(name, photo_url, is_verified, role, faculty_verified, user_type)')
          .eq('post_id', postId)
          .order('likes_count', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (data as List).map((json) => CommentModel.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle like on a comment
  Future<void> toggleLike({
    required int commentId,
    required String userId,
  }) async {
    try {
      await _client.rpc('toggle_comment_like', params: {
        'p_comment_id': commentId,
        'p_user_id': userId,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Add a new comment
  Future<CommentModel> addComment({
    required int postId,
    required String userId,
    required String commentText,
  }) async {
    try {
      if (ProfanityFilter.hasProfanity(commentText)) {
        throw Exception("Please remove inappropriate language from your comment.");
      }

      final response = await _client.from('post_comments').insert({
        'post_id': postId,
        'user_id': userId,
        'comment_text': commentText.trim(),
      }).select('*, users!post_comments_user_id_fkey(name, photo_url, is_verified, role, faculty_verified, user_type)').single();

      return CommentModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteComment({
    required int commentId,
    required String userId,
  }) async {
    try {
      await _client
          .from('post_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Set up a real-time subscription for comments on a specific post
  RealtimeChannel subscribeToComments(
      int postId, void Function(PostgresChangePayload payload) onData) {
    final channel = _client.channel('public:post_comments:post_id=$postId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'post_comments',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'post_id',
        value: postId,
      ),
      callback: onData,
    ).subscribe();

    return channel;
  }
}
