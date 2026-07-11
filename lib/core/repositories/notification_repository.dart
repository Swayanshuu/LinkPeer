import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:igit_connects/core/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> updateFCMToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _supabase.from('users').update({
          'fcm_token': token,
        }).eq('id', user.uid);
      } catch (e) {
        debugPrint("Error saving token to Supabase: $e");
        rethrow;
      }
    }
  }

  Future<int> getUnreadCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;
    
    try {
      final res = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', user.uid)
          .eq('is_read', false)
          .count(CountOption.exact);
      return res.count;
    } catch (e) {
      debugPrint("Error getting unread count: $e");
      return 0;
    }
  }

  Future<List<NotificationModel>> getNotifications({required int offset, required int limit}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final data = await _supabase
          .from('notifications')
          .select('*, actor:users!notifications_actor_user_id_fkey(name, photo_url)')
          .eq('user_id', user.uid)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      debugPrint("Supabase query result count: ${(data as List).length}");
      
      final parsed = (data).map((json) => NotificationModel.fromJson(json)).toList();
      debugPrint("Parsed notification count: ${parsed.length}");
      return parsed;
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint("Error marking notification as read: $e");
      rethrow;
    }
  }
}
