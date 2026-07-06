import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/user_provider.dart';
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
          const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          const BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
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
