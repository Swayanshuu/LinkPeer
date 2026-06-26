import 'package:flutter/material.dart';

import '../Component/app_colors.dart';
import '../Controllers/AuthGate.dart';
import '../Controllers/GoogleAuthController.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool loading = false;

  Future<void> login(String mode) async {
    try {
      setState(() {
        loading = true;
      });

      await Googleauthcontroller.signInWithGoogle();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => AuthGate(userMode: mode)),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: $e")));
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.bgColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              const Spacer(),

              Icon(Icons.school, size: 90, color: colors.primaryText),

              const SizedBox(height: 18),

              Text(
                "IGIT Connects",
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                "Connect Students, Alumni & Faculty",
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.secondaryText, fontSize: 15),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton(
                  onPressed: loading ? null : () => login("student"),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryText,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: loading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        )
                      : const Text(
                          "Student / Alumni Login",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 56,

                child: OutlinedButton(
                  onPressed: loading ? null : () => login("faculty"),

                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: Text(
                    "Faculty Login",
                    style: TextStyle(
                      color: colors.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                "By continuing you agree to community guidelines.",
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.secondaryText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
