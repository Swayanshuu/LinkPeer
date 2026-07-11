class BroadcastModel {
  final String id;
  final String title;
  final String message;
  final String? imageUrl;
  final String? linkUrl;
  final String audience;
  final String createdBy;
  final DateTime createdAt;

  BroadcastModel({
    required this.id,
    required this.title,
    required this.message,
    this.imageUrl,
    this.linkUrl,
    required this.audience,
    required this.createdBy,
    required this.createdAt,
  });

  factory BroadcastModel.fromJson(Map<String, dynamic> json) {
    return BroadcastModel(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      imageUrl: json['image_url'] as String?,
      linkUrl: json['link_url'] as String?,
      audience: json['audience'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'audience': audience,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
