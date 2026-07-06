import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/screens/profile/settings_screen.dart';
import 'package:igit_connects/screens/about/about_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final userAsync = ref.watch(userProvider);

    return Drawer(
      backgroundColor: colors.bgColor,
      child: Column(
        children: [
          // Custom Header
          userAsync.when(
            data: (me) {
              final photoUrl = me["photo_url"]?.toString();
              final name = me["name"] ?? "User";
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  border: Border(bottom: BorderSide(color: colors.borderColor, width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.primaryText.withValues(alpha: 0.1), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 38,
                        backgroundColor: colors.bgColor,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Icon(Icons.person, size: 38, color: colors.secondaryText)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      name,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
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
            error: (_, __) => Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 30),
              decoration: BoxDecoration(
                color: colors.cardColor,
                border: Border(bottom: BorderSide(color: colors.borderColor)),
              ),
              child: Center(child: Text("Error loading user", style: TextStyle(color: colors.primaryText))),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Menu Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _buildDrawerItem(
                  context: context,
                  icon: Icons.info_outline,
                  title: "About",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                  },
                  colors: colors,
                ),
                const SizedBox(height: 8),
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                  colors: colors,
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Footer
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Powered by ",
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 13,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final url = Uri.parse("https://swynx.dev");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                  child: const Text(
                    "swynx.dev",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: colors.primaryText, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: colors.primaryText,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      hoverColor: colors.primaryText.withValues(alpha: 0.05),
    );
  }
}
