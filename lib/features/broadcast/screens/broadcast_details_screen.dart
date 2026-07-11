import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/features/broadcast/models/broadcast_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class BroadcastDetailsScreen extends StatelessWidget {
  final BroadcastModel broadcast;

  const BroadcastDetailsScreen({super.key, required this.broadcast});

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      // Validate that the url is actually a valid url format (contains a domain with a dot)
      final urlRegExp = RegExp(
          r"^(?:http(s)?:\/\/)?[\w.-]+(?:\.[\w\.-]+)+[\w\-\._~:/?#[\]@!\$&\(\)\*\+,;=.]+$",
          caseSensitive: false);

      if (!urlRegExp.hasMatch(url)) {
        throw Exception('Invalid URL format');
      }

      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid URL or cannot open link")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final formattedDate =
        DateFormat('MMMM d, yyyy - h:mm a').format(broadcast.createdAt);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        title: Text(
          'Announcement',
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colors.bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primaryText),
      ),
      floatingActionButton: (broadcast.linkUrl != null && broadcast.linkUrl!.isNotEmpty)
          ? Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: FloatingActionButton.extended(
                onPressed: () => _launchUrl(context, broadcast.linkUrl!),
                backgroundColor: colors.primaryAccent,
                icon: const Icon(Icons.link_rounded, color: Colors.white),
                label: const Text(
                  "Open Link",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (broadcast.imageUrl != null && broadcast.imageUrl!.isNotEmpty)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.40,
                ),
                child: Image.network(
                  broadcast.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.primaryAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          broadcast.audience.toUpperCase(),
                          style: TextStyle(
                            color: colors.primaryAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    broadcast.title,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    broadcast.message,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 80), // extra space for floating button
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
