import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:igit_connects/features/alumni/config/alumni_config.dart';
import 'package:igit_connects/features/alumni/models/alumni_job_model.dart';
import 'package:igit_connects/features/alumni/models/alumni_event_model.dart';

class AlumniApiException implements Exception {
  final String message;
  final int? statusCode;

  AlumniApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AlumniService {
  final http.Client _client;

  AlumniService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch all alumni jobs & internships purely from backend endpoints
  Future<List<AlumniJob>> fetchJobs() async {
    final candidateEndpoints = [
      AlumniConfig.jobEndpoint,
      '${AlumniConfig.baseUrl}/jobs',
      'https://cse-alumni-backend-ll88.onrender.com/api/jobs',
      'https://cse-alumni-backend-ll88.onrender.com/api/projects/all',
    ];

    AlumniApiException? lastException;

    for (final url in candidateEndpoints) {
      try {
        final uri = Uri.parse(url);
        debugPrint('Fetching Alumni Jobs from: $uri');

        final response = await _client
            .get(uri, headers: AlumniConfig.headers)
            .timeout(const Duration(seconds: 12));

        debugPrint('Alumni Jobs API ($url) Response Code: ${response.statusCode}');

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final jobs = AlumniJob.fromJsonList(decoded);
          if (jobs.isNotEmpty || url == candidateEndpoints.last) {
            return jobs;
          }
        } else if (response.statusCode == 401 && url == candidateEndpoints.first) {
          lastException = AlumniApiException(
            'Unauthorized access. Please check key configuration.',
            statusCode: 401,
          );
        }
      } on TimeoutException {
        lastException = AlumniApiException(
          'Backend server response timed out. The server on Render may be waking up, please tap retry.',
        );
      } on SocketException {
        throw AlumniApiException(
          'No internet connection. Please check your network and try again.',
        );
      } on FormatException catch (e) {
        debugPrint('JSON Format Error in Jobs API ($url): $e');
      } catch (e) {
        debugPrint('Error fetching jobs from ($url): $e');
      }
    }

    if (lastException != null) throw lastException;
    return [];
  }

  /// Post a new job or internship opportunity to the portal
  Future<bool> postJob({
    required String posterName,
    required String type,
    required String title,
    required String company,
    required String location,
    required String description,
    required String salaryRange,
    required String contactEmail,
  }) async {
    try {
      final uri = Uri.parse(AlumniConfig.jobEndpoint);
      debugPrint('Posting job to: $uri');

      final body = jsonEncode({
        'posterName': posterName,
        'type': type,
        'title': title,
        'company': company,
        'location': location,
        'description': description,
        'salaryRange': salaryRange,
        'contactEmail': contactEmail,
      });

      final response = await _client
          .post(
            uri,
            headers: AlumniConfig.headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Post Job API Response (${response.statusCode}): ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw AlumniApiException(
          'Failed to post job. Server returned status ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      throw AlumniApiException('Connection timed out while posting job.');
    } on SocketException {
      throw AlumniApiException('No internet connection. Please check your network.');
    } catch (e) {
      if (e is AlumniApiException) rethrow;
      throw AlumniApiException('Failed to post job: $e');
    }
  }

  /// Fetch alumni events (Upcoming or Past) purely from backend endpoints
  Future<List<AlumniEvent>> fetchEvents({bool isPast = false}) async {
    final candidateEndpoints = isPast
        ? [
            'https://cse-alumni-backend-ll88.onrender.com/api/events/past',
            '${AlumniConfig.baseUrl}/events/past',
          ]
        : [
            'https://cse-alumni-backend-ll88.onrender.com/api/events/upcoming',
            AlumniConfig.eventEndpoint,
            'https://cse-alumni-backend-ll88.onrender.com/api/events',
            '${AlumniConfig.baseUrl}/events',
          ];

    AlumniApiException? lastException;

    for (final url in candidateEndpoints) {
      try {
        final uri = Uri.parse(url);
        debugPrint('Fetching Alumni Events (isPast: $isPast) from: $uri');

        final response = await _client
            .get(uri, headers: AlumniConfig.headers)
            .timeout(const Duration(seconds: 12));

        debugPrint('Alumni Events API ($url) Response Code: ${response.statusCode}');

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final events = AlumniEvent.fromJsonList(decoded);
          if (events.isNotEmpty || url == candidateEndpoints.last) {
            return events;
          }
        } else if (response.statusCode == 401 && url == candidateEndpoints.first) {
          lastException = AlumniApiException(
            'Unauthorized access. Please check key configuration.',
            statusCode: 401,
          );
        }
      } on TimeoutException {
        lastException = AlumniApiException(
          'Backend server response timed out. The server on Render may be waking up, please tap retry.',
        );
      } on SocketException {
        throw AlumniApiException(
          'No internet connection. Please check your network and try again.',
        );
      } on FormatException catch (e) {
        debugPrint('JSON Format Error in Events API ($url): $e');
      } catch (e) {
        debugPrint('Error fetching events from ($url): $e');
      }
    }

    if (lastException != null) throw lastException;
    return [];
  }
}
