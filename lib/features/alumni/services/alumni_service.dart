import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Read cached alumni jobs immediately for instant UI display
  Future<List<AlumniJob>> getCachedJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_alumni_jobs');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final decoded = jsonDecode(cachedStr);
        final jobs = AlumniJob.fromJsonList(decoded);
        jobs.sort((a, b) {
          if (a.createdAt != null && b.createdAt != null) {
            try {
              final dateA = DateTime.parse(a.createdAt!);
              final dateB = DateTime.parse(b.createdAt!);
              return dateB.compareTo(dateA);
            } catch (_) {}
          }
          if (a.id != null && b.id != null) {
            return b.id!.compareTo(a.id!);
          }
          return 0;
        });
        return jobs;
      }
    } catch (e) {
      debugPrint('Cache read error for alumni jobs: $e');
    }
    return [];
  }

  /// Read cached alumni events immediately for instant UI display
  Future<List<AlumniEvent>> getCachedEvents({bool isPast = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_alumni_events');
      if (cachedStr != null && cachedStr.isNotEmpty) {
        final decoded = jsonDecode(cachedStr);
        final events = AlumniEvent.fromJsonList(decoded);
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final filtered = events.where((e) {
          if (e.date.isEmpty) return !isPast;
          try {
            final eventDate = DateTime.parse(e.date);
            return isPast ? eventDate.isBefore(todayStart) : !eventDate.isBefore(todayStart);
          } catch (_) {
            return !isPast;
          }
        }).toList();

        filtered.sort((a, b) {
          if (a.date.isNotEmpty && b.date.isNotEmpty) {
            try {
              final dateA = DateTime.parse(a.date);
              final dateB = DateTime.parse(b.date);
              return isPast ? dateB.compareTo(dateA) : dateA.compareTo(dateB);
            } catch (_) {}
          }
          return 0;
        });
        return filtered;
      }
    } catch (e) {
      debugPrint('Cache read error for alumni events: $e');
    }
    return [];
  }

  /// Fetch all alumni jobs & internships with cache persistence and offline fallback
  Future<List<AlumniJob>> fetchJobs() async {
    final candidateEndpoints = [
      AlumniConfig.jobEndpoint,
      '${AlumniConfig.baseUrl}/jobs',
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
          
          // Persist to local cache for instant load
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_alumni_jobs', response.body);
          } catch (e) {
            debugPrint('Cache write error for alumni jobs: $e');
          }

          // Sort most recent jobs first (by createdAt descending or id descending)
          jobs.sort((a, b) {
            if (a.createdAt != null && b.createdAt != null) {
              try {
                final dateA = DateTime.parse(a.createdAt!);
                final dateB = DateTime.parse(b.createdAt!);
                return dateB.compareTo(dateA);
              } catch (_) {}
            }
            if (a.id != null && b.id != null) {
              return b.id!.compareTo(a.id!);
            }
            return 0;
          });
          return jobs;
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
        lastException = AlumniApiException(
          'No internet connection. Please check your network and try again.',
        );
      } on FormatException catch (e) {
        debugPrint('JSON Format Error in Jobs API ($url): $e');
      } catch (e) {
        debugPrint('Error fetching jobs from ($url): $e');
      }
    }

    // Attempt cache fallback if network request fails or times out
    final cached = await getCachedJobs();
    if (cached.isNotEmpty) {
      debugPrint('Returning ${cached.length} cached alumni jobs fallback');
      return cached;
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

  /// Fetch alumni events (Upcoming or Past) with cache persistence and offline fallback
  Future<List<AlumniEvent>> fetchEvents({bool isPast = false}) async {
    final candidateEndpoints = [
      AlumniConfig.eventEndpoint,
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

          // Persist to local cache for instant load
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('cached_alumni_events', response.body);
          } catch (e) {
            debugPrint('Cache write error for alumni events: $e');
          }

          if (url == AlumniConfig.eventEndpoint) {
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final filtered = events.where((e) {
              if (e.date.isEmpty) return !isPast;
              try {
                final eventDate = DateTime.parse(e.date);
                if (isPast) {
                  return eventDate.isBefore(todayStart);
                } else {
                  return !eventDate.isBefore(todayStart);
                }
              } catch (_) {
                return !isPast;
              }
            }).toList();

            filtered.sort((a, b) {
              if (a.date.isNotEmpty && b.date.isNotEmpty) {
                try {
                  final dateA = DateTime.parse(a.date);
                  final dateB = DateTime.parse(b.date);
                  return isPast
                      ? dateB.compareTo(dateA)
                      : dateA.compareTo(dateB);
                } catch (_) {}
              }
              return 0;
            });

            return filtered;
          }

          return events;
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
        lastException = AlumniApiException(
          'No internet connection. Please check your network and try again.',
        );
      } on FormatException catch (e) {
        debugPrint('JSON Format Error in Events API ($url): $e');
      } catch (e) {
        debugPrint('Error fetching events from ($url): $e');
      }
    }

    // Attempt cache fallback if network request fails or times out
    final cached = await getCachedEvents(isPast: isPast);
    if (cached.isNotEmpty) {
      debugPrint('Returning ${cached.length} cached alumni events fallback');
      return cached;
    }

    if (lastException != null) throw lastException;
    return [];
  }
}
