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
import 'package:igit_connects/shared_components/custom_snackbar.dart';
import 'package:igit_connects/main.dart'; // Import to access global deep link variables

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
  final ValueNotifier<bool> _isDisconnected = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _internetSubscription = InternetConnection().onStatusChange.listen((
      status,
    ) {
      if (status == InternetStatus.disconnected) {
        if (!_isDisconnected.value) {
          _isDisconnected.value = true;
          _showNoInternetPopup();
        }
      } else if (status == InternetStatus.connected && _isDisconnected.value) {
        _isDisconnected.value = false;
        _showBackOnlinePopup();

        // Automatically fetch the latest data when internet is restored
        ref.invalidate(userProvider);
        ref.invalidate(postsProvider);
      }
    });

    // Handle deep links that came in during cold start
    isMainScreenReady = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pendingDeepLinkAction != null) {
        pendingDeepLinkAction!();
        pendingDeepLinkAction = null;
      }
    });
  }

  @override
  void dispose() {
    _internetSubscription?.cancel();
    super.dispose();
  }

  void _showNoInternetPopup() {
    CustomSnackBar.show(
      context,
      message: "No internet connection",
      isError: true,
    );
  }

  void _showBackOnlinePopup() {
    CustomSnackBar.show(
      context,
      message: "Back online",
      isError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = ref.watch(userProvider);
    final photoUrl = user.value?['photo_url'] as String?;

    return Scaffold(
      backgroundColor: colors.bgColor,
      drawer: const AppDrawer(), // Added drawer here to cover bottom nav bar
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
