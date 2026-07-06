import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/shared_components/hashtag_text.dart';

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

  @override
  void initState() {
    super.initState();

    title = TextEditingController(text: widget.post["title"].toString());

    content = TextEditingController(text: widget.post["content"].toString());

    link = TextEditingController(text: widget.post["link"].toString());

    postType = widget.post["post_type"].toString();

    title.addListener(() {
      setState(() {});
    });

    content.addListener(() {
      setState(() {});
    });

    link.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    title.dispose();
    content.dispose();
    link.dispose();
    super.dispose();
  }

  Color typeColor() {
    switch (postType) {
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

  Future<void> savePost() async {
    try {
      setState(() {
        loading = true;
      });

      await Supabase.instance.client
          .from('posts')
          .update({
            "title": title.text.trim(),
            "content": content.text.trim(),
            "link": link.text.trim(),
            "post_type": postType,
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

  Widget chip(String type, AppColors colors) {
    final selected = postType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          postType = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? typeColor() : colors.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.borderColor),
        ),
        child: Text(
          type.toUpperCase(),
          style: TextStyle(
            color: selected ? Colors.white : colors.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.bgColor,

      appBar: AppBar(
        backgroundColor: colors.bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.primaryText),
        title: Text(
          "Edit Post",
          style: TextStyle(color: colors.primaryText),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: title,
                style: TextStyle(color: colors.primaryText),
                decoration: InputDecoration(
                  hintText: "Title",
                  hintStyle: TextStyle(color: colors.secondaryText),
                  filled: true,
                  fillColor: colors.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: content,
                maxLines: 6,
                style: TextStyle(color: colors.primaryText),
                decoration: InputDecoration(
                  hintText: "Write here...",
                  hintStyle: TextStyle(color: colors.secondaryText),
                  filled: true,
                  fillColor: colors.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: link,
                style: TextStyle(color: colors.primaryText),
                decoration: InputDecoration(
                  hintText: "Link",
                  hintStyle: TextStyle(color: colors.secondaryText),
                  filled: true,
                  fillColor: colors.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    chip("normal", colors),
                    chip("job", colors),
                    chip("announcement", colors),
                    chip("internship", colors),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              Text(
                "Preview",
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        postType.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (title.text.isNotEmpty)
                      Text(
                        title.text,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                    if (title.text.isNotEmpty) const SizedBox(height: 12),

                    HashtagText(text: content.text, fontSize: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: loading ? null : savePost,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryText,
                foregroundColor: isDark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: loading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    )
                  : const Text(
                      "Save Changes",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
