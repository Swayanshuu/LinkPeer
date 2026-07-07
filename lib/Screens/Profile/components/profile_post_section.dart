// Component/Profile/ProfilePostsSection.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/screens/home/components/post_card.dart';
import 'package:igit_connects/core/post_provider.dart';

class ProfilePostsSection extends StatefulWidget {
  final Map data;
  final AsyncValue<List<Map<String, dynamic>>> posts;
  final WidgetRef ref;

  const ProfilePostsSection({
    super.key,
    required this.data,
    required this.posts,
    required this.ref,
  });

  @override
  State<ProfilePostsSection> createState() => _ProfilePostsSectionState();
}

class _ProfilePostsSectionState extends State<ProfilePostsSection> {
  Widget _buildEmptyState(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add_rounded,
              size: 48,
              color: colors.secondaryText.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              "No posts yet",
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return widget.posts.when(
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
        final myPosts = list
            .where((p) => p["user_id"] == widget.data["id"])
            .toList();
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (myPosts.isEmpty) return _buildEmptyState(colors);

              return PostCard(
                post: myPosts[index],
                onRefresh: () {
                  widget.ref.invalidate(postsProvider);
                },
              );
            }, childCount: myPosts.isEmpty ? 1 : myPosts.length),
          ),
        );
      },
    );
  }
}
