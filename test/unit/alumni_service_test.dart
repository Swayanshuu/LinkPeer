import 'package:flutter_test/flutter_test.dart';
import 'package:igit_connects/features/alumni/services/alumni_service.dart';
import 'package:igit_connects/features/alumni/config/alumni_config.dart';

void main() {
  group('AlumniConfig Tests', () {
    test('AlumniConfig returns valid bearer token', () {
      expect(AlumniConfig.bearerToken, isNotEmpty);
      expect(AlumniConfig.bearerToken, startsWith('Bearer '));
    });

    test('AlumniConfig headers contains Authorization header', () {
      final headers = AlumniConfig.headers;
      expect(headers['Authorization'], equals(AlumniConfig.bearerToken));
      expect(headers['Content-Type'], equals('application/json'));
    });
  });

  group('AlumniService Live API Fetch Verification', () {
    final service = AlumniService();

    test('fetchJobs returns a non-null list of AlumniJob from backend', () async {
      final jobs = await service.fetchJobs();
      expect(jobs, isNotNull);
      expect(jobs, isA<List>());
      print('Fetched ${jobs.length} jobs from backend:');
      for (final job in jobs) {
        print(' - [${job.type}] ${job.title} at ${job.company} (${job.location}) by ${job.posterName}');
      }
    });

    test('fetchEvents returns a non-null list of AlumniEvent from backend', () async {
      final events = await service.fetchEvents(isPast: false);
      expect(events, isNotNull);
      expect(events, isA<List>());
      print('Fetched ${events.length} upcoming events from backend:');
      for (final event in events) {
        print(' - ${event.title} on ${event.formattedFullDate} at ${event.location}');
      }
    });

    test('fetchEvents(isPast: true) returns past events from backend', () async {
      final events = await service.fetchEvents(isPast: true);
      expect(events, isNotNull);
      expect(events, isA<List>());
      print('Fetched ${events.length} past events from backend:');
      for (final event in events) {
        print(' - [PAST] ${event.title} on ${event.formattedFullDate}');
      }
    });
  });
}
