import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Component/app_colors.dart';
import '../Controllers/PostProvider.dart';
import '../Controllers/UserProvider.dart';
import '../Screens/LogInScreen.dart';
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _openOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => OnBoardingscreen(userMode: widget.userMode)),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, size: 70, color: colors.primaryText),

              const SizedBox(height: 18),

              Text(
                "IGIT Connects",
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                "Connecting Students & Alumni",
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.secondaryText),
              ),

              const SizedBox(height: 30),

              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: const LinearProgressIndicator(minHeight: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
