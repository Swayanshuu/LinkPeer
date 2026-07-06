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
    _internetSubscription = InternetConnection().onStatusChange.listen((status) {
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
    final colors = AppColors.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text("No internet connection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
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
    final colors = AppColors.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Text("Back online", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
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

      body: IndexedStack(index: currentIndex, children: screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (value) {
          setState(() {
            currentIndex = value;
          });
        },
        backgroundColor: colors.cardColor,
        selectedItemColor: colors.primaryText,
        unselectedItemColor: colors.secondaryText,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Home",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: "Post",
          ),
          BottomNavigationBarItem(
            icon: photoUrl != null && photoUrl.isNotEmpty
                ? CircleAvatar(
                    radius: 12,
                    backgroundImage: NetworkImage(photoUrl),
                    backgroundColor: colors.borderColor,
                  )
                : const Icon(Icons.person_outline),
            activeIcon: photoUrl != null && photoUrl.isNotEmpty
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.primaryText, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 11,
                      backgroundImage: NetworkImage(photoUrl),
                      backgroundColor: colors.borderColor,
                    ),
                  )
                : const Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}
