class NoticeAttachmentModel {
  final String id;
  final String noticeId;
  final String fileName;
  final String filePath;
  final String fileUrl;
  final String fileType;
  final int fileSize;
  final DateTime createdAt;

  NoticeAttachmentModel({
    required this.id,
    required this.noticeId,
    required this.fileName,
    required this.filePath,
    required this.fileUrl,
    required this.fileType,
    required this.fileSize,
    required this.createdAt,
  });

  factory NoticeAttachmentModel.fromJson(Map<String, dynamic> json) {
    return NoticeAttachmentModel(
      id: json['id']?.toString() ?? '',
      noticeId: json['notice_id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? 'Attachment',
      filePath: json['file_path']?.toString() ?? '',
      fileUrl: json['file_url']?.toString() ?? '',
      fileType: json['file_type']?.toString().toLowerCase() ?? 'file',
      fileSize: json['file_size'] is int
          ? json['file_size'] as int
          : int.tryParse(json['file_size']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notice_id': noticeId,
      'file_name': fileName,
      'file_path': filePath,
      'file_url': fileUrl,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      final kb = (fileSize / 1024).toStringAsFixed(1);
      return '$kb KB';
    } else {
      final mb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      return '$mb MB';
    }
  }
}
