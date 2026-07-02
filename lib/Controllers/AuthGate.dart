import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Component/app_colors.dart';
import '../Controllers/PostProvider.dart';
import '../Controllers/UserProvider.dart';
import '../Screens/LogInScreen2.dart';
import '../MainScreen.dart';
import '../Screens/OnBoardingScreen.dart';

class AuthGate extends ConsumerStatefulWidget {
  final String userMode;

  const AuthGate({super.key, required this.userMode});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    await Future.delayed(const Duration(seconds: 3));

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    ref.invalidate(userProvider);
    ref.invalidate(postsProvider);

    // Not logged in
    if (user == null) {
      _openLogin();
      return;
    }

    final uid = user.uid;

    final prefs = await SharedPreferences.getInstance();

    // Local quick check
    final localCompleted = prefs.getBool('profile_completed_$uid') ?? false;

    if (localCompleted) {
      _openMainScreen();
      return;
    }

    // DB fallback check
    final userData = await ref.read(userProvider.future);

    final isProfileCompleted = userData['profile_completed'] == true;

    if (isProfileCompleted) {
      await prefs.setBool('profile_completed_$uid', true);
      _openMainScreen();
    } else {
      _openOnboarding();
    }
  }

  void _openLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen2()),
    );
  }

  void _openOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OnBoardingscreen(userMode: widget.userMode),
      ),
    );
  }

  void _openMainScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.bgColor,
      body: Stack(
        children: [
          /// Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.bgColor, colors.cardColor],
              ),
            ),
          ),

          /// Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Logo Circle
                  Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                      color: colors.cardColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.08),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Image.asset(
                          'assets/images/LinkPeer.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// Brand
                  Text(
                    "LinkPeer",
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "One Community. Endless Possibilities.",
                    style: TextStyle(color: colors.secondaryText, fontSize: 14),
                  ),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const LinearProgressIndicator(minHeight: 6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Bottom Text
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              "Connecting Students • Alumni • Faculty",
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
