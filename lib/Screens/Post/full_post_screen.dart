import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/shared_components/custom_snackbar.dart';
import 'package:igit_connects/Screens/Post/components/full_screen_image_viewer.dart';
import 'package:igit_connects/shared_components/hashtag_text.dart';
import 'package:igit_connects/core/post_provider.dart';
import 'package:igit_connects/shared_components/share_card.dart';
import 'package:igit_connects/utils/share_service.dart';
import 'package:igit_connects/Screens/Profile/other_user_profile_screen.dart';
import 'package:igit_connects/screens/auth/login_screen.dart';
import 'package:igit_connects/Screens/Post/components/comment_widgets.dart';

class FullPostScreen extends ConsumerStatefulWidget {
  final Map post;
  final bool autoFocusComment;

  const FullPostScreen({
    super.key,
    required this.post,
    this.autoFocusComment = false,
  });

  @override
  ConsumerState<FullPostScreen> createState() => _FullPostScreenState();
}

class _FullPostScreenState extends ConsumerState<FullPostScreen> {
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isSaved = false;
  bool _isGeneratingLink = false;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeLikesAndSaves();
    
    if (widget.autoFocusComment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCommentsModal(context, widget.post['id'], AppColors.of(context));
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
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
    _commentsCount = commentsData.isNotEmpty
        ? (commentsData.first["count"] as int? ?? 0)
        : 0;
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
        await Supabase.instance.client.from("saved_posts").insert({
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
      if (!normalized.endsWith("Z") &&
          !RegExp(r'[+-]\d\d:?\d\d$').hasMatch(normalized)) {
        normalized = "${normalized}Z";
      }
      final dateTime = DateTime.parse(normalized).toLocal();
      return timeago.format(dateTime);
    } catch (_) {
      if (createdAt.length >= 16) {
        return "${createdAt.substring(0, 10)}, ${createdAt.substring(11, 16)}";
      }
      return createdAt.isNotEmpty ? createdAt.substring(0, 10) : "";
    }
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
    CustomSnackBar.show(
      context,
      message: "Invalid URL: $urlString",
      isError: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final post = widget.post;

    final name = (post["user_name"] ?? "User").toString();
    final photo = (post["user_photo"] ?? "").toString();
    final usersData = post["users"] as Map<String, dynamic>?;
    final userType = (usersData?["user_type"] ?? post["user_type"] ?? "student")
        .toString();
    final isAuthorAdmin = userType.toLowerCase() == "admin";
    final department = (post["department"] ?? "").toString();
    final branch = (usersData?["branch"] ?? post["branch"] ?? "").toString();
    final designation = (usersData?["designation"] ?? post["designation"] ?? "")
        .toString();

    String userHeadline = department;
    if (userType.toLowerCase() == "student" ||
        userType.toLowerCase() == "alumni") {
      userHeadline = branch.isNotEmpty ? branch : department;
    } else if (userType.toLowerCase() == "faculty") {
      if (designation.isNotEmpty && department.isNotEmpty) {
        userHeadline = "$designation, $department";
      } else if (designation.isNotEmpty) {
        userHeadline = designation;
      } else {
        userHeadline = branch.isNotEmpty ? branch : department;
      }
    }
    final title = (post["title"] ?? "").toString();
    final content = (post["content"] ?? "").toString();
    final link = (post["link"] ?? "").toString();
    final fileUrl = (post["file_url"] ?? "").toString();
    final fileName = (post["file_name"] ?? "").toString();
    final imageUrls =
        (post["image_urls"] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final createdAt = (post["created_at"] ?? "").toString();
    final date = _formatTimestamp(createdAt);

    final isVerified =
        usersData?["is_verified"] == true || post["is_verified"] == true;

    return Scaffold(
      floatingActionButton: link.isNotEmpty
          ? Padding(
              padding: EdgeInsets.only(
                bottom: FirebaseAuth.instance.currentUser == null ? 80.0 : 60.0,
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _safelyLaunchUrl(context, link, colors),
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? colors.primaryAccent
                    : colors.primaryAccent,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {

                final String imageUrl = (widget.post["image_url"] ?? "")
                    .toString();
                final String title = (widget.post["title"] ?? "").toString();
                final String content = (widget.post["content"] ?? "")
                    .toString();

                final shortUrl = await ShareService.generateShortLink(
                  postId: widget.post['id'].toString(),
                  title: title.isNotEmpty ? title : 'LinkPeer Post',
                  imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                );

                await ShareService.shareWidgetAsImage(
                  widget: ShareCard(
                    userName:
                        widget.post["user_name"]?.toString() ?? "Anonymous",
                    userRole: widget.post["user_type"]?.toString() ?? "User",
                    userAvatar: widget.post["user_photo"]?.toString() ?? "",
                    postContent: title.isNotEmpty
                        ? title
                        : (content.isNotEmpty
                              ? content
                              : "Check out this post!"),
                  ),
                  shareUrl: shortUrl,
                  postTitle: title.isNotEmpty ? title : "LinkPeer Post",
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAuthorAdmin
                        ? colors.adminPostBg
                        : colors.cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAuthorAdmin
                          ? colors.adminPostBorder
                          : colors.borderColor.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
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
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colors.borderColor,
                          backgroundImage: photo.isNotEmpty
                              ? NetworkImage(photo)
                              : null,
                          child: photo.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 28,
                                  color: colors.primaryText,
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
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
                                            name,
                                            style: TextStyle(
                                              color: colors.primaryText,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          name,
                                          style: TextStyle(
                                            color: colors.primaryText,
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.3,
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
                                  if ((usersData?["faculty_verified"] == true ||
                                          post["faculty_verified"] == true) &&
                                      userType.toLowerCase() == "faculty") ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.gpp_good_rounded,
                                      color: colors.primaryAccent,
                                      size: 16,
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAuthorAdmin
                                          ? colors.badgeAdminBg
                                          : userType.toLowerCase() == "alumni"
                                          ? colors.badgeAlumniBg
                                          : userType.toLowerCase() == "faculty"
                                          ? colors.badgeFacultyBg
                                          : colors.badgeStudentBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      userType.toUpperCase(),
                                      style: TextStyle(
                                        color: isAuthorAdmin
                                            ? colors.badgeAdminText
                                            : userType.toLowerCase() == "alumni"
                                            ? colors.badgeAlumniText
                                            : userType.toLowerCase() ==
                                                  "faculty"
                                            ? colors.badgeFacultyText
                                            : colors.badgeStudentText,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (isAuthorAdmin)
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _safelyLaunchUrl(
                                        context,
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
                                            fontSize: 12,
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
                                        color: colors.secondaryText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text(
                                  userHeadline.isNotEmpty
                                      ? "$userHeadline • $date"
                                      : date,
                                  style: TextStyle(
                                    color: colors.secondaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                        fontSize: 20, // smaller title
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                // Content Section
                HashtagText(text: content, fontSize: 14),

                const SizedBox(height: 24),

                // Attachments Section
                if (imageUrls.isNotEmpty) ...[
                  SizedBox(
                    height: 250,
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
                                  heroTagPrefix: 'full_post_${post["id"]}',
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Hero(
                                tag:
                                    'full_post_${post["id"]}_${imageUrls[index]}',
                                child: Image.network(
                                  imageUrls[index],
                                  height: 250,
                                  width: imageUrls.length == 1
                                      ? MediaQuery.of(context).size.width - 32
                                      : 300,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                if (fileUrl.isNotEmpty && imageUrls.isEmpty) ...[
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
                            Icon(
                              Icons.insert_drive_file,
                              color: colors.secondaryText,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fileName.isEmpty
                                    ? "View File Attachment"
                                    : fileName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.primaryText,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.download_rounded,
                              color: colors.primaryText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],

                // Link Secti                // Link Section moved to FAB
              ],
            ),
          ),
        ),
          if (FirebaseAuth.instance.currentUser == null)
            _buildLoginBanner(colors)
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildActionButton(
                      icon: _isLiked
                          ? Icons.favorite
                          : Icons.favorite_border_rounded,
                      color: _isLiked ? Colors.red : colors.secondaryText,
                      label: _likesCount > 0 ? "$_likesCount" : "",
                      onTap: _toggleLike,
                      isActive: _isLiked,
                    ),
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      color: colors.secondaryText,
                      label: _commentsCount > 0 ? "$_commentsCount" : "",
                      onTap: () {
                        showCommentsModal(context, widget.post['id'], colors);
                      },
                      isActive: false,
                    ),
                    _buildActionButton(
                      icon: _isSaved
                          ? Icons.bookmark
                          : Icons.bookmark_border_rounded,
                      color: _isSaved ? Colors.blue : colors.secondaryText,
                      label: "",
                      onTap: _toggleSave,
                      isActive: _isSaved,
                    ),
                    _buildActionButton(
                      icon: Icons.share_outlined,
                      color: colors.secondaryText,
                      label: "",
                      onTap: () async {
                        final String imageUrl =
                            (widget.post["image_url"] ?? "").toString();
                        final String title =
                            (widget.post["title"] ?? "").toString();
                        final String content =
                            (widget.post["content"] ?? "").toString();

                        final shortUrl = await ShareService.generateShortLink(
                          postId: widget.post['id'].toString(),
                          title: title.isNotEmpty ? title : 'LinkPeer Post',
                          imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
                        );

                        await ShareService.shareWidgetAsImage(
                          widget: ShareCard(
                            userName: widget.post["user_name"]?.toString() ??
                                "Anonymous",
                            userRole: widget.post["user_type"]?.toString() ??
                                "User",
                            userAvatar: widget.post["user_photo"]?.toString() ??
                                "",
                            postContent: title.isNotEmpty
                                ? title
                                : (content.isNotEmpty
                                    ? content
                                    : "Check out this post!"),
                          ),
                          shareUrl: shortUrl,
                          postTitle: title.isNotEmpty ? title : "LinkPeer Post",
                        );
                      },
                      isActive: false,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginBanner(AppColors colors) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const LoginScreen2(),
          ),
          (route) => false,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: colors.primaryText,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, color: colors.bgColor, size: 20),
              const SizedBox(width: 8),
              Text(
                "Login to see more",
                style: TextStyle(
                  color: colors.bgColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
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
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
