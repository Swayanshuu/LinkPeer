import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AlumniConfig {
  static const String _defaultUrlB64 =
      'aHR0cHM6Ly9jc2UtYWx1bW5pLWJhY2tlbmQtbGw4OC5vbnJlbmRlci5jb20vYXBpL2FsdW1uaS9leHRlcm5hbA==';
  static const String _defaultTokenB64 =
      'bWlsYW5fY3NlX3NlY3VyZV9zeW5jX2tleV83NzA3Nw==';

  static String get baseUrl {
    final envUrl = dotenv.env['ALUMNI_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    return utf8.decode(base64.decode(_defaultUrlB64));
  }

  static String get jobEndpoint => '$baseUrl/job';
  static String get eventEndpoint => '$baseUrl/event';

  // Get Bearer Token from secure .env configuration
  static String get bearerToken {
    final token = dotenv.env['ALUMNI_BEARER_TOKEN'];
    final rawToken = (token != null && token.isNotEmpty)
        ? token
        : utf8.decode(base64.decode(_defaultTokenB64));
    return rawToken.startsWith('Bearer ') ? rawToken : 'Bearer $rawToken';
  }

  // Default HTTP headers
  static Map<String, String> get headers => {
        'Authorization': bearerToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
}
