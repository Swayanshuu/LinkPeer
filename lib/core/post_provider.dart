import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
final postsProvider =
FutureProvider<List<Map<String,dynamic>>>(
        (ref) async {
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
    });