import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:igit_connects/screens/post/full_post_screen.dart';
import 'package:igit_connects/screens/post/edit_post_screen.dart';
import 'package:igit_connects/shared_components/hashtag_text.dart';
import 'package:igit_connects/storage_backend.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/Screens/Post/components/full_screen_image_viewer.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/shared_components/share_card.dart';
import 'package:igit_connects/utils/share_service.dart';
import 'package:igit_connects/Screens/Profile/other_user_profile_screen.dart';

class PostCard extends ConsumerStatefulWidget {
  final Map post;
  final VoidCallback onRefresh;

  const PostCard({super.key, required this.post, required this.onRefresh});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isSaved = false;
  int _commentsCount = 0;

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

    // Parse comments count
    final commentsData = post["post_comments"] as List? ?? [];
    _commentsCount = commentsData.isNotEmpty ? (commentsData.first["count"] as int? ?? 0) : 0;
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
        await Supabase.instance.client.from("post_likes").insert({
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
        await Supabase.instance.client.from("saved_posts").insert({
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
    try {
      // 1. Delete images from storage if any
      final imageUrls = widget.post["image_urls"];
      if (imageUrls != null && imageUrls is List) {
        for (final url in imageUrls) {
          if (url is String && url.isNotEmpty) {
            await StorageBackend().removePostImage(url);
          }
        }
      }

      final singleImageUrl = widget.post["image_url"];
      if (singleImageUrl != null &&
          singleImageUrl is String &&
          singleImageUrl.isNotEmpty) {
        await StorageBackend().removePostImage(singleImageUrl);
      }

      // 2. Delete the post from DB
      await Supabase.instance.client
          .from("posts")
          .delete()
          .eq("id", widget.post["id"]);

      widget.onRefresh();
    } catch (e) {
      debugPrint("Error deleting post: $e");
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
      if (!normalized.endsWith("Z") &&
          !RegExp(r'[+-]\d\d:?\d\d$').hasMatch(normalized)) {
        normalized = "${normalized}Z";
      }
      final dateTime = DateTime.parse(normalized).toLocal();
      final year = dateTime.year;
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');

      final hourVal = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final amPm = hourVal >= 12 ? "PM" : "AM";
      final hour = (hourVal % 12 == 0 ? 12 : hourVal % 12).toString().padLeft(
        2,
        '0',
      );

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
        backgroundColor: Colors.red.shade600,
        margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                "Invalid URL: $urlString",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
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
    Color bgColor;
    Color textColor;

    switch (userType.toLowerCase()) {
      case "alumni":
        bgColor = colors.badgeAlumniBg;
        textColor = colors.badgeAlumniText;
        break;
      case "admin":
        bgColor = colors.badgeAdminBg;
        textColor = colors.badgeAdminText;
        break;
      case "faculty":
        bgColor = colors.badgeFacultyBg;
        textColor = colors.badgeFacultyText;
        break;
      case "student":
      default:
        bgColor = colors.badgeStudentBg;
        textColor = colors.badgeStudentText;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        userType.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final post = widget.post;

    final userAsync = ref.watch(userProvider);
    bool isAdmin = false;
    userAsync.whenData((userData) {
      if (userData['role']?.toString().toLowerCase() == 'admin' ||
          userData['user_type']?.toString().toLowerCase() == 'admin') {
        isAdmin = true;
      }
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwner = currentUser != null && currentUser.uid == post["user_id"];
    final isOwnerOrAdmin = isOwner || isAdmin;

    final userName = (post["user_name"] ?? "User").toString();
    final photo = (post["user_photo"] ?? "").toString();
    final usersData = post["users"] as Map<String, dynamic>?;
    final userType = (usersData?["user_type"] ?? post["user_type"] ?? "student")
        .toString();
    final department = (post["department"] ?? "").toString();
    final branch = (usersData?["branch"] ?? post["branch"] ?? "").toString();
    final designation = (usersData?["designation"] ?? post["designation"] ?? "")
        .toString();
    final postType = (post["post_type"] ?? "normal").toString();
    final title = (post["title"] ?? "").toString();
    final content = (post["content"] ?? "").toString();
    final link = (post["link"] ?? "").toString();
    final fileName = (post["file_name"] ?? "").toString();
    final fileUrl = (post["file_url"] ?? "").toString();
    final imageUrls =
        (post["image_urls"] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final createdAt = (post["created_at"] ?? "").toString();

    final commentsList = post["post_comments"] as List? ?? [];
    final commentsCount = commentsList.length;

    final date = _formatTimestamp(createdAt);
    final isLongPost = content.length > 250;
    final shortContent = isLongPost ? content.substring(0, 250) : content;

    final isVerified =
        usersData?["is_verified"] == true || post["is_verified"] == true;

    String userHeadline = department;
    if (userType.toLowerCase() == "student" ||
        userType.toLowerCase() == "alumni") {
      userHeadline = branch.isNotEmpty ? branch : department;
    } else if (userType.toLowerCase() == "faculty") {
      userHeadline = designation.isNotEmpty
          ? designation
          : (branch.isNotEmpty ? branch : department);
    }

    final isAuthorAdmin = userType.toLowerCase() == "admin";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FullPostScreen(post: post)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: postType.toLowerCase() == "announcement"
              ? colors.announcementBg
              : isAuthorAdmin
              ? colors.adminPostBg
              : colors.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: postType.toLowerCase() == "announcement"
                ? colors.announcementBorder
                : isAuthorAdmin
                ? colors.adminPostBorder
                : colors.borderColor.withValues(alpha: 0.5),
            width: 1.0,
          ),
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
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (post["user_id"] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OtherUserProfileScreen(
                              userId: post["user_id"].toString(),
                            ),
                          ),
                        );
                      }
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colors.borderColor,
                          backgroundImage: photo.isNotEmpty
                              ? NetworkImage(photo)
                              : null,
                          child: photo.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  isAuthorAdmin
                                      ? Shimmer.fromColors(
                                          baseColor: colors.primaryText,
                                          highlightColor: Colors.blueAccent,
                                          child: Text(
                                            userName,
                                            style: TextStyle(
                                              color: colors.primaryText,
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          userName,
                                          style: TextStyle(
                                            color: colors.primaryText,
                                            fontSize: 13.5, // smaller text
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                  if (isVerified) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  _buildUserTypeBadge(userType, colors),
                                ],
                              ),

                              const SizedBox(height: 4),
                              if (isAuthorAdmin)
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _safelyLaunchUrl(
                                        "https://swynx.dev",
                                        colors,
                                      ),
                                      child: Shimmer.fromColors(
                                        baseColor: Colors.blueAccent,
                                        highlightColor:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : Colors.blue.shade900,
                                        child: Text(
                                          "swynx.dev",
                                          style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: Colors.blueAccent
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      " • $date",
                                      style: TextStyle(
                                        color: colors.secondaryText.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      Icons.public,
                                      size: 11,
                                      color: colors.secondaryText.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ],
                                )
                              else ...[
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        userHeadline.isNotEmpty
                                            ? "$userHeadline • $date"
                                            : date,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.secondaryText,
                                          fontSize: 11, // smaller text
                                        ),
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (isOwnerOrAdmin)
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: colors.secondaryText),
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
                        if (!context.mounted) return;
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: colors.cardColor,
                              title: Text(
                                "Delete Post",
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              content: Text(
                                "Are you sure you want to delete this post? This action cannot be undone.",
                                style: TextStyle(color: colors.secondaryText),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: colors.secondaryText,
                                    ),
                                  ),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm == true) {
                          await deletePost();
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: "edit",
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: colors.primaryText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Edit",
                              style: TextStyle(color: colors.primaryText),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Delete",
                              style: const TextStyle(color: Colors.red),
                            ),
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
                    fontSize: 14, // smaller text
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
              ),

            /// CONTENT
            HashtagText(text: shortContent, fontSize: 13),

            if (isLongPost)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullPostScreen(post: post),
                    ),
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

            /// MULTIPLE IMAGE ATTACHMENTS
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(
                              imageUrls: imageUrls,
                              initialIndex: index,
                              heroTagPrefix: 'post_card_${post["id"]}',
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Hero(
                            tag: 'post_card_${post["id"]}_${imageUrls[index]}',
                            child: Image.network(
                              imageUrls[index],
                              height: 220,
                              width: imageUrls.length == 1
                                  ? MediaQuery.of(context).size.width - 32
                                  : 280,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            /// SINGLE FILE ATTACHMENT (Backward compatibility)
            if (fileUrl.isNotEmpty && imageUrls.isEmpty) ...[
              const SizedBox(height: 12),

              if (isImage(fileUrl))
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageViewer(
                          imageUrls: [fileUrl],
                          initialIndex: 0,
                          heroTagPrefix: 'post_card_${post["id"]}',
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: 'post_card_${post["id"]}_$fileUrl',
                      child: Image.network(
                        fileUrl,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
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
                        Icon(
                          Icons.attach_file,
                          color: colors.secondaryText,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName.isEmpty ? "Open File" : fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.open_in_new,
                          color: colors.secondaryText,
                          size: 14,
                        ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blueAccent.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Open Link",
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.blue.shade300
                                  : Colors.blue.shade700,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 14,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.blue.shade300
                                : Colors.blue.shade700,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 8),

            /// ACTION BAR (Like, Comment, Save, Share)
            Row(
              mainAxisAlignment: MainAxisAlignment.start, // Left align
              children: [
                _ActionButton(
                  icon: _isLiked
                      ? Icons.favorite
                      : Icons.favorite_border_rounded,
                  iconColor: _isLiked ? Colors.red : colors.secondaryText,
                  textColor: _isLiked ? Colors.red : colors.secondaryText,
                  label: _likesCount > 0 ? "$_likesCount" : "",
                  onTap: _toggleLike,
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: colors.secondaryText,
                  textColor: colors.secondaryText,
                  label: _commentsCount > 0 ? "$_commentsCount" : "",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullPostScreen(post: post),
                      ),
                    );
                  },
                ),
                _ActionButton(
                  icon: _isSaved
                      ? Icons.bookmark
                      : Icons.bookmark_border_rounded,
                  iconColor: _isSaved ? Colors.blue : colors.secondaryText,
                  textColor: _isSaved ? Colors.blue : colors.secondaryText,
                  label: "",
                  onTap: _toggleSave,
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  iconColor: colors.secondaryText,
                  textColor: colors.secondaryText,
                  label: "",
                  onTap: () async {
                    if (!context.mounted) return;

                    // Show loading indicator
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: colors.cardColor,
                        content: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              "Generating share link...",
                              style: TextStyle(color: colors.primaryText),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );

                    final String imageUrl = widget.post["image_url"] ?? "";

                    // Call API to get short URL
                    final shortUrl = await ShareService.generateShortLink(
                      postId: widget.post['id'].toString(),
                      title: title.isNotEmpty ? title : 'LinkPeer Post',
                      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                    );

                    if (!context.mounted) return;

                    // Share widget as professional image + short link
                    await ShareService.shareWidgetAsImage(
                      widget: ShareCard(
                        userName: widget.post["user_name"] ?? "Anonymous",
                        userRole: widget.post["user_type"] ?? "User",
                        userAvatar: widget.post["user_photo"] ?? "",
                        postContent: title.isNotEmpty
                            ? title
                            : (content.isNotEmpty
                                  ? content
                                  : "Check out this post!"),
                      ),
                      shareUrl: shortUrl,
                      postTitle: title.isNotEmpty ? title : 'LinkPeer Post',
                    );
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
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
