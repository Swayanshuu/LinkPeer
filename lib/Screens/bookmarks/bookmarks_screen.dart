import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/post_provider.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/screens/home/components/post_card.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final user = ref.watch(userProvider);
    final posts = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Bookmarks",
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text(
            "Failed to load user data",
            style: TextStyle(color: colors.primaryText),
          ),
        ),
        data: (userData) {
          return posts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(
              child: Text(
                "Failed to load bookmarks",
                style: TextStyle(color: colors.primaryText),
              ),
            ),
            data: (postList) {
              final savedPosts = postList.where((p) {
                final savedList = p["saved_posts"] as List? ?? [];
                return savedList.any((s) => s["user_id"] == userData["id"]);
              }).toList();

              if (savedPosts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 64,
                        color: colors.secondaryText.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No saved posts yet",
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Posts you save will appear here",
                        style: TextStyle(
                          color: colors.secondaryText.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(postsProvider);
                },
                color: colors.primaryText,
                backgroundColor: colors.cardColor,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: savedPosts.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PostCard(
                        post: savedPosts[index],
                        onRefresh: () => ref.invalidate(postsProvider),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
