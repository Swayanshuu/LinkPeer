// Component/Profile/ProfileHeaderSliver.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../AppColour.dart';
import 'ProfileGridPainter.dart';
import '../../Controllers/UserProvider.dart';
import '../../Screens/Profile/EditProfileScreen.dart';
import 'ProfileStatsRow.dart';

class ProfileHeaderSliver extends StatelessWidget {
  final Map data;
  final AsyncValue posts;
  final WidgetRef ref;

  const ProfileHeaderSliver({
    super.key,
    required this.data,
    required this.posts,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final name = data["name"] ?? "User";

    final email = data["email"] ?? "";

    final photo = data["photo_url"] ?? "";

    return SliverAppBar(
      stretch: true,
      expandedHeight: 350,
      elevation: 0,
      backgroundColor: AppColours.bgColor,

      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),

          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppColours.bgColor),

              CustomPaint(painter: GridLinePainter()),

              Container(color: Colors.black.withOpacity(0.18)),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),

                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,

                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          const Text(
                            "Profile",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          OutlinedButton(
                            onPressed: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );

                              if (updated == true) {
                                ref.invalidate(userProvider);
                              }
                            },

                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColours.primaryText,

                              backgroundColor: Colors.white.withOpacity(0.06),

                              side: const BorderSide(
                                color: Colors.white24,
                                width: 1,
                              ),

                              elevation: 0,

                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),

                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined, size: 16),

                                SizedBox(width: 8),

                                Text(
                                  "Edit",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      CircleAvatar(
                        radius: 42,
                        backgroundImage: photo.toString().isNotEmpty
                            ? NetworkImage(photo)
                            : null,
                        child: photo.toString().isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),

                      const SizedBox(height: 12),

                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        email,
                        style: const TextStyle(color: Colors.white70),
                      ),

                      const SizedBox(height: 18),

                      ProfileStatsRow(data: data, posts: posts),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
