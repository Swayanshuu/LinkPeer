import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/features/alumni/providers/alumni_provider.dart';
import 'package:igit_connects/features/alumni/screens/jobs_list_screen.dart';
import 'package:igit_connects/features/alumni/screens/events_list_screen.dart';
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
          'Alumni Opportunities',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 17,
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colors.primaryAccent.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primaryAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            color: colors.primaryAccent,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'CSE Alumni Network',
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Connect with alumni network to discover career pathways, job vacancies, internships, and exclusive offline/online events.',
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'EXPLORE CATEGORIES',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 12),

              // Option 1 — Jobs & Internships Card
              _buildCategoryCard(
                context: context,
                colors: colors,
                title: 'Jobs & Internships',
                description:
                    'Explore job and internship opportunities shared by our alumni.',
                icon: Icons.work_outline_rounded,
                accentColor: colors.categoryJob,
                count: jobsAsync.when(
                  data: (jobs) => jobs.isNotEmpty ? '${jobs.length}' : null,
                  loading: () => null,
                  error: (err, stack) => null,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const JobsListScreen()),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Option 2 — Alumni Events Card
              _buildCategoryCard(
                context: context,
                colors: colors,
                title: 'Alumni Events',
                description:
                    'Discover upcoming events, meetups, and activities from the alumni community.',
                icon: Icons.event_note_rounded,
                accentColor: colors.categoryInternship,
                count: eventsAsync.when(
                  data: (events) =>
                      events.isNotEmpty ? '${events.length}' : null,
                  loading: () => null,
                  error: (err, stack) => null,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EventsListScreen()),
                  );
                },
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
              // Icon Container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 16),

              // Title and Description
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
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Navigation Arrow Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: colors.secondaryText.withValues(alpha: 0.7),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
