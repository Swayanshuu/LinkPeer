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

    if (json['actor'] != null) {
      actorName = json['actor']['name'];
      actorPhotoUrl = json['actor']['photo_url'];
    }

    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      actorUserId: json['actor_user_id'],
      postId: json['post_id'] is String ? int.tryParse(json['post_id']) : json['post_id'],
      commentId: json['comment_id'] is String ? int.tryParse(json['comment_id']) : json['comment_id'],
      type: json['type'],
      title: json['title'],
      body: json['body'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
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
