class UpdateModel {
  final int latestVersionCode;
  final String latestVersion;
  final String playStoreUrl;
  final String title;
  final String message;
  final String releaseDate;
  final List<String> features;

  UpdateModel({
    required this.latestVersionCode,
    required this.latestVersion,
    required this.playStoreUrl,
    required this.title,
    required this.message,
    required this.releaseDate,
    required this.features,
  });

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    return UpdateModel(
      latestVersionCode: json['latestVersionCode'] ?? 0,
      latestVersion: json['latestVersion'] ?? '',
      playStoreUrl: json['playStoreUrl'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      releaseDate: json['releaseDate'] ?? '',
      features: List<String>.from(json['features'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latestVersionCode': latestVersionCode,
      'latestVersion': latestVersion,
      'playStoreUrl': playStoreUrl,
      'title': title,
      'message': message,
      'releaseDate': releaseDate,
      'features': features,
    };
  }
}
