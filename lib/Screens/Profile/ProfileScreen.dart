// Screens/Profile/ProfileScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Component/app_colors.dart';
import '../../Component/Profile/ProfileHeaderSliver.dart';
import '../../Component/Profile/ProfilePostSection.dart';
import '../../Controllers/PostProvider.dart';
import '../../Controllers/UserProvider.dart';

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
          return CustomScrollView(
            slivers: [
              ProfileHeaderSliver(data: data, posts: posts, ref: ref),

              ProfilePostsSection(data: data, posts: posts, ref: ref),

              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          );
        },
      ),
    );
  }
}