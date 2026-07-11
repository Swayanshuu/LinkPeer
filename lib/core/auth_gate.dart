import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/post_provider.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/screens/auth/login_screen.dart';
import 'package:igit_connects/main_screen.dart';
import 'package:igit_connects/screens/onboarding/onboarding_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  final String userMode;

  const AuthGate({super.key, required this.userMode});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  double _progress = 0.0;
  bool _initCompleted = false;
  void Function()? _nextNavigation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressAnimation =
        Tween<double>(begin: 0.0, end: 0.99).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        )..addListener(() {
          setState(() {
            _progress = _progressAnimation.value;
          });
        });

    _animationController.forward().then((_) {
      _checkAndNavigate();
    });

    _initApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initApp() async {
    // Yield to the event loop so that initState() finishes before we make any ref calls
    await Future.delayed(Duration.zero);
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (!mounted) return;

      ref.invalidate(userProvider);
      ref.invalidate(postsProvider);

      // Not logged in
      if (user == null) {
        debugPrint(
          "AuthGate: No authenticated user found, redirecting to login.",
        );
        _nextNavigation = _openLogin;
      } else if (user.isAnonymous) {
        debugPrint("AuthGate: Anonymous user, redirecting to main screen.");
        _nextNavigation = _openMainScreen;
      } else {
        final uid = user.uid;
        final prefs = await SharedPreferences.getInstance();

        // Local quick check
        final localCompleted = prefs.getBool('profile_completed_$uid') ?? false;

        if (localCompleted) {
          debugPrint(
            "AuthGate: Local profile completed for uid: $uid, redirecting to main screen.",
          );
          _nextNavigation = _openMainScreen;
        } else {
          // DB fallback check
          try {
            debugPrint(
              "AuthGate: Fetching user data from database for uid: $uid",
            );
            final userData = await ref.read(userProvider.future);
            final isProfileCompleted = userData['profile_completed'] == true;

            if (isProfileCompleted) {
              await prefs.setBool('profile_completed_$uid', true);
              debugPrint(
                "AuthGate: DB profile completed, redirecting to main screen.",
              );
              _nextNavigation = _openMainScreen;
            } else {
              debugPrint(
                "AuthGate: DB profile not completed, redirecting to onboarding.",
              );
              _nextNavigation = _openOnboarding;
            }
          } catch (dbError, stackTrace) {
            debugPrint("AuthGate: DB check error: $dbError");
            debugPrint("Stack trace: $stackTrace");
            // If the user profile fetch fails but user is logged in, redirect to onboarding to complete profile
            _nextNavigation = _openOnboarding;
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint("AuthGate: General error: $e");
      debugPrint("Stack trace: $stackTrace");
      _nextNavigation = _openLogin;
    }

    _initCompleted = true;
    _checkAndNavigate();
  }

  void _checkAndNavigate() async {
    if (_initCompleted && _animationController.isCompleted) {
      // Hold at 99% briefly for user satisfaction
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted && _nextNavigation != null) {
        _nextNavigation!();
      }
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

  String _getLoadingStatus() {
    if (_progress < 0.3) {
      return "Connecting to LinkPeer...";
    } else if (_progress < 0.6) {
      return "Synchronizing community feed...";
    } else if (_progress < 0.85) {
      return "Securing account credentials...";
    } else if (_progress < 0.99) {
      return "Finalizing layout...";
    } else {
      return "Ready!";
    }
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
                          color: Colors.black.withValues(alpha: 0.08),
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

                  /// Modern Percentage Loading Bar using theme AppColors
                  SizedBox(
                    width: 240,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getLoadingStatus(),
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "${(_progress * 100).toInt()}%",
                              style: TextStyle(
                                color: colors.primaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 4,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: colors.borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Stack(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 100),
                                    width: constraints.maxWidth * _progress,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: colors.primaryText,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
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
