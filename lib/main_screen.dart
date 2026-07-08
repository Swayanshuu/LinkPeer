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
import 'package:igit_connects/screens/bookmarks/bookmarks_screen.dart';
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
    BookmarksScreen(),
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
      extendBody:
          true, // This makes the notch gap transparent (shows content behind)
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
                    if (currentIndex != 2)
                      const SizedBox(width: 350, child: CreatePostScreen()),
                  ],
                )
              : IndexedStack(index: currentIndex, children: screens);

          return content;
        },
      ),
      floatingActionButton: _buildFab(colors),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(colors, photoUrl),
    );
  }

  Widget _buildFab(AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(top: 30), // Lowers the FAB slightly
      child: FloatingActionButton(
        onPressed: () {
          setState(() => currentIndex = 2);
        },
        backgroundColor: colors.primaryAccent,
        elevation: 4,
        shape: const CircleBorder(),
        child: Icon(Icons.add, color: colors.onPrimaryAccent, size: 28),
      ),
    );
  }

  Widget _buildBottomNav(AppColors colors, String? photoUrl) {
    return BottomAppBar(
      color: colors.cardColor,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 10,
      padding: EdgeInsets.zero,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: colors.borderColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              Icons.home_filled,
              Icons.home_outlined,
              0,
              "Home",
              colors,
            ),
            _buildNavItem(
              Icons.search,
              Icons.search_outlined,
              1,
              "Explore",
              colors,
            ),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(
              Icons.bookmark,
              Icons.bookmark_outline,
              3,
              "Bookmarks",
              colors,
            ),
            _buildProfileNavItem(photoUrl, 4, "Profile", colors),
          ],
        ),
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
    final activeColor = const Color(0xFF3B82F6);

    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? activeColor : colors.secondaryText,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : colors.secondaryText,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
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
    final activeColor = const Color(0xFF3B82F6);

    return GestureDetector(
      onTap: () => setState(() => currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: isSelected
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: activeColor, width: 2),
                    )
                  : null,
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? CircleAvatar(
                      radius: isSelected ? 10 : 12,
                      backgroundImage: NetworkImage(photoUrl),
                      backgroundColor: colors.borderColor,
                    )
                  : Icon(
                      isSelected ? Icons.person : Icons.person_outline,
                      color: isSelected ? activeColor : colors.secondaryText,
                      size: 24,
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : colors.secondaryText,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
