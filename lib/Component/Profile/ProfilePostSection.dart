// Component/Profile/ProfilePostsSection.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_colors.dart';
import '../Home/PostCard.dart';
import '../../Controllers/PostProvider.dart';

class ProfilePostsSection extends StatelessWidget {
  final Map data;
  final AsyncValue posts;
  final WidgetRef ref;

  const ProfilePostsSection({
    super.key,
    required this.data,
    required this.posts,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return posts.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),

      error: (e, s) => SliverToBoxAdapter(
        child: Center(
          child: Text(
            "Failed loading posts",
            style: TextStyle(color: colors.primaryText),
          ),
        ),
      ),

      data: (list) {
        final myPosts = list.where((p) => p["user_id"] == data["id"]).toList();

        if (myPosts.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  "No posts yet",
                  style: TextStyle(color: colors.secondaryText),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),

          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return PostCard(
                post: myPosts[index],

                onRefresh: () {
                  ref.invalidate(postsProvider);
                },
              );
            }, childCount: myPosts.length),
          ),
        );
      },
    );
  }
}
