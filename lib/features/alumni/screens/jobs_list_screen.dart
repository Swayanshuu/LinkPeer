import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/features/alumni/models/alumni_job_model.dart';
import 'package:igit_connects/features/alumni/providers/alumni_provider.dart';
import 'package:igit_connects/features/alumni/screens/job_details_screen.dart';
import 'package:igit_connects/shared_components/custom_snackbar.dart';

class JobsListScreen extends ConsumerWidget {
  const JobsListScreen({super.key});

  Future<void> _postJobWebPortal(BuildContext context) async {
    final Uri uri = Uri.parse('https://cse.igitalumni.in/careers');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            message: 'Could not launch website: https://cse.igitalumni.in/careers',
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

  Future<void> _applyToJob(BuildContext context, AlumniJob job) async {
    final email = (job.contactEmail != null && job.contactEmail!.trim().isNotEmpty)
        ? job.contactEmail!.trim()
        : 'alumni@igitalumni.in';
    final subject = 'Application for ${job.title} via Alumni Network';

    final String mailtoUrl =
        'mailto:$email?subject=${Uri.encodeComponent(subject)}';
    final Uri mailtoUri = Uri.parse(mailtoUrl);

    try {
      final bool launched = await launchUrl(
        mailtoUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return;
    } catch (_) {}

    try {
      final bool launchedDefault = await launchUrl(mailtoUri);
      if (launchedDefault) return;
    } catch (_) {}

    // Fallback: Launch Gmail web composer matching web portal behavior
    try {
      final Uri gmailWebUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm&fs=1&tf=cm&source=mailto&to=${Uri.encodeComponent(email)}&su=${Uri.encodeComponent(subject)}',
      );
      await launchUrl(gmailWebUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: 'Unable to open mail app for $email',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final jobsAsync = ref.watch(alumniJobsProvider);

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.primaryText, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Jobs & Internships',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _postJobWebPortal(context),
        backgroundColor: colors.primaryAccent,
        foregroundColor: colors.onPrimaryAccent,
        elevation: 3,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Post Job/Project',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: colors.primaryAccent,
        backgroundColor: colors.cardColor,
        onRefresh: () async {
          return ref.refresh(alumniJobsProvider.future);
        },
        child: jobsAsync.when(
          data: (jobs) {
            if (jobs.isEmpty) {
              return _buildEmptyState(context, colors, ref);
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
              itemCount: jobs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final job = jobs[index];
                return _buildJobCard(context, colors, job);
              },
            );
          },
          loading: () => _buildShimmerLoading(colors),
          error: (error, stackTrace) => _buildErrorState(context, colors, ref, error),
        ),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, AppColors colors, AlumniJob job) {
    final isInternship = job.type.toLowerCase().contains('intern');
    final badgeBg = isInternship
        ? colors.categoryInternship.withValues(alpha: 0.12)
        : colors.categoryJob.withValues(alpha: 0.12);
    final badgeText = isInternship ? colors.categoryInternship : colors.categoryJob;

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
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Type Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      job.type,
                      style: TextStyle(
                        color: badgeText,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Company
              Row(
                children: [
                  Icon(
                    Icons.business_rounded,
                    size: 15,
                    color: colors.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job.company,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Meta chips: Location & Salary
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _buildMetaChip(
                    colors,
                    Icons.location_on_outlined,
                    job.location,
                  ),
                  if (job.salaryRange != null && job.salaryRange!.isNotEmpty)
                    _buildMetaChip(
                      colors,
                      Icons.payments_outlined,
                      job.salaryRange!,
                    ),
                ],
              ),

              if (job.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  job.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.secondaryText.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 14),

              Divider(
                color: colors.borderColor.withValues(alpha: 0.5),
                height: 1,
              ),

              const SizedBox(height: 10),

              // Footer: Poster Name & Apply Now Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: colors.primaryAccent.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.person,
                            size: 12,
                            color: colors.primaryAccent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Shared by ${job.posterName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _applyToJob(context, job),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primaryAccent,
                      foregroundColor: colors.onPrimaryAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Apply Now',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(AppColors colors, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.secondaryText),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(AppColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Shimmer.fromColors(
            baseColor: colors.borderColor.withValues(alpha: 0.3),
            highlightColor: colors.cardColor,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColors colors, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.categoryJob.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.work_off_outlined,
                size: 48,
                color: colors.categoryJob,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No opportunities available',
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "+ Post Job/Project" below to post a new job or internship opportunity on the portal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(alumniJobsProvider);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryAccent,
                side: BorderSide(color: colors.primaryAccent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(
    BuildContext context,
    AppColors colors,
    WidgetRef ref,
    Object error,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: Colors.redAccent.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Opportunities',
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString().replaceAll('AlumniApiException: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(alumniJobsProvider);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: colors.onPrimaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
