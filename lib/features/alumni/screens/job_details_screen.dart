import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/features/alumni/models/alumni_job_model.dart';
import 'package:igit_connects/shared_components/custom_snackbar.dart';

class JobDetailsScreen extends StatelessWidget {
  final AlumniJob job;

  const JobDetailsScreen({super.key, required this.job});

  String get _jobWebUrl {
    return 'https://cse.igitalumni.in/careers';
  }

  Future<void> _openWebPortal(BuildContext context) async {
    final Uri uri = Uri.parse(_jobWebUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            message: 'Could not open portal link: $_jobWebUrl',
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

  Future<void> _contactPoster(BuildContext context, String rawEmail) async {
    final email = rawEmail.trim().isNotEmpty ? rawEmail.trim() : 'alumni@igitalumni.in';
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
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isInternship = job.type.toLowerCase().contains('intern');
    final badgeBg = isInternship
        ? colors.categoryInternship.withValues(alpha: 0.12)
        : colors.categoryJob.withValues(alpha: 0.12);
    final badgeText = isInternship ? colors.categoryInternship : colors.categoryJob;

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
          'Opportunity Details',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colors.cardColor,
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  job.type,
                                  style: TextStyle(
                                    color: badgeText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            job.title,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.business_rounded,
                                size: 18,
                                color: colors.primaryAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                job.company,
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Details Grid Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.borderColor.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            colors,
                            icon: Icons.location_on_rounded,
                            label: 'Location',
                            value: job.location,
                          ),
                          if (job.salaryRange != null && job.salaryRange!.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Divider(
                                color: colors.borderColor.withValues(alpha: 0.4),
                                height: 1,
                              ),
                            ),
                            _buildDetailRow(
                              colors,
                              icon: Icons.payments_rounded,
                              label: 'Salary / Stipend',
                              value: job.salaryRange!,
                            ),
                          ],
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(
                              color: colors.borderColor.withValues(alpha: 0.4),
                              height: 1,
                            ),
                          ),
                          _buildDetailRow(
                            colors,
                            icon: Icons.account_circle_rounded,
                            label: 'Posted By',
                            value: job.posterName,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description Section
                    Text(
                      'Job Description',
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.borderColor.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Text(
                        job.description.isNotEmpty
                            ? job.description
                            : 'No full description provided.',
                        style: TextStyle(
                          color: colors.primaryText.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),

                    if (job.contactEmail != null && job.contactEmail!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Contact Information',
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: colors.borderColor.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.primaryAccent.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.email_rounded,
                                color: colors.primaryAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recruiter Email',
                                    style: TextStyle(
                                      color: colors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    job.contactEmail!,
                                    style: TextStyle(
                                      color: colors.primaryText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _contactPoster(context, job.contactEmail!),
                              icon: Icon(
                                Icons.open_in_new_rounded,
                                color: colors.primaryAccent,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom CTA bar matching web behavior
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.cardColor,
                border: Border(
                  top: BorderSide(
                    color: colors.borderColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _openWebPortal(context),
                        icon: const Icon(Icons.language_rounded, size: 18),
                        label: const Text('Website'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.primaryAccent,
                          side: BorderSide(color: colors.primaryAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _contactPoster(
                          context,
                          job.contactEmail ?? 'alumni@igitalumni.in',
                        ),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text(
                          'Apply Now',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primaryAccent,
                          foregroundColor: colors.onPrimaryAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    AppColors colors, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.secondaryText),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
