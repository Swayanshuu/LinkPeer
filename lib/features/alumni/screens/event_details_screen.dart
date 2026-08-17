import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/features/alumni/models/alumni_event_model.dart';
import 'package:igit_connects/shared_components/custom_snackbar.dart';

class EventDetailsScreen extends StatelessWidget {
  final AlumniEvent event;

  const EventDetailsScreen({super.key, required this.event});

  String get _eventWebUrl {
    if (event.registrationLink != null &&
        event.registrationLink!.isNotEmpty &&
        event.registrationLink!.startsWith('http')) {
      return event.registrationLink!;
    }
    if (event.id != null && event.id!.isNotEmpty) {
      return 'https://cse.igitalumni.in/event/${event.id}';
    }
    return 'https://igitmcaalumni.netlify.app/register';
  }

  Future<void> _openRegistrationLink(BuildContext context, String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            message: 'Could not open link: $urlString',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: 'Unable to open registration URL: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _contactOrganizer(BuildContext context, String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Inquiry regarding Alumni Event: ${event.title}',
      },
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            message: 'Could not launch email app for $email',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(
          context,
          message: 'Unable to open mail app: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isHighPriority = event.priority.toLowerCase() == 'high';

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
          'Event Details',
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
                              if (event.priority.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isHighPriority
                                        ? Colors.redAccent.withValues(alpha: 0.12)
                                        : colors.borderColor.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${event.priority} Priority',
                                    style: TextStyle(
                                      color: isHighPriority
                                          ? Colors.redAccent
                                          : colors.secondaryText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            event.title,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.groups_rounded,
                                size: 16,
                                color: colors.primaryAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Organized by ${event.organizer}',
                                style: TextStyle(
                                  color: colors.secondaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Event Details Grid Card
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
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: event.formattedFullDate,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(
                              color: colors.borderColor.withValues(alpha: 0.4),
                              height: 1,
                            ),
                          ),
                          _buildDetailRow(
                            colors,
                            icon: Icons.access_time_rounded,
                            label: 'Time',
                            value: event.time,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(
                              color: colors.borderColor.withValues(alpha: 0.4),
                              height: 1,
                            ),
                          ),
                          _buildDetailRow(
                            colors,
                            icon: Icons.location_on_rounded,
                            label: 'Location',
                            value: event.location,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description Section
                    Text(
                      'About Event',
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
                        event.description.isNotEmpty
                            ? event.description
                            : 'No detailed description available.',
                        style: TextStyle(
                          color: colors.primaryText.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Agenda Section
                    if (event.agenda != null && event.agenda!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Event Agenda',
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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.format_list_bulleted_rounded,
                              color: colors.primaryAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                event.agenda!,
                                style: TextStyle(
                                  color: colors.primaryText.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Contact Information
                    if (event.contactEmail != null && event.contactEmail!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Contact Organizer',
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
                                    'Contact Email',
                                    style: TextStyle(
                                      color: colors.secondaryText,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    event.contactEmail!,
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
                              onPressed: () => _contactOrganizer(context, event.contactEmail!),
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

            // Registration Action Button at Bottom
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
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _openRegistrationLink(context, _eventWebUrl),
                  icon: const Icon(Icons.app_registration_rounded, size: 20),
                  label: const Text(
                    'Register / View Event Website',
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
    );
  }

  Widget _buildDetailRow(
    AppColors colors, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
