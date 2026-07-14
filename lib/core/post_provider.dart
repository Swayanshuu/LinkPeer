import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  RealtimeChannel? _channel;

  @override
  Future<List<Map<String, dynamic>>> build() async {
    // Clean previous subscription
    _channel?.unsubscribe();

    // Subscribe to new posts
    _setupSubscription();

    // Fetch initial data
    return _loadCacheAndFetch();
  }

  void _setupSubscription() {
    _channel = Supabase.instance.client.channel('public:posts');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'posts',
          callback: (payload) async {
            final newPost = Map<String, dynamic>.from(payload.newRecord);
            newPost['post_likes'] = [];
            newPost['saved_posts'] = [];
            newPost['post_comments'] = [
              {'count': 0},
            ];

            try {
              final userResp = await Supabase.instance.client
                  .from('users')
                  .select(
                    'is_verified, subscription_plan, role, faculty_verified, branch, designation, user_type',
                  )
                  .eq('id', newPost['user_id'])
                  .maybeSingle();
              if (userResp != null) {
                newPost['users'] = userResp;
              }
            } catch (_) {}

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

  Future<List<Map<String, dynamic>>> _loadCacheAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'cached_posts';
    final cachedStr = prefs.getString(cacheKey);

    if (cachedStr != null) {
      try {
        final decoded = jsonDecode(cachedStr) as List<dynamic>;
        final cachedList = decoded
            .map((e) => e as Map<String, dynamic>)
            .toList();

        // Trigger background fetch to update the state silently
        _fetchNetworkAndUpdate();

        return cachedList;
      } catch (_) {}
    }

    // No cache available, fetch from network and wait
    return await _fetchNetwork();
  }

  Future<void> _fetchNetworkAndUpdate() async {
    try {
      final freshData = await _fetchNetwork();
      // Silently update state with fresh data
      state = AsyncData(freshData);
    } catch (e) {
      // Ignored silently, keeping cached data visible
    }
  }

  Future<List<Map<String, dynamic>>> _fetchNetwork() async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'cached_posts';

    final data = await Supabase.instance.client
        .from('posts')
        .select(
          '*, post_likes(user_id), saved_posts(user_id), post_comments(count), users!posts_user_id_fkey(is_verified, subscription_plan, role, faculty_verified, branch, designation, user_type)',
        )
        .order('created_at', ascending: false);

    final resultList = List<Map<String, dynamic>>.from(data);

    // Cache the latest posts
    await prefs.setString(cacheKey, jsonEncode(resultList));
    return resultList;
  }

  // Use this for pull-to-refresh
  Future<void> forceRefresh() async {
    state = const AsyncLoading();
    try {
      final freshData = await _fetchNetwork();
      state = AsyncData(freshData);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Update a specific post without reloading everything
  void updatePostLocally(Map<String, dynamic> updatedPost) {
    if (!state.hasValue) return;
    final currentList = state.value!;
    final index = currentList.indexWhere((p) => p['id'] == updatedPost['id']);
    if (index != -1) {
      final newList = List<Map<String, dynamic>>.from(currentList);
      newList[index] = updatedPost;
      state = AsyncData(newList);
    }
  }
}

final postsProvider =
    AsyncNotifierProvider<PostsNotifier, List<Map<String, dynamic>>>(
      () => PostsNotifier(),
    );
