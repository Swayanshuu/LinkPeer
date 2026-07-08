import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igit_connects/core/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(
    BuildContext context,
    String urlString,
    AppColors colors,
  ) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showError(context, colors);
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, colors);
      }
    }
  }

  void _showError(BuildContext context, AppColors colors) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Could not open link",
          style: TextStyle(color: colors.bgColor),
        ),
        backgroundColor: colors.primaryText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        title: Text(
          "About",
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colors.bgColor,
        iconTheme: IconThemeData(color: colors.primaryText),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.borderColor.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.primaryAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.rocket_launch_rounded,
                          size: 48,
                          color: colors.primaryAccent,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "LinkPeer",
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.bgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Text(
                          "Version 1.0.0",
                          style: TextStyle(
                            color: colors.primaryText,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Connecting Students, Alumni, and Faculty seamlessly.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Developer Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: colors.borderColor.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
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
                          Icon(Icons.code_rounded, color: colors.primaryText),
                          const SizedBox(width: 12),
                          Text(
                            "Developer Info",
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Swayanshu (swynx)",
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Full Stack Developer & App Architect passionate about building scalable solutions.",
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _launchUrl(context, "https://swynx.dev", colors),
                        icon: const Icon(
                          Icons.public,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Visit swynx.dev",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Space for footer
              ],
            ),
          ),

          // Absolute Footer
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Built with ",
                  style: TextStyle(color: colors.secondaryText, fontSize: 13),
                ),
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 14,
                ),
                Text(
                  " by ",
                  style: TextStyle(color: colors.secondaryText, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () => _launchUrl(context, "https://swynx.dev", colors),
                  child: const Text(
                    "swynx.dev",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
