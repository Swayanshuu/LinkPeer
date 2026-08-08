class NotificationModel {
  final String id;
  final String userId;
  final String? actorUserId;
  final int? postId;
  final int? commentId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;

  // Additional fields fetched via joins
  final String? actorName;
  final String? actorPhotoUrl;

  NotificationModel({
    required this.id,
    required this.userId,
    this.actorUserId,
    this.postId,
    this.commentId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.actorName,
    this.actorPhotoUrl,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Parse actor information if joined from users table
    String? actorName;
    String? actorPhotoUrl;

    if (json['actor'] != null && json['actor'] is Map) {
      actorName = json['actor']['name']?.toString();
      actorPhotoUrl = json['actor']['photo_url']?.toString();
    }

    return NotificationModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      actorUserId: json['actor_user_id']?.toString(),
      postId: json['post_id'] is String
          ? int.tryParse(json['post_id'])
          : (json['post_id'] as int?),
      commentId: json['comment_id'] is String
          ? int.tryParse(json['comment_id'])
          : (json['comment_id'] as int?),
      type: json['type']?.toString() ?? 'SYSTEM',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      actorName: actorName,
      actorPhotoUrl: actorPhotoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'actor_user_id': actorUserId,
      'post_id': postId,
      'comment_id': commentId,
      'type': type,
      'title': title,
      'body': body,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
