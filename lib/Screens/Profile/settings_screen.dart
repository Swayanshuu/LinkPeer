import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/auth_gate.dart';
import 'package:igit_connects/core/post_provider.dart';
import 'package:igit_connects/core/theme_provider.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/screens/profile/edit_profile_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colors.bgColor,
        iconTheme: IconThemeData(color: colors.primaryText),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              ).then((updated) {
                if (updated == true) {
                  ref.invalidate(userProvider);
                }
              });
            },
            leading: Icon(Icons.person_outline, color: colors.primaryText),
            title: Text(
              "Personal Data",
              style: TextStyle(
                color: colors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              "Update your profile info",
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
          ListTile(
            leading: Icon(Icons.dark_mode_outlined, color: colors.primaryText),
            title: Text(
              "App Theme",
              style: TextStyle(
                color: colors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              Theme.of(context).brightness == Brightness.dark ? "Dark Mode" : "Light Mode",
              style: TextStyle(color: colors.secondaryText, fontSize: 12),
            ),
            trailing: Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (isDark) {
                ref
                    .read(themeProvider.notifier)
                    .setMode(isDark ? ThemeMode.dark : ThemeMode.light);
              },
              activeThumbColor: colors.bgColor,
              activeTrackColor: colors.primaryText,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: colors.cardColor,
          ),
          const SizedBox(height: 12),
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
