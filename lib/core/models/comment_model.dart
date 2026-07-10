class CommentModel {
  final int id;
  final int postId;
  final String userId;
  final String commentText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likesCount;
  final List<String> likedBy;

  // Joined user info
  final String userName;
  final String userPhoto;
  final bool isVerified;
  final bool isFacultyVerified;
  final String userType;
  final String
  role; // Assuming role acts like User Type or Designation from requirements

  CommentModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.commentText,
    required this.createdAt,
    required this.updatedAt,
    this.likesCount = 0,
    this.likedBy = const [],
    required this.userName,
    required this.userPhoto,
    required this.isVerified,
    required this.isFacultyVerified,
    required this.userType,
    required this.role,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    // Parse the joined user data
    final userMap = json['users'] as Map<String, dynamic>? ?? {};

    return CommentModel(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      userId: json['user_id'] as String,
      commentText: json['comment_text'] as String,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
      likesCount: json['likes_count'] as int? ?? 0,
      likedBy: List<String>.from(json['liked_by'] ?? []),
      userName: userMap['name'] as String? ?? 'Unknown User',
      userPhoto: userMap['photo_url'] as String? ?? '',
      isVerified: userMap['is_verified'] as bool? ?? false,
      isFacultyVerified: userMap['faculty_verified'] as bool? ?? false,
      userType: userMap['user_type'] as String? ?? 'user',
      role: userMap['role'] as String? ?? 'User',
    );
  }

  static DateTime _parseDateTime(dynamic dateStr) {
    if (dateStr == null) return DateTime.now();
    String s = dateStr.toString();
    // If the database returns TIMESTAMP WITHOUT TIME ZONE, it lacks 'Z'
    // By appending 'Z', Dart knows it is UTC, then we convert to local time
    if (!s.endsWith('Z') && !s.contains('+') && !s.contains('-') ||
        (s.contains('-') && s.split('-').length == 3)) {
      // Basic check to see if it's just a date-time without timezone offset
      if (!s.endsWith('Z') &&
          s.length > 10 &&
          !s.substring(10).contains('+') &&
          !s.substring(10).contains('-')) {
        s += 'Z';
      }
    }
    return DateTime.parse(s).toLocal();
  }

  CommentModel copyWith({int? likesCount, List<String>? likedBy}) {
    return CommentModel(
      id: id,
      postId: postId,
      userId: userId,
      commentText: commentText,
      createdAt: createdAt,
      updatedAt: updatedAt,
      likesCount: likesCount ?? this.likesCount,
      likedBy: likedBy ?? this.likedBy,
      userName: userName,
      userPhoto: userPhoto,
      isVerified: isVerified,
      isFacultyVerified: isFacultyVerified,
      userType: userType,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'comment_text': commentText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
