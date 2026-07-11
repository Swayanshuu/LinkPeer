class DeveloperProfileModel {
  final String name;
  final String imageUrl;
  final String portfolio;
  final String website;
  final String github;
  final String linkedin;
  final String instagram;
  final String x;
  final String email;

  DeveloperProfileModel({
    required this.name,
    required this.imageUrl,
    required this.portfolio,
    required this.website,
    required this.github,
    required this.linkedin,
    required this.instagram,
    required this.x,
    required this.email,
  });

  factory DeveloperProfileModel.fromJson(Map<String, dynamic> json) {
    return DeveloperProfileModel(
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      portfolio: json['portfolio'] ?? '',
      website: json['website'] ?? '',
      github: json['github'] ?? '',
      linkedin: json['linkedin'] ?? '',
      instagram: json['instagram'] ?? '',
      x: json['x'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'portfolio': portfolio,
      'website': website,
      'github': github,
      'linkedin': linkedin,
      'instagram': instagram,
      'x': x,
      'email': email,
    };
  }
}
