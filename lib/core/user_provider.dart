import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    return {};
  }

  final prefs = await SharedPreferences.getInstance();
  final cacheKey = 'cached_user_$uid';

  try {
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
  } catch (e) {
    // On network failure or error, attempt to load from local cache
    final cachedStr = prefs.getString(cacheKey);
    if (cachedStr != null) {
      try {
        return jsonDecode(cachedStr) as Map<String, dynamic>;
      } catch (_) {
        // If parsing fails, rethrow the original error
        rethrow;
      }
    }
    // No cache available, throw the original error
    rethrow;
  }
});
