import 'package:flutter/foundation.dart';
import 'package:igit_connects/features/broadcast/models/broadcast_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igit_connects/storage_backend.dart';

class BroadcastService {
  final _supabase = Supabase.instance.client;

  Future<List<BroadcastModel>> getBroadcasts({
    required int offset,
    required int limit,
    required String userType,
  }) async {
    try {
      final response = await _supabase
          .from('broadcasts')
          .select()
          .inFilter('audience', ['all', userType.toLowerCase()])
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint("RAW BROADCASTS RESPONSE: \$response");

      return (response as List<dynamic>).map((json) {
        try {
          return BroadcastModel.fromJson(json as Map<String, dynamic>);
        } catch (err) {
          debugPrint("Failed to parse broadcast: \$err - Data: \$json");
          rethrow;
        }
      }).toList();
    } catch (e) {
      debugPrint("Error fetching broadcasts: \$e");
      rethrow;
    }
  }

  Future<BroadcastModel> getBroadcastById(String id) async {
    try {
      final response = await _supabase
          .from('broadcasts')
          .select()
          .eq('id', id)
          .single();

      return BroadcastModel.fromJson(response);
    } catch (e) {
      debugPrint("Error fetching broadcast by id: \$e");
      rethrow;
    }
  }

  Future<void> createBroadcast({
    required String title,
    required String message,
    required String audience,
    required String createdBy,
    String? imageUrl,
    String? linkUrl,
  }) async {
    try {
      await _supabase.from('broadcasts').insert({
        'title': title,
        'message': message,
        'audience': audience,
        'created_by': createdBy,
        'image_url': imageUrl,
        'link_url': linkUrl,
      });
    } catch (e) {
      debugPrint("Error creating broadcast: $e");
      rethrow;
    }
  }

  Future<void> deleteBroadcast(String id, {String? imageUrl}) async {
    try {
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await StorageBackend().removeBroadcastImage(imageUrl);
      }
      await _supabase.from('broadcasts').delete().eq('id', id);
    } catch (e) {
      debugPrint("Error deleting broadcast: $e");
      rethrow;
    }
  }
}
