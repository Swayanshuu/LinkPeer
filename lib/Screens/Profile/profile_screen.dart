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
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userProvider);
              ref.invalidate(postsProvider);
              // Small delay to allow the providers to fetch new data before stopping the indicator
              await Future.delayed(const Duration(milliseconds: 500));
            },
            color: colors.primaryText,
            backgroundColor: colors.cardColor,
            child: CustomScrollView(
              slivers: [
                ProfileHeaderSliver(data: data, posts: posts, ref: ref),
                ProfilePostsSection(data: data, posts: posts, ref: ref),
                const SliverToBoxAdapter(child: SizedBox(height: 90)),
              ],
            ),
          );
        },
      ),
    );
  }
}
