import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:igit_connects/Component/HashtagText.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Component/app_colors.dart';
import '../../Screens/Post/EditPostScreen.dart';
import '../../Screens/Post/FullPostScreen.dart';

class PostCard extends StatefulWidget {
  final Map post;
  final VoidCallback onRefresh;

  const PostCard({super.key, required this.post, required this.onRefresh});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  Color postTypeColor(String type) {
    switch (type.toLowerCase()) {
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

  Color userTypeColor(String type) {
    switch (type.toLowerCase()) {
      case "faculty":
        return Colors.red;
      case "alumni":
        return Colors.green;
      default:
        return const Color(0xff001f54);
    }
  }

  Future<void> deletePost() async {
    await Supabase.instance.client
        .from("posts")
        .delete()
        .eq("id", widget.post["id"]);

    widget.onRefresh();
  }

  bool isImage(String url) {
    final u = url.toLowerCase();

    return u.endsWith(".png") ||
        u.endsWith(".jpg") ||
        u.endsWith(".jpeg") ||
        u.endsWith(".webp");
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final post = widget.post;

    final currentUser = FirebaseAuth.instance.currentUser;

    final isOwner = currentUser != null && currentUser.uid == post["user_id"];

    final userName = (post["user_name"] ?? "User").toString();

    final photo = (post["user_photo"] ?? "").toString();

    final userType = (post["user_type"] ?? "student").toString();

    final department = (post["department"] ?? "").toString();

    final postType = (post["post_type"] ?? "normal").toString();

    final title = (post["title"] ?? "").toString();

    final content = (post["content"] ?? "").toString();

    final link = (post["link"] ?? "").toString();

    final fileName = (post["file_name"] ?? "").toString();

    final fileUrl = (post["file_url"] ?? "").toString();

    final createdAt = (post["created_at"] ?? "").toString();

    final date = createdAt.isNotEmpty ? createdAt.substring(0, 10) : "";

    final isLongPost = content.length > 250;

    final shortContent = isLongPost ? content.substring(0, 250) : content;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.borderColor,
                backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                child: photo.isEmpty ? const Icon(Icons.person) : null,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: userTypeColor(userType),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            userType.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Text(
                          userType == "faculty" && department.isNotEmpty
                              ? "$department • $date"
                              : date,
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              PopupMenuButton(
                color: colors.cardColor,
                onSelected: (value) async {
                  if (value == "edit") {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditPostScreen(post: post),
                      ),
                    );

                    if (updated == true) {
                      widget.onRefresh();
                    }
                  }

                  if (value == "delete") {
                    await deletePost();
                  }
                },
                itemBuilder: (_) {
                  if (isOwner) {
                    return [
                      PopupMenuItem(
                        value: "edit",
                        child: Text("Edit", style: TextStyle(color: colors.primaryText)),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Text("Delete", style: TextStyle(color: colors.primaryText)),
                      ),
                    ];
                  }

                  return const [];
                },
              ),
            ],
          ),

          const SizedBox(height: 14),

          /// POST TYPE
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: postTypeColor(postType),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              postType.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 14),

          /// TITLE
          if (title.isNotEmpty)
            Text(
              title,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

          if (title.isNotEmpty) const SizedBox(height: 10),

          /// CONTENT
          HashtagText(text: shortContent, fontSize: 15),

          if (isLongPost)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FullPostScreen(post: post)),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  "Read more",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          /// FILE FROM DATABASE
          if (fileUrl.isNotEmpty) ...[
            const SizedBox(height: 14),

            if (isImage(fileUrl))
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  fileUrl,
                  width: double.infinity,
                  height: 230,
                  fit: BoxFit.cover,
                ),
              )
            else
              InkWell(
                onTap: () async {
                  await launchUrl(
                    Uri.parse(fileUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.bgColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, color: colors.secondaryText),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName.isEmpty ? "Open File" : fileName,
                          style: TextStyle(color: colors.primaryText),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          /// LINK
          if (link.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: InkWell(
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
                      color: colors.bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Text(
                      "Open Link",
                      style: TextStyle(color: colors.primaryText),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
