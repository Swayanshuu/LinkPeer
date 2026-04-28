// Screens/Profile/ProfileScreen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Component/AppColour.dart';
import '../../Component/Profile/ProfileHeaderSliver.dart';
import '../../Component/Profile/ProfilePostSection.dart';
import '../../Controllers/PostProvider.dart';
import '../../Controllers/UserProvider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(
      BuildContext context,
      WidgetRef ref) {

    final user =
    ref.watch(userProvider);

    final posts =
    ref.watch(postsProvider);

    return Scaffold(
      backgroundColor:
      AppColours.bgColor,

      body: user.when(
        loading:
            () =>
        const Center(
          child:
          CircularProgressIndicator(),
        ),

        error:
            (e, s) =>
        const Center(
          child: Text(
            "Failed to load profile",
            style: TextStyle(
              color:
              AppColours.primaryText,
            ),
          ),
        ),

        data: (data) {
          return CustomScrollView(
            slivers: [

              ProfileHeaderSliver(
                data: data,
                posts: posts,
                ref: ref,
              ),

              ProfilePostsSection(
                data: data,
                posts: posts,
                ref: ref,
              ),

              const SliverToBoxAdapter(
                child:
                SizedBox(
                  height: 90,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}