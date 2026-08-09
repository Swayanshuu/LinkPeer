class NoticePublisherModel {
  final String id;
  final String userId;
  final String createdBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined user metadata
  final String? userName;
  final String? userEmail;
  final String? userPhotoUrl;
  final String? userDesignation;

  NoticePublisherModel({
    required this.id,
    required this.userId,
    required this.createdBy,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userEmail,
    this.userPhotoUrl,
    this.userDesignation,
  });

  factory NoticePublisherModel.fromJson(Map<String, dynamic> json) {
    String? userName;
    String? userEmail;
    String? userPhotoUrl;
    String? userDesignation;

    if (json['users'] != null && json['users'] is Map) {
      final userMap = json['users'] as Map<String, dynamic>;
      userName = userMap['name']?.toString();
      userEmail = userMap['email']?.toString();
      userPhotoUrl = userMap['photo_url']?.toString();
      userDesignation = userMap['designation']?.toString() ??
          userMap['user_type']?.toString();
    }

    return NoticePublisherModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      createdBy: json['created_by']?.toString() ?? '',
      isActive: json['is_active'] == true,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? (DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      userName: userName,
      userEmail: userEmail,
      userPhotoUrl: userPhotoUrl,
      userDesignation: userDesignation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'created_by': createdBy,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
