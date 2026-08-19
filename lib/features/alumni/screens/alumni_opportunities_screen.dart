import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/features/alumni/models/alumni_job_model.dart';
import 'package:igit_connects/features/alumni/models/alumni_event_model.dart';
import 'package:igit_connects/features/alumni/providers/alumni_provider.dart';
import 'package:igit_connects/features/alumni/screens/jobs_list_screen.dart';
import 'package:igit_connects/features/alumni/screens/events_list_screen.dart';
import 'package:igit_connects/features/alumni/screens/job_details_screen.dart';
import 'package:igit_connects/features/alumni/screens/event_details_screen.dart';
import 'package:igit_connects/shared_components/banner_ad_widget.dart';
import 'package:igit_connects/shared_components/custom_snackbar.dart';

class AlumniOpportunitiesScreen extends ConsumerWidget {
  const AlumniOpportunitiesScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            message: 'Could not launch link: $urlString',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: 'Unable to open website: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final jobsAsync = ref.watch(alumniJobsProvider);
    final eventsAsync = ref.watch(alumniEventsProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: colors.borderColor.withValues(alpha: 0.5),
            height: 1.0,
          ),
        ),
        title: Text(
          'Alumni Network',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildFeaturedPartnersRow(context, colors),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: colors.primaryAccent,
                backgroundColor: colors.cardColor,
                onRefresh: () async {
                  ref.invalidate(alumniJobsProvider);
                  ref.invalidate(alumniEventsProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Hero Card
                      _buildHeroBanner(context, colors),

                      const SizedBox(height: 20),

                      // Real Data Metric Counters Bar
                      _buildMetricsBar(colors, jobsAsync, eventsAsync),

                      const SizedBox(height: 24),

                      Text(
                        'EXPLORE CATEGORIES',
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Category 1 — Jobs & Internships Card
                      _buildCategoryCard(
                        context: context,
                        colors: colors,
                        title: 'Jobs & Internships',
                        description:
                            'Browse opportunities shared by alumni members.',
                        icon: Icons.work_outline_rounded,
                        accentColor: colors.categoryJob,
                        count: jobsAsync.when(
                          data: (jobs) => '${jobs.length}',
                          loading: () => '...',
                          error: (err, stack) => null,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const JobsListScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 14),

                      // Category 2 — Alumni Events Card
                      _buildCategoryCard(
                        context: context,
                        colors: colors,
                        title: 'Alumni Events',
                        description:
                            'Discover upcoming meetups, webinars, and reunions.',
                        icon: Icons.event_note_rounded,
                        accentColor: colors.categoryInternship,
                        count: eventsAsync.when(
                          data: (events) => '${events.length}',
                          loading: () => '...',
                          error: (err, stack) => null,
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const EventsListScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Live Spotlight Preview Sections (Only when real data exists)
                      jobsAsync.when(
                        data: (jobs) {
                          if (jobs.isEmpty) return const SizedBox.shrink();
                          final latestJob = jobs.first;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                colors,
                                title: 'LATEST OPPORTUNITY',
                                actionLabel: 'View All',
                                onAction: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const JobsListScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _buildLatestJobSpotlight(context, colors, latestJob),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),

                      eventsAsync.when(
                        data: (events) {
                          if (events.isEmpty) return const SizedBox.shrink();
                          final latestEvent = events.first;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader(
                                colors,
                                title: 'UPCOMING EVENT HIGHLIGHT',
                                actionLabel: 'View All',
                                onAction: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const EventsListScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              _buildLatestEventSpotlight(context, colors, latestEvent),
                              const SizedBox(height: 24),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (err, stack) => const SizedBox.shrink(),
                      ),

                      // Official Web Portal Link Button
                      _buildPortalCard(context, colors),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // Sticky Banner Ad above bottom navigation bar
            Container(
              width: double.infinity,
              color: colors.bgColor,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const BannerAdWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.primaryAccent.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: colors.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IGIT CSE Alumni Cell',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Official Sync Active',
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Connect directly with verified alumni for career mentorship, job referrals, internships, and official department events.',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsBar(
    AppColors colors,
    AsyncValue<List<AlumniJob>> jobsAsync,
    AsyncValue<List<AlumniEvent>> eventsAsync,
  ) {
    final jobsCount = jobsAsync.when(
      data: (jobs) => '${jobs.length}',
      loading: () => '...',
      error: (err, stack) => '0',
    );

    final eventsCount = eventsAsync.when(
      data: (events) => '${events.length}',
      loading: () => '...',
      error: (err, stack) => '0',
    );

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            colors,
            label: 'Active Listings',
            value: jobsCount,
            icon: Icons.work_history_outlined,
            accentColor: colors.categoryJob,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricTile(
            colors,
            label: 'Upcoming Events',
            value: eventsCount,
            icon: Icons.event_available_outlined,
            accentColor: colors.categoryInternship,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    AppColors colors, {
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required BuildContext context,
    required AppColors colors,
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    String? count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: colors.cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: accentColor.withValues(alpha: 0.1),
        highlightColor: accentColor.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.borderColor.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (count != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              count,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.secondaryText.withValues(alpha: 0.7),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    AppColors colors, {
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        InkWell(
          onTap: onAction,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              actionLabel,
              style: TextStyle(
                color: colors.primaryAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLatestJobSpotlight(
    BuildContext context,
    AppColors colors,
    AlumniJob job,
  ) {
    final isInternship = job.type.toLowerCase().contains('intern');
    final badgeColor = isInternship ? colors.categoryInternship : colors.categoryJob;

    return Material(
      color: colors.cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => JobDetailsScreen(job: job),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.borderColor.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      job.type,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${job.company} • ${job.location}',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLatestEventSpotlight(
    BuildContext context,
    AppColors colors,
    AlumniEvent event,
  ) {
    return Material(
      color: colors.cardColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EventDetailsScreen(event: event),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.borderColor.withValues(alpha: 0.8),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  event.formattedDateBadge,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.primaryAccent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${event.time} • ${event.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.primaryAccent,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedPartnersRow(BuildContext context, AppColors colors) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.borderColor.withValues(alpha: 0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () =>
                  _launchUrl(context, 'https://hellomelo.netlify.app/'),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  ).createShader(bounds),
                  child: const Text(
                    'MELO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              ' × ',
              style: TextStyle(
                color: colors.secondaryText.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
            InkWell(
              onTap: () => _launchUrl(context, 'https://swynx.dev'),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                child: ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ).createShader(bounds),
                  child: const Text(
                    'SWYNX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalCard(BuildContext context, AppColors colors) {
    return Material(
      color: colors.primaryAccent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _launchUrl(context, 'https://cse.igitalumni.in/'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.primaryAccent.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.language_rounded,
                  color: colors.primaryAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visit Alumni Website of IGIT CSEA',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'https://cse.igitalumni.in/',
                      style: TextStyle(
                        color: colors.primaryAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                color: colors.primaryAccent,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

