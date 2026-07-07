import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/screens/post/components/create_post_input_card.dart';
import 'package:igit_connects/screens/post/components/create_post_live_preview.dart';
import 'package:igit_connects/screens/post/components/create_post_top_section.dart';

import 'package:igit_connects/core/post_provider.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/main_screen.dart';

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

  Future<void> createPost() async {
    try {
      setState(() {
        posting = true;
      });

      final user = await ref.read(userProvider.future);

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

  Uint8List? imageBytes;

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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

                // Main Input Area
                CreatePostInputCard(title: title, content: content, link: link),

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

