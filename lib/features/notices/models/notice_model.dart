import 'package:igit_connects/features/notices/models/notice_attachment_model.dart';
import 'package:intl/intl.dart';

class NoticeModel {
  final String id;
  final String title;
  final String content;
  final String category;
  final String publisherId;
  final bool isImportant;
  final String? externalUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined publisher fields
  final String? publisherName;
  final String? publisherPhotoUrl;
  final String? publisherDesignation;
  final String? publisherUserType;
  final String? publisherDepartment;
  final String? publisherBranch;
  final String? publisherRole;

  // Attached files
  final List<NoticeAttachmentModel> attachments;

  NoticeModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.publisherId,
    required this.isImportant,
    this.externalUrl,
    required this.createdAt,
    required this.updatedAt,
    this.publisherName,
    this.publisherPhotoUrl,
    this.publisherDesignation,
    this.publisherUserType,
    this.publisherDepartment,
    this.publisherBranch,
    this.publisherRole,
    this.attachments = const [],
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    String? pubName;
    String? pubPhoto;
    String? pubDesig;
    String? pubType;
    String? pubDept;
    String? pubBranch;
    String? pubRole;

    if (json['publisher'] != null && json['publisher'] is Map) {
      final p = json['publisher'] as Map<String, dynamic>;
      pubName = p['name']?.toString();
      pubPhoto = p['photo_url']?.toString();
      pubDesig = p['designation']?.toString();
      pubType = p['user_type']?.toString();
      pubDept = p['department']?.toString();
      pubBranch = p['branch']?.toString();
      pubRole = p['role']?.toString();
    } else if (json['users'] != null && json['users'] is Map) {
      final p = json['users'] as Map<String, dynamic>;
      pubName = p['name']?.toString();
      pubPhoto = p['photo_url']?.toString();
      pubDesig = p['designation']?.toString();
      pubType = p['user_type']?.toString();
      pubDept = p['department']?.toString();
      pubBranch = p['branch']?.toString();
      pubRole = p['role']?.toString();
    }

    List<NoticeAttachmentModel> attachList = [];
    if (json['notice_attachments'] != null && json['notice_attachments'] is List) {
      attachList = (json['notice_attachments'] as List)
          .map((item) => NoticeAttachmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return NoticeModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      publisherId: json['publisher_id']?.toString() ?? '',
      isImportant: json['is_important'] == true,
      externalUrl: json['external_url']?.toString(),
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      publisherName: pubName ?? 'College Notice Board',
      publisherPhotoUrl: pubPhoto,
      publisherDesignation: pubDesig,
      publisherUserType: pubType,
      publisherDepartment: pubDept,
      publisherBranch: pubBranch,
      publisherRole: pubRole,
      attachments: attachList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'publisher_id': publisherId,
      'is_important': isImportant,
      'external_url': externalUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Formatted date string (e.g. 09 Aug 2026)
  String get formattedDate {
    return DateFormat('dd MMM yyyy').format(createdAt);
  }

  /// Formatted time string (e.g. 02:30 PM)
  String get formattedTime {
    return DateFormat('hh:mm a').format(createdAt);
  }

  /// Combined formatted display date/time
  String get formattedDateTime {
    return '$formattedDate, $formattedTime';
  }

  /// Composite publisher tag e.g. "Dean Academics" or "Faculty • CSE"
  String get publisherSubtitle {
    if (publisherDesignation != null && publisherDesignation!.isNotEmpty) {
      if (publisherDepartment != null && publisherDepartment!.isNotEmpty) {
        return '$publisherDesignation • $publisherDepartment';
      }
      return publisherDesignation!;
    }
    if (publisherUserType != null && publisherUserType!.isNotEmpty) {
      return publisherUserType!;
    }
    return 'Authorized Publisher';
  }
}
