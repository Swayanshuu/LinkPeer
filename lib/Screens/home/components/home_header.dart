import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/services/notification_service.dart';
import 'package:igit_connects/Screens/notifications/notification_screen.dart';
import 'package:igit_connects/core/update/update_provider.dart';
import 'package:igit_connects/features/update/screens/app_update_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeHeader extends ConsumerWidget {
  final Map me;

  const HomeHeader({super.key, required this.me});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning,";
    if (hour < 17) return "Good Afternoon,";
    return "Good Evening,";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final String photoUrl = me["photo_url"]?.toString() ?? "";
    final String name = me["name"]?.toString() ?? "User";
    final firstName = name.split(' ').first;
    final updateState = ref.watch(updateProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Side: Avatar and Greeting
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primaryAccent.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage: photoUrl.isNotEmpty
                      ? CachedNetworkImageProvider(photoUrl)
                      : null,
                  backgroundColor: colors.cardColor,
                  child: photoUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          color: colors.secondaryText,
                          size: 24,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  firstName,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right Side: Update and Notification Icons
        Row(
          children: [
            // Update Icon
            if (updateState.value?.hasUpdate == true)
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Tooltip(
                    message: "Update Available",
                    child: GestureDetector(
                      onTap: () {
                        final updateInfo = updateState.value?.updateInfo;
                        if (updateInfo != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AppUpdateScreen(updateInfo: updateInfo),
                            ),
                          );
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primaryAccent.withValues(alpha: 0.1),
                              border: Border.all(
                                color: colors.primaryAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.system_update_alt_rounded,
                              color: colors.primaryAccent,
                              size: 20,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.bgColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            // Notification Icon
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.cardColor,
                border: Border.all(
                  color: colors.borderColor.withValues(alpha: 0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: FutureBuilder<int>(
                future: NotificationService().getUnreadCount(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.notifications_none_rounded,
                          color: colors.primaryText,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const NotificationScreen()),
                          );
                        },
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        padding: EdgeInsets.zero,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }
              ),
            ),
          ],
        ),
      ],
    );
  }
}
