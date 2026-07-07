import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/core/theme_provider.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/screens/profile/settings_screen.dart';
import 'package:igit_connects/screens/about/about_screen.dart';
import 'package:igit_connects/screens/bookmarks/bookmarks_screen.dart';
import 'package:igit_connects/core/auth_gate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  void _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final colors = AppColors.of(context);
        return AlertDialog(
          backgroundColor: colors.cardColor,
          title: Text(
            "Sign Out",
            style: TextStyle(
              color: colors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            "Are you sure you want to sign out?",
            style: TextStyle(color: colors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                "Cancel",
                style: TextStyle(color: colors.secondaryText),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text(
                "Sign Out",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const AuthGate(userMode: "student"),
          ),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final userAsync = ref.watch(userProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: colors.bgColor,
      child: Column(
        children: [
          // Custom Header
          userAsync.when(
            data: (me) {
              final photoUrl = me["photo_url"]?.toString();
              final name = me["name"] ?? "User";
              final email = FirebaseAuth.instance.currentUser?.email ?? "";
              final userType = (me["user_type"] ?? "Student")
                  .toString()
                  .toUpperCase();
              final isStudent = userType.toLowerCase() == "student";
              final isVerified = me["is_verified"] == true;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 60,
                  bottom: 20,
                  left: 24,
                  right: 24,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.cardColor
                      : colors.primaryAccent.withValues(alpha: 0.05),
                  image: DecorationImage(
                    image: const NetworkImage(
                      "https://www.transparenttextures.com/patterns/cubes.png",
                    ), // Subtle pattern
                    fit: BoxFit.cover,
                    opacity: isDark ? 0.05 : 0.1,
                  ),
                  border: Border(
                    bottom: BorderSide(color: colors.borderColor, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.primaryAccent.withValues(
                                alpha: 0.3,
                              ),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.primaryAccent.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 36,
                            backgroundColor: colors.bgColor,
                            backgroundImage:
                                (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? Icon(
                                    Icons.person,
                                    size: 36,
                                    color: colors.secondaryText,
                                  )
                                : null,
                          ),
                        ),
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isStudent
                                ? colors.badgeStudentBg
                                : colors.badgeAlumniBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            userType,
                            style: TextStyle(
                              color: isStudent
                                  ? colors.badgeStudentText
                                  : colors.badgeAlumniText,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: Icon(
                              Icons.verified,
                              color: colors.primaryAccent,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: BoxDecoration(
                color: colors.cardColor,
                border: Border(bottom: BorderSide(color: colors.borderColor)),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: BoxDecoration(
                color: colors.cardColor,
                border: Border(bottom: BorderSide(color: colors.borderColor)),
              ),
              child: Center(
                child: Text(
                  "Error loading user",
                  style: TextStyle(color: colors.primaryText),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.bookmark_border_rounded,
                  title: "Saved Posts",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BookmarksScreen(),
                      ),
                    );
                  },
                  colors: colors,
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: isDark
                      ? Icons.light_mode_rounded
                      : Icons.dark_mode_rounded,
                  title: isDark ? "Light Mode" : "Dark Mode",
                  onTap: () {
                    ref
                        .read(themeProvider.notifier)
                        .setMode(isDark ? ThemeMode.light : ThemeMode.dark);
                  },
                  colors: colors,
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.bug_report_outlined,
                  title: "Report a Bug",
                  onTap: () async {
                    Navigator.pop(context); // close drawer first
                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'swynx.dev@gmail.com',
                      queryParameters: {'subject': 'Bug Report in LinkPeer'},
                    );
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    }
                  },
                  colors: colors,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Divider(
                    color: colors.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.info_outline_rounded,
                  title: "About App",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                  colors: colors,
                ),
                const SizedBox(height: 4),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  colors: colors,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: Divider(
                    color: colors.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.logout_rounded,
                  title: "Sign Out",
                  iconColor: Colors.redAccent,
                  textColor: Colors.redAccent,
                  onTap: () => _signOut(context, ref),
                  colors: colors,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Built with ",
                  style: TextStyle(color: colors.secondaryText, fontSize: 13),
                ),
                const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 14,
                ),
                Text(
                  " by ",
                  style: TextStyle(color: colors.secondaryText, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse("https://swynx.dev");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                  child: const Text(
                    "swynx.dev",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required AppColors colors,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? colors.primaryText, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? colors.primaryText,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      hoverColor: colors.primaryText.withValues(alpha: 0.05),
    );
  }
}
