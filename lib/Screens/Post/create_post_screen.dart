import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/screens/post/components/create_post_input_card.dart';
import 'package:igit_connects/screens/post/components/create_post_live_preview.dart';
import 'package:igit_connects/screens/post/components/create_post_top_section.dart';
import 'package:igit_connects/screens/premium/subscription_screen.dart';

import 'package:igit_connects/core/post_provider.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/main_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:igit_connects/storage_backend.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  // Controllers
  final title = TextEditingController();

  final content = TextEditingController();

  final link = TextEditingController();

  // State
  String postType = "normal";

  bool posting = false;
  final List<XFile> _selectedXFiles = [];
  final List<Uint8List> _selectedImagesBytes = [];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.invalidate(userProvider);
    });
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

  Future<void> _pickImages() async {
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

    if (_selectedXFiles.length >= maxImages) {
      if (isActive && plan == 'premium_pro') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You can upload up to $maxImages images.")),
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
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(imageQuality: 50);

      if (images.isNotEmpty) {
        if (_selectedXFiles.length + images.length > maxImages) {
          if (mounted) {
            if (isAdmin || (isActive && plan == 'premium_pro')) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "You can only upload up to $maxImages images per post.",
                  ),
                ),
              );
            } else {
              _showPremiumPrompt(
                plan == 'premium_lite'
                    ? "Premium Lite limit: Up to 4 images per post."
                    : "Free tier limit: Up to 2 images per post.",
              );
            }
          }
          return;
        }

        List<Uint8List> newImagesBytes = [];
        for (var image in images) {
          final bytes = await image.readAsBytes();
          newImagesBytes.add(bytes);
        }

        setState(() {
          _selectedXFiles.addAll(images);
          _selectedImagesBytes.addAll(newImagesBytes);
        });
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    }
  }

  Future<void> createPost() async {
    if (title.text.trim().isEmpty &&
        content.text.trim().isEmpty &&
        link.text.trim().isEmpty &&
        _selectedXFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You cannot publish an empty post.")),
      );
      return;
    }

    try {
      setState(() {
        posting = true;
      });

      final user = await ref.read(userProvider.future);
      final plan = user["subscription_plan"] ?? 'free';
      final isActive = user["subscription_status"] == 'active';
      final isAdmin = user["role"] == 'admin';
      final isPro = (plan == 'premium_pro' && isActive) || isAdmin;
      final isLite = plan == 'premium_lite' && isActive;

      final int maxImagesPerPost = isPro ? 999 : (isLite ? 4 : 2);
      final int maxPostsPerDay = isPro ? 999 : (isLite ? 10 : 3);
      final int maxPicPostsPerMonth = isPro ? 999 : (isLite ? 15 : 5);

      if (!isPro) {
        if (_selectedXFiles.length > maxImagesPerPost) {
          _showPremiumPrompt(
            isLite
                ? "Premium Lite users can only upload up to $maxImagesPerPost images per post."
                : "Free tier users can only upload up to $maxImagesPerPost images per post.",
          );
          return;
        }

        final today = DateTime.now();
        final startOfDay = DateTime(
          today.year,
          today.month,
          today.day,
        ).toIso8601String();

        final dailyPostsResp = await Supabase.instance.client
            .from("user_activities")
            .select("id")
            .eq("user_id", FirebaseAuth.instance.currentUser!.uid)
            .inFilter("activity_type", ["text_post", "image_post"])
            .gte("created_at", startOfDay);

        if ((dailyPostsResp as List).length >= maxPostsPerDay) {
          _showPremiumPrompt(
            isLite
                ? "Premium Lite limit: You can only publish $maxPostsPerDay posts per day."
                : "Free tier limit: You can only publish $maxPostsPerDay posts per day.",
          );
          return;
        }

        if (_selectedXFiles.isNotEmpty) {
          final startOfMonth = DateTime(
            today.year,
            today.month,
            1,
          ).toIso8601String();
          final monthlyPicPostsResp = await Supabase.instance.client
              .from("user_activities")
              .select("id")
              .eq("user_id", FirebaseAuth.instance.currentUser!.uid)
              .eq("activity_type", "image_post")
              .gte("created_at", startOfMonth);

          if ((monthlyPicPostsResp as List).length >= maxPicPostsPerMonth) {
            _showPremiumPrompt(
              isLite
                  ? "Premium Lite limit: You can only publish $maxPicPostsPerMonth posts with pictures per month."
                  : "Free tier limit: You can only publish $maxPicPostsPerMonth posts with pictures per month.",
            );
            return;
          }
        }
      }

      List<String> uploadedUrls = [];
      if (_selectedXFiles.isNotEmpty) {
        uploadedUrls = await StorageBackend().uploadMultipleImages(
          _selectedXFiles,
        );
      }

      await Supabase.instance.client.from("posts").insert({
        "user_id": FirebaseAuth.instance.currentUser!.uid,
        "user_name": user["name"],
        "user_photo": user["photo_url"],
        "user_type": user["user_type"],
        "department": user["department"],
        "branch": user["branch"],
        "designation": user["designation"],
        "post_type": postType,
        "title": title.text.trim(),
        "content": content.text.trim(),
        "link": link.text.trim(),
        "image_urls": uploadedUrls,
      });

      // Insert into user_activities for immutable tracking
      await Supabase.instance.client.from("user_activities").insert({
        "user_id": FirebaseAuth.instance.currentUser!.uid,
        "activity_type": uploadedUrls.isNotEmpty ? "image_post" : "text_post",
      });

      ref.invalidate(postsProvider);

      title.clear();
      content.clear();
      link.clear();

      if (!mounted) {
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      if (mounted) {
        setState(() {
          posting = false;
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

      // Top App Bar matching mockup
      appBar: AppBar(
        backgroundColor: colors.bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Create Post",
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
              onPressed: posting ? null : createPost,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: colors.onPrimaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: posting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimaryAccent,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(
                posting ? "Posting..." : "Post",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),

      // Bottom Bar matching mockup
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
                  "Draft saved",
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
                final role = (data?["role"] ?? "user").toString().toLowerCase();
                final isAdmin = role == "admin";
                final userType = isAdmin 
                    ? "admin" 
                    : (data?["user_type"] ?? "student").toString().toLowerCase();
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
                // User Profile Header Row (Mockup: Avatar, Name, Public dropdown, Shield chip)
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
                                  "• Be respectful to all members.\n• Do not share spam or irrelevant content.\n• Ensure opportunities posted are genuine.\n• Keep discussions professional and constructive.",
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

                // Main Input Area
                CreatePostInputCard(
                  title: title,
                  content: content,
                  link: link,
                  images: _selectedImagesBytes,
                  onAddImage: _pickImages,
                  onRemoveImage: (index) {
                    setState(() {
                      _selectedXFiles.removeAt(index);
                      _selectedImagesBytes.removeAt(index);
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
