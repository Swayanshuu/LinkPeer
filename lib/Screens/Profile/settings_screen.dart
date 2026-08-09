import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/auth_gate.dart';
import 'package:igit_connects/core/post_provider.dart';
import 'package:igit_connects/core/theme_provider.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/screens/profile/edit_profile_screen.dart';
import 'package:igit_connects/features/broadcast/screens/admin_broadcast_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Settings",
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
            leading: Icon(Icons.person_outline, color: colors.primaryText),
            title: Text(
              "Edit Profile",
              style: TextStyle(
                color: colors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              "Update your personal information",
              style: TextStyle(color: colors.secondaryText, fontSize: 12),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colors.secondaryText,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: colors.cardColor,
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final isDark = ref.watch(themeProvider) == ThemeMode.dark;
              return ListTile(
                leading: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  color: colors.primaryText,
                ),
                title: Text(
                  "Dark Mode",
                  style: TextStyle(
                    color: colors.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Switch(
                  value: isDark,
                  onChanged: (val) {
                    ref
                        .read(themeProvider.notifier)
                        .setMode(val ? ThemeMode.dark : ThemeMode.light);
                  },
                  activeThumbColor: colors.bgColor,
                  activeTrackColor: colors.primaryText,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: colors.cardColor,
              );
            },
          ),
          const SizedBox(height: 12),
          Consumer(
            builder: (context, ref, child) {
              final userAsync = ref.watch(userProvider);
              return userAsync.when(
                data: (user) {
                  if (user['role'] == 'admin') {
                    return Column(
                      children: [
                        ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminBroadcastScreen()),
                            );
                          },
                          leading: Icon(Icons.campaign, color: colors.primaryAccent),
                          title: Text(
                            "Broadcast Announcement",
                            style: TextStyle(
                              color: colors.primaryText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            "Create and send announcements",
                            style: TextStyle(color: colors.secondaryText, fontSize: 12),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: colors.secondaryText,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          tileColor: colors.cardColor,
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
          ListTile(
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              ref.invalidate(userProvider);
              ref.invalidate(postsProvider);

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthGate(userMode: "student"),
                ),
                (route) => false,
              );
            },
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Logout",
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              "Sign out of your account",
              style: TextStyle(color: colors.secondaryText, fontSize: 12),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: colors.cardColor,
          ),
        ],
      ),
    );
  }
}
