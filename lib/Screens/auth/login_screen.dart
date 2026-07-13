import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/auth_gate.dart';
import 'package:igit_connects/core/google_auth_controller.dart';
import 'package:igit_connects/screens/about/privacy_policy_sheet.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          backgroundColor: const Color(0xFFF5F5F5),
          textColor: Colors.black87,
          iconColor: Colors.black87,
        );
        return;
      }

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
        backgroundColor: const Color(0xFFD32F2F),
        textColor: Colors.white,
        iconColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingMode = null; // Reset loading
        });
      }
    }
  }

  Future<void> loginAsGuest() async {
    try {
      setState(() {
        loadingMode = "guest";
      });

      await FirebaseAuth.instance.signInAnonymously();

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
        message: "Unable to continue: ${e.toString()}",
        backgroundColor: const Color(0xFFD32F2F),
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

    Widget buildIllustration() {
      return Container(
        width: double.infinity,
        color: Colors.white,
        child: Image.asset("assets/images/loginscreen.png", fit: BoxFit.cover),
      );
    }

    Widget buildLoginForm(bool isDesktop) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: isDesktop
              ? BorderRadius.zero
              : const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + brand row
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/LinkPeer.png',
                          height: 40,
                          width: 40,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "LinkPeer",
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Welcome back 👋",
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "One Community. Endless Possibilities.",
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        FeatureChip(
                          icon: Icons.people_outline,
                          text: "Network",
                        ),
                        FeatureChip(icon: Icons.work_outline, text: "Career"),
                        FeatureChip(
                          icon: Icons.school_outlined,
                          text: "Campus",
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    /// Student Login
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: loadingMode != null
                            ? null
                            : () => login("student"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: loadingMode == "student"
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text("Signing in..."),
                                ],
                              )
                            : const Text(
                                "Continue as Student / Alumni",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    /// Faculty Card
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: loadingMode != null
                          ? null
                          : () => login("faculty"),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: loadingMode == "faculty"
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text("Verifying faculty..."),
                                ],
                              )
                            : Row(
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    color: colors.primaryText,
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Faculty Login",
                                          style: TextStyle(
                                            color: colors.primaryText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Verification Required",
                                          style: TextStyle(
                                            color: colors.secondaryText,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: colors.secondaryText,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Center(
                    //   child: OutlinedButton.icon(
                    //     onPressed: loadingMode != null ? null : loginAsGuest,
                    //     icon: loadingMode == "guest"
                    //         ? const SizedBox.shrink()
                    //         : Icon(
                    //             Icons.explore_outlined,
                    //             size: 18,
                    //             color: colors.primaryText,
                    //           ),
                    //     label: loadingMode == "guest"
                    //         ? const SizedBox(
                    //             width: 16,
                    //             height: 16,
                    //             child: CircularProgressIndicator(
                    //               strokeWidth: 2,
                    //             ),
                    //           )
                    //         : Text(
                    //             "Continue as Guest",
                    //             style: TextStyle(
                    //               fontWeight: FontWeight.w600,
                    //               fontSize: 14,
                    //               color: colors.primaryText,
                    //             ),
                    //           ),
                    //     style: OutlinedButton.styleFrom(
                    //       foregroundColor: colors.primaryText,
                    //       side: BorderSide(
                    //         color: colors.borderColor,
                    //         width: 1.5,
                    //       ),
                    //       padding: const EdgeInsets.symmetric(
                    //         horizontal: 24,
                    //         vertical: 12,
                    //       ),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(20),
                    //       ),
                    //     ),
                    //   ),
                    // ),

                    // const SizedBox(height: 24),
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
                            const TextSpan(
                              text: "By continuing, you agree to our ",
                            ),
                            TextSpan(
                              text: "Privacy Policy",
                              style: const TextStyle(
                                color: Colors.blue,
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
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 800;
          if (isDesktop) {
            return Row(
              children: [
                Expanded(flex: 6, child: buildIllustration()),
                Expanded(flex: 5, child: buildLoginForm(true)),
              ],
            );
          }
          return Column(
            children: [
              Expanded(flex: 6, child: buildIllustration()),
              Expanded(flex: 5, child: buildLoginForm(false)),
            ],
          );
        },
      ),
    );
  }
}

class FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeatureChip({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgColor,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 14), const SizedBox(width: 6), Text(text)],
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
        //width: 300,
        elevation: 0,
        backgroundColor: backgroundColor,
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 90),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
}
