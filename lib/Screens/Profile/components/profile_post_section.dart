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
  int _activeTab = 0; // 0 = My Posts, 1 = Saved Posts

  Widget _buildTabSelector(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.cardColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTab = 0),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 0 ? colors.cardColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _activeTab == 0
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.grid_on_rounded,
                        size: 16,
                        color: _activeTab == 0 ? colors.primaryText : colors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "My Posts",
                        style: TextStyle(
                          color: _activeTab == 0 ? colors.primaryText : colors.secondaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _activeTab = 1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _activeTab == 1 ? colors.cardColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _activeTab == 1
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_rounded,
                        size: 16,
                        color: _activeTab == 1 ? colors.primaryText : colors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Saved",
                        style: TextStyle(
                          color: _activeTab == 1 ? colors.primaryText : colors.secondaryText,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _activeTab == 0 ? Icons.post_add_rounded : Icons.bookmark_border_rounded,
              size: 48,
              color: colors.secondaryText.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              _activeTab == 0 ? "No posts yet" : "No saved posts yet",
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
        final myPosts = list.where((p) => p["user_id"] == widget.data["id"]).toList();
        final savedPosts = list.where((p) {
          final savedList = p["saved_posts"] as List? ?? [];
          return savedList.any((s) => s["user_id"] == widget.data["id"]);
        }).toList();

        final activeList = _activeTab == 0 ? myPosts : savedPosts;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) return _buildTabSelector(colors);
                if (activeList.isEmpty) return _buildEmptyState(colors);

                final postIndex = index - 1;
                return PostCard(
                  post: activeList[postIndex],
                  onRefresh: () {
                    widget.ref.invalidate(postsProvider);
                  },
                );
              },
              childCount: activeList.isEmpty ? 2 : activeList.length + 1,
            ),
          ),
        );
      },
    );
  }
}
