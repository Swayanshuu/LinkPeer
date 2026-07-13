import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserNotifier extends AsyncNotifier<Map<String, dynamic>> {
  @override
  Future<Map<String, dynamic>> build() async {
    return _loadCacheAndFetch();
  }

  Future<Map<String, dynamic>> _loadCacheAndFetch() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return {'user_type': 'guest'};
    }
    
    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_user_$uid';
    final cachedStr = prefs.getString(cacheKey);

    if (cachedStr != null) {
      try {
        final cachedData = jsonDecode(cachedStr) as Map<String, dynamic>;
        
        // Trigger background fetch to update the state silently
        _fetchNetworkAndUpdate(uid, cacheKey, prefs);
        
        return cachedData;
      } catch (_) {}
    }

    // No cache available, fetch from network and wait
    return await _fetchNetwork(uid, cacheKey, prefs);
  }

  Future<void> _fetchNetworkAndUpdate(String uid, String cacheKey, SharedPreferences prefs) async {
    try {
      final freshData = await _fetchNetwork(uid, cacheKey, prefs);
      state = AsyncData(freshData);
    } catch (e) {
      // Background fetch failed, silently ignore to keep cache shown
    }
  }

  Future<Map<String, dynamic>> _fetchNetwork(String uid, String cacheKey, SharedPreferences prefs) async {
    final data = await Supabase.instance.client
        .from('users')
        .select(
          'name, photo_url, user_type, id, profile_completed, department, email, role, created_at, last_login, branch, college, stream, graduating_year, designation, phone, github, link2, description, is_verified, subscription_plan, subscription_status, faculty_verified, faculty_verification_image',
        )
        .eq('id', uid)
        .single();

    // Cache the latest user data
    await prefs.setString(cacheKey, jsonEncode(data));
    return data;
  }

  // Use this for pull-to-refresh on profile screen
  Future<void> forceRefresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    
    final uid = user.uid;
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'cached_user_$uid';

    state = const AsyncLoading();
    try {
      final freshData = await _fetchNetwork(uid, cacheKey, prefs);
      state = AsyncData(freshData);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, Map<String, dynamic>>(
  () => UserNotifier(),
);
