import 'package:flutter_dotenv/flutter_dotenv.dart';

class AlumniConfig {
  static const String baseUrl =
      'https://cse-alumni-backend-ll88.onrender.com/api/alumni/external';

  static const String jobEndpoint = '$baseUrl/job';
  static const String eventEndpoint = '$baseUrl/event';

  // Get Bearer Token from secure .env configuration
  static String get bearerToken {
    final token = dotenv.env['ALUMNI_BEARER_TOKEN'] ?? '';
    if (token.isEmpty) {
      return '';
    }
    return token.startsWith('Bearer ') ? token : 'Bearer $token';
  }

  // Default HTTP headers
  static Map<String, String> get headers => {
    'Authorization': bearerToken,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
