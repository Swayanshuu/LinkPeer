// create_post_preview_section.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Component/AppColour.dart';

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

  Color typeColor() {
    switch (postType) {
      case "job":
        return Colors.green;
      case "announcement":
        return Colors.orange;
      case "internship":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget hashText(String text) {
    final words = text.split(" ");

    return Wrap(
      children: words.map((e) {
        final hash = e.startsWith("#");

        return Text(
          "$e ",
          style: TextStyle(
            color: hash ? Colors.blue : AppColours.primaryText,
            fontWeight: hash ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Live Preview",
          style: TextStyle(
            color: AppColours.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColours.cardColor,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: photo.isNotEmpty
                        ? NetworkImage(photo)
                        : null,
                    child: photo.isEmpty ? const Icon(Icons.person) : null,
                  ),

                  const SizedBox(width: 10),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColours.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        userType == "faculty" && department.isNotEmpty
                            ? "faculty • $department"
                            : userType,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColours.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: typeColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  postType.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColours.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              if (title.isNotEmpty) const SizedBox(height: 8),

              content.isEmpty
                  ? const Text(
                      "Your post content...",
                      style: TextStyle(color: AppColours.primaryText),
                    )
                  : hashText(content),

              if (link.isNotEmpty) ...[
                const SizedBox(height: 14),

                InkWell(
                  onTap: () async {
                    await launchUrl(
                      Uri.parse(link),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColours.bgColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      "Open Link",
                      style: TextStyle(color: AppColours.primaryText),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
