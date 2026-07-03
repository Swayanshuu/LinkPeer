import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _initializeLikesAndSaves();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _initializeLikesAndSaves();
    }
  }

  void _initializeLikesAndSaves() {
    final post = widget.post;
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? "";

    // Parse likes
    final likesList = post["post_likes"] as List? ?? [];
    _likesCount = likesList.length;
    _isLiked = likesList.any((like) => like["user_id"] == currentUserId);

    // Parse saved posts
    final savedList = post["saved_posts"] as List? ?? [];
    _isSaved = savedList.any((save) => save["user_id"] == currentUserId);
  }

  Future<void> _toggleLike() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final currentUserId = currentUser.uid;
    final postId = widget.post["id"];

    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likesCount--;
      } else {
        _isLiked = true;
        _likesCount++;
      }
    });

    try {
      if (!_isLiked) {
        await Supabase.instance.client
            .from("post_likes")
            .delete()
            .eq("post_id", postId)
            .eq("user_id", currentUserId);
      } else {
        await Supabase.instance.client
            .from("post_likes")
            .insert({
              "post_id": postId,
              "user_id": currentUserId,
            });
      }
      widget.onRefresh();
    } catch (e) {
      setState(() {
        if (_isLiked) {
          _isLiked = false;
          _likesCount--;
        } else {
          _isLiked = true;
          _likesCount++;
        }
      });
      debugPrint("Error toggling like: $e");
    }
  }

  Future<void> _toggleSave() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final currentUserId = currentUser.uid;
    final postId = widget.post["id"];

    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      if (!_isSaved) {
        await Supabase.instance.client
            .from("saved_posts")
            .delete()
            .eq("post_id", postId)
            .eq("user_id", currentUserId);
      } else {
        await Supabase.instance.client
            .from("saved_posts")
            .insert({
              "post_id": postId,
              "user_id": currentUserId,
            });
      }
      widget.onRefresh();
    } catch (e) {
      setState(() {
        _isSaved = !_isSaved;
      });
      debugPrint("Error toggling save: $e");
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

  String _formatTimestamp(String createdAt) {
    if (createdAt.isEmpty) return "";
    try {
      String normalized = createdAt;
      if (!normalized.endsWith("Z") && !RegExp(r'[+-]\d\d:?\d\d$').hasMatch(normalized)) {
        normalized = "${normalized}Z";
      }
      final dateTime = DateTime.parse(normalized).toLocal();
      final year = dateTime.year;
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      
      final hourVal = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final amPm = hourVal >= 12 ? "PM" : "AM";
      final hour = (hourVal % 12 == 0 ? 12 : hourVal % 12).toString().padLeft(2, '0');
      
      return "$year-$month-$day • $hour:$minute $amPm";
    } catch (_) {
      if (createdAt.length >= 16) {
        return "${createdAt.substring(0, 10)} • ${createdAt.substring(11, 16)}";
      }
      return createdAt.isNotEmpty ? createdAt.substring(0, 10) : "";
    }
  }

  Future<void> _safelyLaunchUrl(String urlString, AppColors colors) async {
    try {
      final uri = Uri.parse(urlString);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showInvalidUrlSnackBar(urlString, colors);
      }
    } catch (_) {
      if (mounted) {
        _showInvalidUrlSnackBar(urlString, colors);
      }
    }
  }

  void _showInvalidUrlSnackBar(String urlString, AppColors colors) {
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

    final date = _formatTimestamp(createdAt);
    final isLongPost = content.length > 250;
    final shortContent = isLongPost ? content.substring(0, 250) : content;

    final userHeadline = department;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FullPostScreen(post: post)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// CATEGORY UPPERCASE LABEL (e.g. JOB OPPORTUNITY)
          _buildCategoryHeader(postType, colors),

          /// HEADER (AVATAR & NAME BLOCK)
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 15.5,
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
                          date,
                          style: TextStyle(
                            color: colors.secondaryText.withValues(alpha: 0.7),
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.public,
                          size: 11,
                          color: colors.secondaryText.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (isOwner)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_horiz,
                    color: colors.secondaryText,
                  ),
                  color: colors.cardColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.borderColor),
                  ),
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
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: "edit",
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: colors.primaryText),
                          const SizedBox(width: 8),
                          Text("Edit", style: TextStyle(color: colors.primaryText)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: "delete",
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          const SizedBox(width: 8),
                          Text("Delete", style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
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
                  fontSize: 17.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ),

          /// CONTENT
          HashtagText(text: shortContent, fontSize: 14.5),

          if (isLongPost)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FullPostScreen(post: post)),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  "... see more",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          /// FILE ATTACHMENT
          if (fileUrl.isNotEmpty) ...[
            const SizedBox(height: 12),

            if (isImage(fileUrl))
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  fileUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else
              InkWell(
                onTap: () => _safelyLaunchUrl(fileUrl, colors),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, color: colors.secondaryText, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName.isEmpty ? "Open File" : fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.primaryText, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.open_in_new, color: colors.secondaryText, size: 14),
                    ],
                  ),
                ),
              ),
          ],

          /// LINK ATTACHMENT (Bookmark Card Layout)
          if (link.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () => _safelyLaunchUrl(link, colors),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.bgColor.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.borderColor.withValues(alpha: 0.3)),
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

          /// LIKES COUNT ROW (Just above the divider)
          if (_likesCount > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 14),
                const SizedBox(width: 6),
                Text(
                  "$_likesCount ${_likesCount == 1 ? 'like' : 'likes'}",
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),

          /// ACTION BAR (Like, Comment, Save, Share)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ActionButton(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                iconColor: _isLiked ? Colors.red : colors.secondaryText,
                textColor: _isLiked ? Colors.red : colors.secondaryText,
                label: "Like",
                onTap: _toggleLike,
              ),
              _ActionButton(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: colors.secondaryText,
                textColor: colors.secondaryText,
                label: "Comment",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FullPostScreen(post: post)),
                  );
                },
              ),
              _ActionButton(
                icon: _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                iconColor: _isSaved ? Colors.blue : colors.secondaryText,
                textColor: _isSaved ? Colors.blue : colors.secondaryText,
                label: "Save",
                onTap: _toggleSave,
              ),
              _ActionButton(
                icon: Icons.share_outlined,
                iconColor: colors.secondaryText,
                textColor: colors.secondaryText,
                label: "Share",
                onTap: () {
                  final shareText = "${title.isNotEmpty ? "$title\n\n" : ""}$content\n\nShared via LinkPeer";
                  Clipboard.setData(ClipboardData(text: shareText)).then((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: colors.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: colors.borderColor),
                          ),
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                "Copied to clipboard!",
                                style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  });
                },
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color textColor;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.textColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
