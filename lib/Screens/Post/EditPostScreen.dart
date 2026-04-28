import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Component/AppColour.dart';
import '../../Component/HashtagText.dart';

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

  Widget chip(String type) {
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
          color: selected ? typeColor() : AppColours.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColours.borderColor),
        ),
        child: Text(
          type.toUpperCase(),
          style: const TextStyle(
            color: AppColours.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.bgColor,

      appBar: AppBar(
        backgroundColor: AppColours.bgColor,
        elevation: 0,
        title: const Text(
          "Edit Post",
          style: TextStyle(color: AppColours.primaryText),
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
                style: const TextStyle(color: AppColours.primaryText),
                decoration: InputDecoration(
                  hintText: "Title",
                  filled: true,
                  fillColor: AppColours.cardColor,
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
                style: const TextStyle(color: AppColours.primaryText),
                decoration: InputDecoration(
                  hintText: "Write here...",
                  filled: true,
                  fillColor: AppColours.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: link,
                style: const TextStyle(color: AppColours.primaryText),
                decoration: InputDecoration(
                  hintText: "Link",
                  filled: true,
                  fillColor: AppColours.cardColor,
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
                    chip("normal"),
                    chip("job"),
                    chip("announcement"),
                    chip("internship"),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                "Preview",
                style: TextStyle(
                  color: AppColours.primaryText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColours.cardColor,
                  borderRadius: BorderRadius.circular(22),
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
                        style: const TextStyle(
                          color: AppColours.primaryText,
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
                backgroundColor: AppColours.primaryText,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
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
