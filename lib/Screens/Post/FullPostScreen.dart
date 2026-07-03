import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Component/app_colors.dart';
import '../../Component/HashtagText.dart';
import '../../Controllers/PostProvider.dart';

class FullPostScreen extends ConsumerStatefulWidget {
  final Map post;

  const FullPostScreen({super.key, required this.post});

  @override
  ConsumerState<FullPostScreen> createState() => _FullPostScreenState();
}

class _FullPostScreenState extends ConsumerState<FullPostScreen> {
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _initializeLikesAndSaves();
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
      ref.invalidate(postsProvider);
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
      ref.invalidate(postsProvider);
    } catch (e) {
      setState(() {
        _isSaved = !_isSaved;
      });
      debugPrint("Error toggling save: $e");
    }
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

  Future<void> _safelyLaunchUrl(BuildContext context, String urlString, AppColors colors) async {
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

  void _showInvalidUrlSnackBar(BuildContext context, String urlString, AppColors colors) {
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
    final post = widget.post;

    final name = (post["user_name"] ?? "User").toString();
    final photo = (post["user_photo"] ?? "").toString();
    final userType = (post["user_type"] ?? "student").toString();
    final department = (post["department"] ?? "").toString();
    final title = (post["title"] ?? "").toString();
    final content = (post["content"] ?? "").toString();
    final link = (post["link"] ?? "").toString();
    final fileUrl = (post["file_url"] ?? "").toString();
    final fileName = (post["file_name"] ?? "").toString();
    final createdAt = (post["created_at"] ?? "").toString();
    final date = _formatTimestamp(createdAt);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.bgColor,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colors.primaryText),
        title: Text(
          "Post",
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110), // Extra padding for bottom bar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Profile Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.cardColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colors.borderColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: colors.borderColor,
                        backgroundImage: photo.isNotEmpty ? NetworkImage(photo) : null,
                        child: photo.isEmpty
                            ? Icon(Icons.person, size: 28, color: colors.primaryText)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userType == "faculty" && department.isNotEmpty
                                  ? "$department • $date"
                                  : "$userType • $date",
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Title Section
                if (title.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 24,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                // Content Section
                HashtagText(text: content, fontSize: 16),

                const SizedBox(height: 24),

                // Attachments Section
                if (fileUrl.isNotEmpty) ...[
                  if (isImage(fileUrl))
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        fileUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => _safelyLaunchUrl(context, fileUrl, colors),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.insert_drive_file, color: colors.secondaryText, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fileName.isEmpty ? "View File Attachment" : fileName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.primaryText, 
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.download_rounded, color: colors.primaryText),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],

                // Link Section
                if (link.isNotEmpty)
                  InkWell(
                    onTap: () => _safelyLaunchUrl(context, link, colors),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.cardColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.bgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.link_rounded, color: colors.primaryText),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "External Link",
                                  style: TextStyle(
                                    color: colors.primaryText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  link,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.blue.shade400,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.bgColor.withOpacity(0.95),
                border: Border(
                  top: BorderSide(color: colors.borderColor.withOpacity(0.5)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionButton(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                      color: _isLiked ? Colors.red : colors.secondaryText,
                      label: _likesCount > 0 ? "$_likesCount" : "Like",
                      onTap: _toggleLike,
                      isActive: _isLiked,
                    ),
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: colors.secondaryText,
                      label: "Comment",
                      onTap: () {
                        // Keep current screen, maybe focus a comment field later
                      },
                      isActive: false,
                    ),
                    _buildActionButton(
                      icon: _isSaved ? Icons.bookmark : Icons.bookmark_border_rounded,
                      color: _isSaved ? Colors.blue : colors.secondaryText,
                      label: "Save",
                      onTap: _toggleSave,
                      isActive: _isSaved,
                    ),
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      color: colors.secondaryText,
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
                      isActive: false,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
