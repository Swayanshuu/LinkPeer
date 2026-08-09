import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:igit_connects/features/notices/config/notice_config.dart';

class NoticeStorageService {
  final _supabase = Supabase.instance.client;
  static const String bucketName = 'notices';

  /// Picks multiple attachment files using [FilePicker] with size and count checks
  Future<List<PlatformFile>> pickNoticeAttachments() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    return result.files;
  }

  /// Validates a list of platform files against max size and max count limits
  /// Returns null if valid, or an error message if invalid.
  String? validateAttachments(List<PlatformFile> files) {
    if (files.length > NoticeConfig.maxNoticeAttachments) {
      return 'Maximum ${NoticeConfig.maxNoticeAttachments} attachments allowed per notice.';
    }

    for (var file in files) {
      if (file.size > NoticeConfig.maxNoticeFileSize) {
        return 'File "${file.name}" is too large. Maximum allowed size is ${NoticeConfig.maxNoticeFileSizeFormatted}.';
      }
    }

    return null;
  }

  /// Uploads a single attachment to `notices/{noticeId}/{filename}` in Supabase Storage
  Future<Map<String, dynamic>> uploadNoticeAttachment({
    required String noticeId,
    required PlatformFile file,
  }) async {
    try {
      if (file.size > NoticeConfig.maxNoticeFileSize) {
        throw Exception(
          'File "${file.name}" is too large. Maximum allowed size is ${NoticeConfig.maxNoticeFileSizeFormatted}.',
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanFileName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = '$noticeId/${timestamp}_$cleanFileName';

      final String fileExt = file.extension?.toLowerCase() ?? 'bin';

      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('File bytes missing for web upload');
        }
        await _supabase.storage.from(bucketName).uploadBinary(
              path,
              file.bytes!,
              fileOptions: FileOptions(
                contentType: _getMimeType(fileExt),
                upsert: true,
              ),
            );
      } else {
        if (file.path == null) {
          throw Exception('File path missing for upload');
        }
        final ioFile = File(file.path!);
        await _supabase.storage.from(bucketName).upload(
              path,
              ioFile,
              fileOptions: FileOptions(
                contentType: _getMimeType(fileExt),
                upsert: true,
              ),
            );
      }

      final publicUrl = _supabase.storage.from(bucketName).getPublicUrl(path);

      return {
        'file_name': file.name,
        'file_path': path,
        'file_url': publicUrl,
        'file_type': fileExt,
        'file_size': file.size,
      };
    } catch (e) {
      debugPrint('Error uploading notice attachment: $e');
      rethrow;
    }
  }

  /// Delete attachment files for a specific notice from storage
  Future<void> deleteNoticeAttachments(List<String> filePaths) async {
    if (filePaths.isEmpty) return;
    try {
      await _supabase.storage.from(bucketName).remove(filePaths);
      debugPrint('Successfully removed storage files: $filePaths');
    } catch (e) {
      debugPrint('Error removing storage files for notice: $e');
    }
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'zip':
        return 'application/zip';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
