import 'package:intl/intl.dart';

class AlumniEvent {
  final String? id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final String priority;
  final String? registrationLink;
  final String? agenda;
  final String? contactEmail;
  final String organizer;

  AlumniEvent({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.priority,
    this.registrationLink,
    this.agenda,
    this.contactEmail,
    required this.organizer,
  });

  factory AlumniEvent.fromJson(Map<String, dynamic> json) {
    return AlumniEvent(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      title: json['title']?.toString() ?? 'Untitled Event',
      description: json['description']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      time: json['time']?.toString() ?? 'TBA',
      location: json['location']?.toString() ?? 'TBA',
      priority: json['priority']?.toString() ?? 'Normal',
      registrationLink: json['registrationLink']?.toString() ??
          json['link']?.toString(),
      agenda: json['agenda']?.toString(),
      contactEmail: json['contactEmail']?.toString() ?? json['email']?.toString(),
      organizer: json['organizer']?.toString() ?? 'CSE Alumni Cell',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'location': location,
      'priority': priority,
      'registrationLink': registrationLink,
      'agenda': agenda,
      'contactEmail': contactEmail,
      'organizer': organizer,
    };
  }

  /// Formatted date day & month representation (e.g. '16 AUG')
  String get formattedDateBadge {
    if (date.isEmpty) return 'TBA';
    try {
      final parsedDate = DateTime.parse(date);
      final day = DateFormat('dd').format(parsedDate);
      final month = DateFormat('MMM').format(parsedDate).toUpperCase();
      return '$day\n$month';
    } catch (_) {
      // Fallback format if string is not ISO 8601
      return date.length > 6 ? date.substring(0, 6) : date;
    }
  }

  /// Formatted full date representation (e.g. 'Aug 16, 2026')
  String get formattedFullDate {
    if (date.isEmpty) return 'Date TBA';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('EEE, MMM d, yyyy').format(parsedDate);
    } catch (_) {
      return date;
    }
  }

  /// Helper to parse array or wrapper object from API
  static List<AlumniEvent> fromJsonList(dynamic responseData) {
    if (responseData == null) return [];
    if (responseData is List) {
      return responseData
          .whereType<Map<String, dynamic>>()
          .map((item) => AlumniEvent.fromJson(item))
          .toList();
    }
    if (responseData is Map<String, dynamic>) {
      if (responseData['data'] is List) {
        return (responseData['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => AlumniEvent.fromJson(item))
            .toList();
      }
      if (responseData['events'] is List) {
        return (responseData['events'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => AlumniEvent.fromJson(item))
            .toList();
      }
      return [AlumniEvent.fromJson(responseData)];
    }
    return [];
  }
}
