import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Controllers/AuthGate.dart';
import '../../Controllers/PostProvider.dart';
import '../../Controllers/UserProvider.dart';
import '../AppColour.dart';

class HomeHeader extends ConsumerWidget {
  final Map me;

  const HomeHeader({super.key, required this.me});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),

      decoration: BoxDecoration(
        color: AppColours.cardColor,

        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),

        border: Border.all(color: AppColours.borderColor),
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome back",
                  style: TextStyle(
                    color: AppColours.secondaryText,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                AutoSizeText(
                  me["name"],
                  maxLines: 1,
                  minFontSize: 18,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColours.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,

                backgroundColor: AppColours.cardColor,

                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),

                builder: (_) {
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(18),

                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 42,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppColours.borderColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          const SizedBox(height: 18),

                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColours.borderColor,
                            backgroundImage:
                                (me["photo_url"] != null &&
                                    me["photo_url"].toString().isNotEmpty)
                                ? NetworkImage(me["photo_url"])
                                : null,
                            child:
                                (me["photo_url"] == null ||
                                    me["photo_url"].toString().isEmpty)
                                ? const Icon(
                                    Icons.verified_user,
                                    color: AppColours.primaryText,
                                  )
                                : null,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            me["name"] ?? "User",
                            style: const TextStyle(
                              color: AppColours.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            height: 52,

                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.logout, color: Colors.red),

                              label: const Text(
                                "Logout",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),

                              onPressed: () async {
                                Navigator.pop(context);

                                await FirebaseAuth.instance.signOut();

                                ref.invalidate(userProvider);

                                ref.invalidate(postsProvider);

                                if (!context.mounted) {
                                  return;
                                }

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AuthGate(userMode: "student"),
                                  ),
                                  (route) => false,
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
              );
            },

            child: CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(me["photo_url"]),
            ),
          ),
        ],
      ),
    );
  }
}
