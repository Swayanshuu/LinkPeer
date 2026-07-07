import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igit_connects/shared_components/hashtag_text.dart';

class CreatePostPreviewSection extends StatelessWidget {
  final String name;
  final String photo;
  final String userType;
  final String department;

  final String postType;
  final String title;
  final String content;
  final String link;

  const CreatePostPreviewSection({
    super.key,
    required this.name,
    required this.photo,
    required this.userType,
    required this.department,
    required this.postType,
    required this.title,
    required this.content,
    required this.link,
  });

  Color _getCategoryColor(String postType) {
    switch (postType.toLowerCase()) {
      case "job":
        return const Color(0xFF10B981); // Emerald Green
      case "internship":
        return const Color(0xFF3B82F6); // Blue
      case "announcement":
        return const Color(0xFFF59E0B); // Amber/Orange
      default:
        return const Color(0xFF6B7280); // Grey
    }
  }

  Widget _buildCategoryHeader(String postType, AppColors colors) {
    String label = "";
    IconData icon;
    Color color = _getCategoryColor(postType);

    switch (postType.toLowerCase()) {
      case "job":
        label = "JOB OPPORTUNITY";
        icon = Icons.work_outline_rounded;
        break;
      case "internship":
        label = "INTERNSHIP OPPORTUNITY";
        icon = Icons.school_outlined;
        break;
      case "announcement":
        label = "ANNOUNCEMENT";
        icon = Icons.campaign_outlined;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeBadge(String userType, AppColors colors) {
    Color color;
    switch (userType.toLowerCase()) {
      case "faculty":
        color = const Color(0xFFEF4444); // Red
        break;
      case "alumni":
        color = const Color(0xFF10B981); // Emerald
        break;
      default:
        color = const Color(0xFF6366F1); // Indigo
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Text(
        userType.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Future<void> _safelyLaunchUrl(
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
        _showInvalidUrlSnackBar(context, urlString, colors);
      }
    } catch (_) {
      if (context.mounted) {
        _showInvalidUrlSnackBar(context, urlString, colors);
      }
    }
  }

  void _showInvalidUrlSnackBar(
    BuildContext context,
    String urlString,
    AppColors colors,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 0.8),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                "Invalid URL: $urlString",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final userHeadline = department;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Live Preview",
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.4,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: (userType.toLowerCase() == "admin")
                ? colors.primaryText.withValues(alpha: 0.04)
                : colors.cardColor,
            border: Border(
              left: (userType.toLowerCase() == "admin")
                  ? const BorderSide(color: Colors.blue, width: 3.5)
                  : BorderSide.none,
              bottom: BorderSide(
                color: colors.borderColor.withValues(alpha: 0.5),
                width: 1.0,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// CATEGORY HEADER
              _buildCategoryHeader(postType, colors),

              /// HEADER
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: colors.borderColor,
                    backgroundImage: photo.isNotEmpty
                        ? NetworkImage(photo)
                        : null,
                    child: photo.isEmpty ? const Icon(Icons.person) : null,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name.isEmpty ? "User" : name,
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontSize: 13.5, // smaller text
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildUserTypeBadge(userType, colors),
                          ],
                        ),

                        if (userHeadline.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            userHeadline,
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        const SizedBox(height: 3),

                        Row(
                          children: [
                            Text(
                              "Just now",
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 11, // smaller text
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.public,
                              size: 11,
                              color: colors.secondaryText,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /// TITLE
              if (title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 14, // smaller text
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ),

              /// CONTENT
              content.isEmpty
                  ? Text(
                      "Your post content...",
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 13, // smaller text
                      ),
                    )
                  : HashtagText(text: content, fontSize: 13),

              /// LINK ATTACHMENT (Bookmark Card Layout)
              if (link.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => _safelyLaunchUrl(context, link, colors),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: colors.bgColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.borderColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Open Link",
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 14,
                              color: colors.secondaryText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),

              /// DUMMY ACTION BAR
              Row(
                mainAxisAlignment: MainAxisAlignment.start, // Left align
                children: [
                  _DummyActionButton(
                    icon: Icons.favorite_border_rounded,
                    color: colors.secondaryText,
                    label: "",
                  ),
                  _DummyActionButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: colors.secondaryText,
                    label: "",
                  ),
                  _DummyActionButton(
                    icon: Icons.share_outlined,
                    color: colors.secondaryText,
                    label: "",
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DummyActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _DummyActionButton({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          if (label.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
