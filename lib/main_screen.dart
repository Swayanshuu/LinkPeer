import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/core/post_provider.dart';
import 'package:igit_connects/screens/home/home_screen.dart';
import 'package:igit_connects/screens/search/search_screen.dart';
import 'package:igit_connects/screens/post/create_post_screen.dart';
import 'package:igit_connects/screens/profile/profile_screen.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/shared_components/app_drawer.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int currentIndex = 0;

  final screens = const [
    HomeScreen(),
    Searchscreen(),
    CreatePostScreen(),
    ProfileScreen(),
  ];

  StreamSubscription<InternetStatus>? _internetSubscription;
  bool _isDisconnected = false;

  @override
  void initState() {
    super.initState();
    _internetSubscription = InternetConnection().onStatusChange.listen((
      status,
    ) {
      if (status == InternetStatus.disconnected) {
        setState(() => _isDisconnected = true);
        _showNoInternetPopup();
      } else if (status == InternetStatus.connected && _isDisconnected) {
        setState(() => _isDisconnected = false);
        _showBackOnlinePopup();

        // Automatically fetch the latest data when internet is restored
        ref.invalidate(userProvider);
        ref.invalidate(postsProvider);
      }
    });
  }

  @override
  void dispose() {
    _internetSubscription?.cancel();
    super.dispose();
  }

  void _showNoInternetPopup() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text(
              "No internet connection",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 365), // Persistent until reconnected
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showBackOnlinePopup() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text(
              "Back online",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = ref.watch(userProvider);
    final photoUrl = user.value?['photo_url'] as String?;

    return Scaffold(
      backgroundColor: colors.bgColor,
      resizeToAvoidBottomInset:
          false, // Prevents nav bar from moving above keyboard
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 1024;

          Widget content = isDesktop
              ? Row(
                  children: [
                    const SizedBox(width: 280, child: AppDrawer()),
                    Expanded(
                      child: IndexedStack(
                        index: currentIndex,
                        children: screens,
                      ),
                    ),
                    const SizedBox(width: 350, child: CreatePostScreen()),
                  ],
                )
              : IndexedStack(index: currentIndex, children: screens);

          return Stack(
            children: [
              content,

              // Floating Navigation Bar
              Positioned(
                bottom: 50,
                left: isDesktop ? 280 + 20 : 20,
                right: isDesktop ? 350 + 20 : 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: colors.cardColor.withValues(
                        alpha: 0.92,
                      ), // A little transparent
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: colors.borderColor.withValues(alpha: 0.6),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.08,
                          ), // Removed glow, subtle professional shadow
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNavItem(
                          Icons.home_filled,
                          Icons.home_outlined,
                          0,
                          "Home",
                          colors,
                        ),
                        const SizedBox(width: 30),
                        _buildNavItem(
                          Icons.search,
                          Icons.search_outlined,
                          1,
                          "Search",
                          colors,
                        ),
                        const SizedBox(width: 30),
                        _buildNavItem(
                          Icons.add_box,
                          Icons.add_box_outlined,
                          2,
                          "Post",
                          colors,
                        ),
                        const SizedBox(width: 30),
                        _buildProfileNavItem(photoUrl, 3, "Profile", colors),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
    IconData activeIcon,
    IconData inactiveIcon,
    int index,
    String label,
    AppColors colors,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        child: Icon(
          isSelected ? activeIcon : inactiveIcon,
          color: isSelected ? colors.primaryText : colors.secondaryText,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildProfileNavItem(
    String? photoUrl,
    int index,
    String label,
    AppColors colors,
  ) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(4),
        decoration: isSelected
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: colors.primaryText, width: 2),
              )
            : null,
        child: photoUrl != null && photoUrl.isNotEmpty
            ? CircleAvatar(
                radius: isSelected ? 11 : 13,
                backgroundImage: NetworkImage(photoUrl),
                backgroundColor: colors.borderColor,
              )
            : Icon(
                isSelected ? Icons.person : Icons.person_outline,
                color: isSelected ? colors.primaryText : colors.secondaryText,
                size: 28,
              ),
      ),
    );
  }
}
