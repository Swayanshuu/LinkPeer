import 'package:flutter/material.dart';
import 'Component/AppColour.dart';
import 'Screens/HomeScreen.dart';
import 'Screens/SearchScreen.dart';
import 'Screens/Post/CreatePostScreen.dart';
import 'Screens/Profile/ProfileScreen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;

  final screens = const [
    HomeScreen(),
    Searchscreen(),
    CreatePostScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColours.bgColor,

      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (value) {
          setState(() {
            currentIndex = value;
          });
        },
        backgroundColor: AppColours.cardColor,
        selectedItemColor: AppColours.primaryText,
        unselectedItemColor: AppColours.secondaryText,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: "Post",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }
}