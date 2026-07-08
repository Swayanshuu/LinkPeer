// Screens/Profile/ProfileScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/screens/profile/components/profile_header_sliver.dart';
import 'package:igit_connects/screens/profile/components/profile_post_section.dart';
import 'package:igit_connects/core/post_provider.dart';
import 'package:igit_connects/core/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final user = ref.watch(userProvider);
    final posts = ref.watch(postsProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,
      body: user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text(
            "Failed to load profile",
            style: TextStyle(color: colors.primaryText),
          ),
        ),
        data: (data) {
          return DefaultTabController(
            length: 2,
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(userProvider);
                ref.invalidate(postsProvider);
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: colors.primaryText,
              backgroundColor: colors.cardColor,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    ProfileHeaderSliver(
                      data: data,
                      posts: posts,
                      ref: ref,
                      bottom: _SolidTabBar(
                        TabBar(
                          indicatorColor: colors.primaryAccent,
                          labelColor: colors.primaryAccent,
                          unselectedLabelColor: colors.secondaryText,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: colors.borderColor.withValues(
                            alpha: 0.5,
                          ),
                          tabs: const [
                            Tab(
                              icon: Icon(Icons.list_alt_rounded, size: 20),
                              text: "Posts",
                            ),
                            Tab(
                              icon: Icon(Icons.show_chart_rounded, size: 20),
                              text: "Activity",
                            ),
                          ],
                        ),
                        colors.bgColor,
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    CustomScrollView(
                      key: const PageStorageKey<String>('posts_tab'),
                      slivers: [
                        ProfilePostsSection(data: data, posts: posts, ref: ref),
                        const SliverToBoxAdapter(child: SizedBox(height: 90)),
                      ],
                    ),
                    Center(
                      child: Text(
                        "Activity - Coming Soon",
                        style: TextStyle(color: colors.secondaryText),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SolidTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabBar tabBar;
  final Color color;

  const _SolidTabBar(this.tabBar, this.color);

  @override
  Size get preferredSize => tabBar.preferredSize;

  @override
  Widget build(BuildContext context) {
    return Container(color: color, child: tabBar);
  }
}
