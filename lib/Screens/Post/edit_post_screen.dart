import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/screens/post/components/create_post_input_card.dart';
import 'package:igit_connects/screens/post/components/create_post_live_preview.dart';
import 'package:igit_connects/screens/post/components/create_post_top_section.dart';
import 'package:igit_connects/screens/premium/subscription_screen.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/storage_backend.dart';

class EditPostScreen extends ConsumerStatefulWidget {
  final Map post;

  const EditPostScreen({super.key, required this.post});

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late TextEditingController title;
  late TextEditingController content;
  late TextEditingController link;

  bool loading = false;
  late String postType;

  List<String> existingImages = [];
  List<String> imagesToRemove =
      []; // Keep track of images to delete from storage
  List<XFile> _selectedXFiles = [];
  List<Uint8List> _selectedImagesBytes = [];

  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.post["title"].toString());
    content = TextEditingController(text: widget.post["content"].toString());
    link = TextEditingController(text: (widget.post["link"] ?? "").toString());
    postType = widget.post["post_type"].toString();

    if (widget.post["image_urls"] != null) {
      existingImages = List<String>.from(widget.post["image_urls"]);
    }
  }

  @override
  void dispose() {
    title.dispose();
    content.dispose();
    link.dispose();
    super.dispose();
  }

  void _showPremiumPrompt(String message) {
    final colors = AppColors.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: colors.cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colors.primaryAccent.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primaryAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                color: colors.primaryAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Limit Reached",
                    style: TextStyle(
                      color: colors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: colors.secondaryText, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: "Upgrade",
          textColor: colors.primaryAccent,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            );
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<void> savePost() async {
    if (title.text.trim().isEmpty &&
        content.text.trim().isEmpty &&
        link.text.trim().isEmpty &&
        existingImages.isEmpty &&
        _selectedXFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot save an empty post.")),
      );
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final user = await ref.read(userProvider.future);
      final plan = user["subscription_plan"] ?? 'free';
      final isActive = user["subscription_status"] == 'active';
      final isAdmin = user["role"] == 'admin';
      final isPro = (plan == 'premium_pro' && isActive) || isAdmin;
      final isLite = plan == 'premium_lite' && isActive;

      final int maxImagesPerPost = isPro ? 999 : (isLite ? 4 : 2);

      if (!isPro) {
        if (existingImages.length + _selectedXFiles.length > maxImagesPerPost) {
          _showPremiumPrompt(
            isLite
                ? "Premium Lite users can only have up to $maxImagesPerPost images per post."
                : "Free tier users can only have up to $maxImagesPerPost images per post.",
          );
          return;
        }
      }

      // 1. Delete removed images from storage
      for (String url in imagesToRemove) {
        await StorageBackend().removePostImage(url);
      }

      // 2. Upload new images
      List<String> uploadedUrls = [];
      if (_selectedXFiles.isNotEmpty) {
        uploadedUrls = await StorageBackend().uploadMultipleImages(
          _selectedXFiles,
        );
      }

      // 3. Combine existing images and newly uploaded images
      List<String> finalImageUrls = [...existingImages, ...uploadedUrls];

      await Supabase.instance.client
          .from('posts')
          .update({
            "title": title.text.trim(),
            "content": content.text.trim(),
            "link": link.text.trim(),
            "post_type": postType,
            "image_urls": finalImageUrls,
          })
          .eq("id", widget.post["id"]);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,

      // Top App Bar matching create post screen
      appBar: AppBar(
        backgroundColor: colors.bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Edit Post",
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: loading ? null : savePost,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: colors.onPrimaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimaryAccent,
                      ),
                    )
                  : const Icon(Icons.save_rounded, size: 16),
              label: Text(
                loading ? "Saving..." : "Save",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Bar matching create post screen
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 12,
          top: 12,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          color: colors.cardColor,
          border: Border(
            top: BorderSide(color: colors.borderColor.withValues(alpha: 0.5)),
          ),
        ),
        child: Row(
          children: [
            // Draft saved status
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.successColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: colors.successColor, size: 14),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edits saved",
                  style: TextStyle(
                    color: colors.primaryText,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  "Just now",
                  style: TextStyle(color: colors.secondaryText, fontSize: 11),
                ),
              ],
            ),

            const Spacer(),

            // Preview Button
            OutlinedButton.icon(
              onPressed: () {
                final colors = AppColors.of(context);
                final data = ref.read(userProvider).value;
                final name = (data?["name"] ?? "User").toString();
                final photo = (data?["photo_url"] ?? "").toString();
                final userType = (data?["user_type"] ?? "student")
                    .toString()
                    .toLowerCase();
                final department = (data?["department"] ?? "").toString();

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: colors.bgColor,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: AnimatedBuilder(
                          animation: Listenable.merge([title, content, link]),
                          builder: (context, _) => CreatePostPreviewSection(
                            name: name,
                            photo: photo,
                            userType: userType,
                            department: department,
                            postType: postType,
                            title: title.text,
                            content: content.text,
                            link: link.text,
                            images: _selectedImagesBytes,
                            existingImages: existingImages,
                            isVerified: data?["is_verified"] == true,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primaryText,
                side: BorderSide(color: colors.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
              label: const Text(
                "Preview",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),

      body: user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text(
            "Error loading user profile",
            style: TextStyle(color: colors.primaryText),
          ),
        ),
        data: (data) {
          final name = (data["name"] ?? "User").toString();
          final photo = (data["photo_url"] ?? "").toString();

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colors.borderColor,
                      backgroundImage: photo.isNotEmpty
                          ? NetworkImage(photo)
                          : null,
                      child: photo.isEmpty ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),

                    // Be kind chip
                    GestureDetector(
                      onTap: () {
                        final colors = AppColors.of(context);
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: colors.cardColor,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Community Guidelines",
                                  style: TextStyle(
                                    color: colors.primaryText,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "â€¢ Be respectful to all members.\nâ€¢ Do not share spam or irrelevant content.\nâ€¢ Ensure opportunities posted are genuine.\nâ€¢ Keep discussions professional and constructive.",
                                  style: TextStyle(
                                    color: colors.secondaryText,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colors.primaryAccent,
                                    ),
                                    child: Text(
                                      "I understand",
                                      style: TextStyle(
                                        color: colors.onPrimaryAccent,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colors.borderColor.withValues(alpha: 0.6),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: colors.secondaryText,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Be kind and follow our",
                                  style: TextStyle(
                                    color: colors.secondaryText,
                                    fontSize: 9.5,
                                  ),
                                ),
                                Text(
                                  "community guidelines",
                                  style: TextStyle(
                                    color: colors.primaryAccent,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                CreatePostInputCard(
                  title: title,
                  content: content,
                  link: link,
                  images: _selectedImagesBytes,
                  existingImages: existingImages,
                  onAddImage: () async {
                    final user = ref.read(userProvider).value;
                    final plan = user?["subscription_plan"] ?? 'free';
                    final isActive = user?["subscription_status"] == 'active';
                    final isAdmin = user?["role"] == 'admin';

                    int maxImages = 2; // free
                    if (isAdmin) {
                      maxImages = 999;
                    } else if (isActive) {
                      if (plan == 'premium_pro')
                        maxImages = 10;
                      else if (plan == 'premium_lite')
                        maxImages = 4;
                    }

                    if (existingImages.length + _selectedXFiles.length >=
                        maxImages) {
                      if (isAdmin || (isActive && plan == 'premium_pro')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "You can upload up to $maxImages images.",
                            ),
                          ),
                        );
                      } else {
                        _showPremiumPrompt(
                          plan == 'premium_lite'
                              ? "Premium Lite users can only upload up to 4 images."
                              : "Free tier users can only upload up to 2 images.",
                        );
                      }
                      return;
                    }
                    final image = await StorageBackend().pickImage();
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setState(() {
                        _selectedXFiles.add(image);
                        _selectedImagesBytes.add(bytes);
                      });
                    }
                  },
                  onRemoveImage: (index) {
                    setState(() {
                      _selectedXFiles.removeAt(index);
                      _selectedImagesBytes.removeAt(index);
                    });
                  },
                  onRemoveExistingImage: (index) {
                    setState(() {
                      imagesToRemove.add(existingImages[index]);
                      existingImages.removeAt(index);
                    });
                  },
                ),

                const SizedBox(height: 32),

                // Post Category Selector
                CreatePostTopSection(
                  postType: postType,
                  onChanged: (value) {
                    setState(() {
                      postType = value;
                    });
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
