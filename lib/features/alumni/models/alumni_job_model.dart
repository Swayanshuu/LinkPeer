class AlumniJob {
  final String? id;
  final String posterName;
  final String type;
  final String title;
  final String company;
  final String location;
  final String description;
  final String? salaryRange;
  final String? contactEmail;
  final String? createdAt;

  AlumniJob({
    this.id,
    required this.posterName,
    required this.type,
    required this.title,
    required this.company,
    required this.location,
    required this.description,
    this.salaryRange,
    this.contactEmail,
    this.createdAt,
  });

  factory AlumniJob.fromJson(Map<String, dynamic> json) {
    return AlumniJob(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      posterName: json['posterName']?.toString() ??
          json['postedBy']?.toString() ??
          'Alumni Member',
      type: json['type']?.toString() ?? 'Job',
      title: json['title']?.toString() ?? 'Untitled Position',
      company: json['company']?.toString() ?? 'Unknown Company',
      location: json['location']?.toString() ?? 'Remote',
      description: json['description']?.toString() ?? '',
      salaryRange: json['salaryRange']?.toString() ?? json['salary']?.toString(),
      contactEmail: json['contactEmail']?.toString() ?? json['email']?.toString(),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'posterName': posterName,
      'type': type,
      'title': title,
      'company': company,
      'location': location,
      'description': description,
      'salaryRange': salaryRange,
      'contactEmail': contactEmail,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  /// Helper to parse array or wrapper object from API
  static List<AlumniJob> fromJsonList(dynamic responseData) {
    if (responseData == null) return [];
    if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map((item) => AlumniJob.fromJson(item))
          .toList();
    }
    if (responseData is Map<String, dynamic>) {
      // Check for nested keys if applicable
      if (responseData['data'] is List) {
        return (responseData['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => AlumniJob.fromJson(item))
            .toList();
      }
      if (responseData['jobs'] is List) {
        return (responseData['jobs'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => AlumniJob.fromJson(item))
            .toList();
      }
      // Single object fallback
      return [AlumniJob.fromJson(responseData)];
    }
    return [];
  }
}
