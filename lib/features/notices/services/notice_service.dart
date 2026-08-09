import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igit_connects/features/notices/models/notice_model.dart';
import 'package:igit_connects/features/notices/services/notice_storage_service.dart';

class NoticeService {
  final _supabase = Supabase.instance.client;
  final _storageService = NoticeStorageService();

  /// Read cached notices immediately for instant UI display
  Future<List<NoticeModel>> getCachedNotices({String? category}) async {
    final catKey = category?.toLowerCase().replaceAll(' ', '_') ?? 'all';
    final cacheKey = 'cached_notices_$catKey';
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        final decoded = jsonDecode(cachedStr) as List<dynamic>;
        return decoded
            .map((json) => NoticeModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
    return [];
  }

  /// Cache-first fetch notices with category filter, search query, offset, and limit
  Future<List<NoticeModel>> getNotices({
    int offset = 0,
    int limit = 20,
    String? category,
    String? searchQuery,
  }) async {
    final isDefaultQuery = (searchQuery == null || searchQuery.trim().isEmpty) && offset == 0;
    final catKey = category?.toLowerCase().replaceAll(' ', '_') ?? 'all';
    final cacheKey = 'cached_notices_$catKey';

    List<NoticeModel>? cachedList;
    SharedPreferences? prefs;

    if (isDefaultQuery) {
      try {
        prefs = await SharedPreferences.getInstance();
        final cachedStr = prefs.getString(cacheKey);
        if (cachedStr != null) {
          final decoded = jsonDecode(cachedStr) as List<dynamic>;
          cachedList = decoded
              .map((json) => NoticeModel.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      } catch (e) {
        debugPrint('Cache read error for notices: $e');
      }
    }

    try {
      var query = _supabase.from('notices').select('''
            *,
            publisher:users!notices_publisher_id_fkey(id, name, email, photo_url, user_type, role, designation, department, branch),
            notice_attachments(*)
          ''');

      if (category != null && category != 'All' && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final term = '%${searchQuery.trim()}%';
        query = query.or('title.ilike.$term,content.ilike.$term');
      }

      final response = await query
          .order('is_important', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final rawList = response as List<dynamic>;
      final freshList = rawList
          .map((json) => NoticeModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (isDefaultQuery && prefs != null) {
        try {
          await prefs.setString(cacheKey, jsonEncode(rawList));
        } catch (e) {
          debugPrint('Cache write error for notices: $e');
        }
      }

      return freshList;
    } catch (e) {
      debugPrint('Error fetching notices from network: $e');
      if (cachedList != null && cachedList.isNotEmpty) {
        debugPrint('Returning ${cachedList.length} cached notices fallback');
        return cachedList;
      }
      rethrow;
    }
  }

  /// Cache-first fetch notice by ID with publisher & attachment details
  Future<NoticeModel?> getNoticeById(String id) async {
    final cacheKey = 'cached_notice_detail_$id';
    NoticeModel? cachedNotice;
    SharedPreferences? prefs;

    try {
      prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        cachedNotice = NoticeModel.fromJson(jsonDecode(cachedStr) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Cache read error for notice detail ($id): $e');
    }

    try {
      final response = await _supabase
          .from('notices')
          .select('''
            *,
            publisher:users!notices_publisher_id_fkey(id, name, email, photo_url, user_type, role, designation, department, branch),
            notice_attachments(*)
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return cachedNotice;

      if (prefs != null) {
        try {
          await prefs.setString(cacheKey, jsonEncode(response));
        } catch (_) {}
      }

      return NoticeModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching notice by ID ($id): $e');
      if (cachedNotice != null) {
        return cachedNotice;
      }
      rethrow;
    }
  }

  /// Create a notice with attachments and push notification trigger
  Future<NoticeModel> createNotice({
    required String title,
    required String content,
    required String category,
    required String publisherId,
    required bool isImportant,
    String? externalUrl,
    List<PlatformFile> attachmentFiles = const [],
  }) async {
    String? createdNoticeId;
    List<String> uploadedFilePaths = [];

    try {
      final noticeData = await _supabase.from('notices').insert({
        'title': title,
        'content': content,
        'category': category,
        'publisher_id': publisherId,
        'is_important': isImportant,
        'external_url': externalUrl?.trim().isEmpty == true ? null : externalUrl?.trim(),
      }).select().single();

      createdNoticeId = noticeData['id'].toString();

      if (attachmentFiles.isNotEmpty) {
        for (var file in attachmentFiles) {
          final uploadResult = await _storageService.uploadNoticeAttachment(
            noticeId: createdNoticeId,
            file: file,
          );

          uploadedFilePaths.add(uploadResult['file_path'].toString());

          await _supabase.from('notice_attachments').insert({
            'notice_id': createdNoticeId,
            'file_name': uploadResult['file_name'],
            'file_path': uploadResult['file_path'],
            'file_url': uploadResult['file_url'],
            'file_type': uploadResult['file_type'],
            'file_size': uploadResult['file_size'],
          });
        }
      }

      _triggerNoticePushNotification(
        noticeId: createdNoticeId,
        title: title,
      );

      // Invalidate cache
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cached_notices_'));
      for (var k in keys) {
        await prefs.remove(k);
      }

      final fullNotice = await getNoticeById(createdNoticeId);
      return fullNotice ?? NoticeModel.fromJson(noticeData);
    } catch (e) {
      debugPrint('Error creating notice: $e');

      if (uploadedFilePaths.isNotEmpty) {
        await _storageService.deleteNoticeAttachments(uploadedFilePaths);
      }
      if (createdNoticeId != null) {
        await _supabase.from('notices').delete().eq('id', createdNoticeId);
      }

      rethrow;
    }
  }

  /// Update an existing notice
  Future<void> updateNotice({
    required String noticeId,
    required String title,
    required String content,
    required String category,
    required bool isImportant,
    String? externalUrl,
  }) async {
    try {
      await _supabase.from('notices').update({
        'title': title,
        'content': content,
        'category': category,
        'is_important': isImportant,
        'external_url': externalUrl?.trim().isEmpty == true ? null : externalUrl?.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', noticeId);

      // Invalidate cache
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cached_notices_') || k == 'cached_notice_detail_$noticeId');
      for (var k in keys) {
        await prefs.remove(k);
      }
    } catch (e) {
      debugPrint('Error updating notice ($noticeId): $e');
      rethrow;
    }
  }

  /// Delete a notice and clean up all storage attachments
  Future<void> deleteNotice(String noticeId) async {
    try {
      final attachments = await _supabase
          .from('notice_attachments')
          .select('file_path')
          .eq('notice_id', noticeId);

      final List<String> paths = (attachments as List)
          .map((a) => a['file_path']?.toString() ?? '')
          .where((p) => p.isNotEmpty)
          .toList();

      if (paths.isNotEmpty) {
        await _storageService.deleteNoticeAttachments(paths);
      }

      await _supabase.from('notices').delete().eq('id', noticeId);

      // Invalidate cache
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('cached_notices_') || k == 'cached_notice_detail_$noticeId');
      for (var k in keys) {
        await prefs.remove(k);
      }
    } catch (e) {
      debugPrint('Error deleting notice ($noticeId): $e');
      rethrow;
    }
  }

  /// Deletes a single attachment by ID and storage file path
  Future<void> deleteNoticeAttachment(String attachmentId, String filePath) async {
    try {
      await _storageService.deleteNoticeAttachments([filePath]);
      await _supabase.from('notice_attachments').delete().eq('id', attachmentId);
    } catch (e) {
      debugPrint('Error deleting attachment ($attachmentId): $e');
      rethrow;
    }
  }

  /// Uploads and adds new attachments to an existing notice
  Future<void> addNoticeAttachments({
    required String noticeId,
    required List<PlatformFile> attachmentFiles,
  }) async {
    try {
      for (var file in attachmentFiles) {
        final uploadResult = await _storageService.uploadNoticeAttachment(
          noticeId: noticeId,
          file: file,
        );

        await _supabase.from('notice_attachments').insert({
          'notice_id': noticeId,
          'file_name': uploadResult['file_name'],
          'file_path': uploadResult['file_path'],
          'file_url': uploadResult['file_url'],
          'file_type': uploadResult['file_type'],
          'file_size': uploadResult['file_size'],
        });
      }
    } catch (e) {
      debugPrint('Error adding attachments to notice ($noticeId): $e');
      rethrow;
    }
  }

  /// Triggers push notification for new college notices
  Future<void> _triggerNoticePushNotification({
    required String noticeId,
    required String title,
  }) async {
    try {
      await _supabase.functions.invoke('notice-push', body: {
        'record': {
          'id': noticeId,
          'title': title,
          'type': 'notice',
        }
      });
    } catch (e) {
      debugPrint('Failed to trigger push notification edge function: $e');
    }
  }
}
