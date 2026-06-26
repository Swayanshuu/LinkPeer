import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Controllers/AuthGate.dart';
import '../../Controllers/PostProvider.dart';
import '../../Controllers/UserProvider.dart';
import '../../Controllers/ThemeProvider.dart';
import '../app_colors.dart';
import 'package:auto_size_text/auto_size_text.dart';

class HomeHeader extends ConsumerWidget {
  final Map me;

  const HomeHeader({super.key, required this.me});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),

      decoration: BoxDecoration(
        color: colors.cardColor,

        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),

        border: Border.all(color: colors.borderColor),
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back",
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                AutoSizeText(
                  me["name"],
                  maxLines: 1,
                  minFontSize: 18,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Theme toggle button
          GestureDetector(
            onTap: () => ref.read(themeProvider.notifier).toggle(),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colors.bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderColor),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: colors.primaryText,
                size: 20,
              ),
            ),
          ),

          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,

                backgroundColor: colors.cardColor,

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
                              color: colors.borderColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          const SizedBox(height: 18),

                          CircleAvatar(
                            radius: 28,
                            backgroundColor: colors.borderColor,
                            backgroundImage:
                                (me["photo_url"] != null &&
                                    me["photo_url"].toString().isNotEmpty)
                                ? NetworkImage(me["photo_url"])
                                : null,
                            child:
                                (me["photo_url"] == null ||
                                    me["photo_url"].toString().isEmpty)
                                ? Icon(
                                    Icons.verified_user,
                                    color: colors.primaryText,
                                  )
                                : null,
                          ),

                          const SizedBox(height: 12),

                          Text(
                            me["name"] ?? "User",
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 22),

                          if(me["role"] == "admin")...  [
                            SizedBox(
                              height: 52,width: MediaQuery.of(context).size.width/2,
                              child: InkWell(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colors.primaryText,
                                    borderRadius: BorderRadius.circular(18)
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.security, color: colors.cardColor),
                                      Text("Go to App Manager", style: TextStyle(color: colors.cardColor)),
                                    ],
                                  ),
                                ),
                                onTap: (){
                                  // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_){
                                  //   return ;
                                  // }));
                                },
                              ),
                            ),
                            const SizedBox(height: 22,)
                          ],

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
