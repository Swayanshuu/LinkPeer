import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  RealtimeChannel? _channel;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    // 1. Clean up any previous channel subscription if rebuilding
    _channel?.unsubscribe();

    // 2. Set up the realtime subscription for new posts
    _setupSubscription();

    // 3. Fetch and return initial data
    return _fetchInitialPosts();
  }

  void _setupSubscription() {
    _channel = Supabase.instance.client.channel('public:posts');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            final newPost = Map<String, dynamic>.from(payload.newRecord);
            newPost['post_likes'] = [];
            newPost['saved_posts'] = [];

            _addNewPost(newPost);
          },
        )
        .subscribe((status, [error]) {});

    ref.onDispose(() {
      _channel?.unsubscribe();
    });
  }

  void _addNewPost(Map<String, dynamic> newPost) {
    final currentPosts = state.hasValue ? state.value : null;
    if (currentPosts != null) {
      // Prevent inserting duplicate posts
      if (!currentPosts.any((p) => p['id'] == newPost['id'])) {
        // Updating state directly with AsyncData avoids a 'loading' flash and preserves scroll position
        state = AsyncData([newPost, ...currentPosts]);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchInitialPosts() async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'cached_posts';

    try {
      final data = await Supabase.instance.client
          .from('posts')
          .select('*, post_likes(user_id), saved_posts(user_id)')
          .order('created_at', ascending: false);

      final resultList = List<Map<String, dynamic>>.from(data);

      // Cache the latest posts
      await prefs.setString(cacheKey, jsonEncode(resultList));

      return resultList;
    } catch (e) {
      // On network failure or error, attempt to load from local cache
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        try {
          final decoded = jsonDecode(cachedStr) as List<dynamic>;
          return decoded.map((e) => e as Map<String, dynamic>).toList();
        } catch (_) {
          rethrow;
        }
      }
      // No cache available, throw original error
      rethrow;
    }
  }
}

final postsProvider =
    AsyncNotifierProvider<PostsNotifier, List<Map<String, dynamic>>>(
      () => PostsNotifier(),
    );
