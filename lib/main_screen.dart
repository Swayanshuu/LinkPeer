import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:igit_connects/Screens/bookmarks/bookmarks_screen.dart';
import 'package:igit_connects/Screens/search/search_screen.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/core/post_provider.dart';
import 'package:igit_connects/screens/home/home_screen.dart';
import 'package:igit_connects/screens/profile/profile_screen.dart';
import 'package:igit_connects/features/notices/screens/notice_board_screen.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/shared_components/app_drawer.dart';
import 'package:igit_connects/main.dart'; // Import to access global deep link variables

final isOfflineProvider = StateProvider<bool>((ref) => false);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int currentIndex = 2;

  final screens = const [
    BookmarksScreen(),
    SearchScreen(),
    HomeScreen(),
    NoticeBoardScreen(),
    ProfileScreen(),
  ];

  StreamSubscription<InternetStatus>? _internetSubscription;

  @override
  void initState() {
    super.initState();
    _internetSubscription = InternetConnection().onStatusChange.listen((
      status,
    ) {
      final isOffline = status == InternetStatus.disconnected;
      if (ref.read(isOfflineProvider) != isOffline) {
        ref.read(isOfflineProvider.notifier).state = isOffline;
        if (!isOffline) {
          // Automatically fetch latest data when connection is restored
          ref.invalidate(userProvider);
          ref.invalidate(postsProvider);
        }
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
                  ],
                )
              : IndexedStack(index: currentIndex, children: screens);

          return content;
        },
      ),
      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(colors, photoUrl),
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
            // Bookmark tab
            _buildNavItem(
              Icons.bookmark,
              Icons.bookmark_border,
              0,
              "Bookmark",
              colors,
            ),
            // Explore tab
            _buildNavItem(
              Icons.search,
              Icons.search_outlined,
              1,
              "Explore",
              colors,
            ),
            // Home tab
            _buildNavItem(Icons.home, Icons.home_outlined, 2, "Home", colors),
            // Notices tab
            _buildNavItem(
              Icons.campaign,
              Icons.campaign_outlined,
              3,
              "Notices",
              colors,
            ),
            // Profile tab
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
