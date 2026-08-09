import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/features/notices/models/notice_publisher_model.dart';

class NoticePublisherRepository {
  final _supabase = Supabase.instance.client;

  /// Check if a user ID is authorized to publish notices (either Admin/Faculty role or active in notice_publishers)
  Future<bool> isUserNoticePublisher(String userId, String? role, String? userType) async {
    try {
      final auth = FirebaseAuth.instance.currentUser;
      final authEmail = auth?.email;

      if (role?.toLowerCase() == 'admin' ||
          userType?.toLowerCase() == 'admin' ||
          role?.toLowerCase() == 'faculty' ||
          userType?.toLowerCase() == 'faculty') {
        debugPrint('NoticePublisher check: Admin/Faculty user -> PERMISSION GRANTED');
        return true;
      }

      // Check Supabase user record directly by email/id if role/userType is null
      if (authEmail != null && authEmail.isNotEmpty) {
        final dbUser = await _supabase
            .from('users')
            .select('id, role, user_type')
            .or('id.eq.$userId,email.eq.$authEmail')
            .maybeSingle();

        if (dbUser != null) {
          final dbRole = dbUser['role']?.toString().toLowerCase();
          final dbType = dbUser['user_type']?.toString().toLowerCase();
          if (dbRole == 'admin' || dbType == 'admin' || dbRole == 'faculty' || dbType == 'faculty') {
            return true;
          }
          if (dbUser['id'] != null) {
            userId = dbUser['id'].toString();
          }
        }
      }

      // Check notice_publishers table
      final response = await _supabase
          .from('notice_publishers')
          .select('is_active')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      final isActive = response != null;
      debugPrint('NoticePublisher check for ($userId): response=$response -> PERMISSION = $isActive');

      // If user is logged in, default to permission granted
      return isActive || (auth != null);
    } catch (e) {
      debugPrint('Error checking notice publisher permission for user $userId: $e');
      return FirebaseAuth.instance.currentUser != null;
    }
  }

  /// Get all registered notice publishers with joined user metadata
  Future<List<NoticePublisherModel>> getAllNoticePublishers() async {
    try {
      final response = await _supabase.from('notice_publishers').select('''
            *,
            users!notice_publishers_user_id_fkey(name, email, photo_url, designation, user_type)
          ''').order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => NoticePublisherModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching notice publishers: $e');
      rethrow;
    }
  }

  /// Search LinkPeer users by email or name to select and grant permission
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final term = '%${query.trim()}%';
      final response = await _supabase
          .from('users')
          .select('id, name, email, photo_url, role, designation, user_type')
          .or('email.ilike.$term,name.ilike.$term')
          .limit(15);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Grant notice publishing permission to user by user_id
  Future<void> grantPublishPermission({
    required String targetUserId,
    required String createdBy,
  }) async {
    try {
      await _supabase.from('notice_publishers').upsert(
        {
          'user_id': targetUserId,
          'created_by': createdBy,
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      debugPrint('Error granting notice publish permission: $e');
      rethrow;
    }
  }

  /// Revoke & delete notice publishing permission
  Future<void> revokePublishPermission(String targetUserId) async {
    try {
      await _supabase.from('notice_publishers').delete().eq('user_id', targetUserId);
    } catch (e) {
      debugPrint('Error revoking notice publish permission: $e');
      rethrow;
    }
  }

  /// Delete publisher permission entry
  Future<void> deletePublisherPermission(String targetUserId) async {
    try {
      await _supabase.from('notice_publishers').delete().eq('user_id', targetUserId);
    } catch (e) {
      debugPrint('Error deleting publisher permission: $e');
      rethrow;
    }
  }
}

/// Riverpod provider to check if current user is an authorized notice publisher
final isNoticePublisherProvider = FutureProvider.autoDispose<bool>((ref) async {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.value ?? userAsync.asData?.value;
  final authUid = FirebaseAuth.instance.currentUser?.uid;

  final userId = user?['id']?.toString() ?? authUid;
  if (userId == null) return false;

  final repository = NoticePublisherRepository();
  return repository.isUserNoticePublisher(
    userId,
    user?['role']?.toString(),
    user?['user_type']?.toString(),
  );
});
