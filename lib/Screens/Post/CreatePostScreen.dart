import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/Storage_Backend.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Component/app_colors.dart';
import '../../Component/CreatePost/CreatePostInputCard.dart';
import '../../Component/CreatePost/CreatePostLivePreview.dart';
import '../../Component/CreatePost/CreatePostTopSection.dart';
import '../../Component/CreatePost/TextfielsBuild.dart';
import '../../Controllers/PostProvider.dart';
import '../../Controllers/UserProvider.dart';
import '../../MainScreen.dart';

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

      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Spacer(),

          FloatingActionButton.extended(
            onPressed: posting ? null : createPost,

            backgroundColor: colors.primaryText,

            foregroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black
                : Colors.white,

            elevation: 0,

            icon: posting
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.black
                          : Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),

            label: Text(
              posting ? "Posting..." : "Post",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),

          child: user.when(
            loading: () => const Center(child: CircularProgressIndicator()),

            error: (e, s) => Center(
              child: Text("Error", style: TextStyle(color: colors.primaryText)),
            ),

            data: (data) {
              final name = (data["name"] ?? "User").toString();

              final photo = (data["photo_url"] ?? "").toString();

              final userType = (data["user_type"] ?? "student")
                  .toString()
                  .toLowerCase();

              final department = (data["department"] ?? "").toString();

              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // Top section
                    CreatePostTopSection(
                      postType: postType,

                      onChanged: (value) {
                        setState(() {
                          postType = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    CreatePostInputCard(
                      title: title,
                      content: content,
                      link: link,
                    ),

                    const SizedBox(height: 22),

                    // Preview — AnimatedBuilder listens to all three
                    // controllers without calling setState on every keystroke,
                    // so the TextField composition buffer is never interrupted.
                    AnimatedBuilder(
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
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
