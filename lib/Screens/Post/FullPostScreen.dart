import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Component/AppColour.dart';
import '../../Component/HashtagText.dart';

class FullPostScreen extends StatelessWidget {
  final Map post;

  const FullPostScreen({super.key, required this.post});

  Color userTypeColor(String type) {
    switch (type.toLowerCase()) {
      case "alumni":
        return Colors.green;
      case "faculty":
        return Colors.red;
      default:
        return const Color(0xff001f54);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (post["user_name"] ?? "User").toString();

    final photo = (post["user_photo"] ?? "").toString();

    final userType = (post["user_type"] ?? "student").toString();

    final department = (post["department"] ?? "").toString();

    final title = (post["title"] ?? "").toString();

    final content = (post["content"] ?? "").toString();

    final link = (post["link"] ?? "").toString();

    final createdAt = (post["created_at"] ?? "").toString();

    final date = createdAt.isNotEmpty ? createdAt.substring(0, 10) : "";

    return Scaffold(
      backgroundColor: AppColours.bgColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColours.bgColor,
        surfaceTintColor: Colors.transparent,
        leadingWidth: 44,

        titleSpacing: 0,

        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColours.borderColor,
              backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
              child: photo.isEmpty
                  ? const Icon(
                      Icons.person,
                      size: 18,
                      color: AppColours.primaryText,
                    )
                  : null,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColours.primaryText,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    userType == "faculty" && department.isNotEmpty
                        ? "$department • $date"
                        : "$userType • $date",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColours.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.share_outlined,
              color: AppColours.primaryText,
            ),
          ),

          const SizedBox(width: 4),
        ],
      ),

      floatingActionButton: link.isNotEmpty
          ? FloatingActionButton.extended(
              elevation: 0,
              backgroundColor: AppColours.cardColor,
              foregroundColor: AppColours.primaryText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColours.borderColor),
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text(
                "Open Link",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                await launchUrl(
                  Uri.parse(link),
                  mode: LaunchMode.externalApplication,
                );
              },
            )
          : null,

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty)
              Text(
                title,
                style: const TextStyle(
                  color: AppColours.primaryText,
                  fontSize: 26,
                  height: 1.3,
                  fontWeight: FontWeight.bold,
                ),
              ),

            if (title.isNotEmpty) const SizedBox(height: 18),

            HashtagText(text: content, fontSize: 17),
          ],
        ),
      ),
    );
  }
}
