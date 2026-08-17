import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/features/alumni/models/alumni_job_model.dart';
import 'package:igit_connects/features/alumni/models/alumni_event_model.dart';
import 'package:igit_connects/features/alumni/services/alumni_service.dart';

final alumniServiceProvider = Provider<AlumniService>((ref) {
  return AlumniService();
});

final alumniJobsProvider = FutureProvider.autoDispose<List<AlumniJob>>((ref) async {
  final service = ref.watch(alumniServiceProvider);
  return await service.fetchJobs();
});

final alumniEventsProvider = FutureProvider.autoDispose<List<AlumniEvent>>((ref) async {
  final service = ref.watch(alumniServiceProvider);
  return await service.fetchEvents(isPast: false);
});

final alumniPastEventsProvider = FutureProvider.autoDispose<List<AlumniEvent>>((ref) async {
  final service = ref.watch(alumniServiceProvider);
  return await service.fetchEvents(isPast: true);
});
