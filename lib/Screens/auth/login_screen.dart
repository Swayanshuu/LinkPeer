import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/auth_gate.dart';
import 'package:igit_connects/core/google_auth_controller.dart';
import 'package:igit_connects/screens/about/privacy_policy_sheet.dart';

class LoginScreen2 extends StatefulWidget {
  const LoginScreen2({super.key});

  @override
  State<LoginScreen2> createState() => _LoginScreen2State();
}

class _LoginScreen2State extends State<LoginScreen2> {
  String? loadingMode;

  Future<void> login(String mode) async {
    try {
      setState(() {
        loadingMode = mode;
      });

      final credential = await Googleauthcontroller.signInWithGoogle();

      if (!mounted) return;

      if (credential == null) {
        showAppSnackBar(
          context: context,
          icon: Icons.info_outline_rounded,
          message: "Sign in cancelled",
          backgroundColor: AppColors.of(context).cardColor,
          textColor: AppColors.of(context).primaryText,
          iconColor: AppColors.of(context).primaryAccent,
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_user_mode', mode);
      if (credential.user != null) {
        await prefs.setString('pending_user_mode_${credential.user!.uid}', mode);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthGate(userMode: mode)),
      );
    } catch (e) {
      if (!mounted) return;

      showAppSnackBar(
        context: context,
        icon: Icons.error_outline_rounded,
        message: "Unable to sign in. Please try again.",
        backgroundColor: Theme.of(context).colorScheme.error,
        textColor: Colors.white,
        iconColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingMode = null;
        });
      }
    }
  }

  Future<void> loginAsGuest() async {
    try {
      setState(() {
        loadingMode = "guest";
      });

      final userCred = await FirebaseAuth.instance.signInAnonymously();

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_user_mode', 'guest');
      if (userCred.user != null) {
        await prefs.setString('pending_user_mode_${userCred.user!.uid}', 'guest');
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthGate(userMode: "guest")),
      );
    } catch (e) {
      if (!mounted) return;
      debugPrint("Guest Login Error: $e");

      showAppSnackBar(
        context: context,
        icon: Icons.error_outline_rounded,
        message: "Unable to continue. Please try again.",
        backgroundColor: Theme.of(context).colorScheme.error,
        textColor: Colors.white,
        iconColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingMode = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    Widget buildLoginForm() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand Logo & Name Header
            Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/LinkPeer.png',
                    height: 38,
                    width: 38,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                AutoSizeText(
                  "LinkPeer",
                  maxLines: 1,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            AutoSizeText(
              "Welcome back",
              maxLines: 1,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 6),

            AutoSizeText(
              "Connect with students, alumni & faculty in one space.",
              maxLines: 2,
              minFontSize: 12,
              maxFontSize: 14,
              style: TextStyle(color: colors.secondaryText, height: 1.4),
            ),

            const SizedBox(height: 32),

            /// Unified Google Sign-in CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: loadingMode != null ? null : () => login("user"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  foregroundColor: colors.onPrimaryAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: loadingMode != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: colors.onPrimaryAccent,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          AutoSizeText(
                            "Signing in...",
                            maxLines: 1,
                            style: TextStyle(
                              color: colors.onPrimaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AutoSizeText(
                            "Continue with Google",
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colors.onPrimaryAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: colors.onPrimaryAccent,
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 28),

            // Terms & Privacy Note
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(text: "By continuing, you agree to our "),
                    TextSpan(
                      text: "Privacy Policy",
                      style: TextStyle(
                        color: colors.primaryAccent,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const PrivacyPolicySheet(),
                          );
                        },
                    ),
                    const TextSpan(text: " and Community Guidelines."),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgColor,
      body: Stack(
        children: [
          /// Full-Screen Background Image (Consistent Center Focus across all Mobile Screens)
          Positioned.fill(
            child: ClipRect(
              child: Transform.scale(
                scale: 1,
                alignment: Alignment.center,
                child: Image.asset(
                  "assets/images/loginscreen.png",
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),

          /// Background Tint Overlay for Optimal Contrast
          Positioned.fill(
            child: Container(color: colors.bgColor.withValues(alpha: 0.72)),
          ),

          /// Floating Overlaid Login Card Above
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: buildLoginForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showAppSnackBar({
  required BuildContext context,
  required IconData icon,
  required String message,
  required Color backgroundColor,
  required Color textColor,
  required Color iconColor,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: backgroundColor,
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: AutoSizeText(
                message,
                maxLines: 2,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
}
