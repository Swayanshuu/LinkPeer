import 'package:flutter/material.dart';

import '../Component/AppColour.dart';
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
    return Scaffold(
      backgroundColor: AppColours.bgColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              const Spacer(),

              const Icon(Icons.school, size: 90, color: AppColours.primaryText),

              const SizedBox(height: 18),

              const Text(
                "IGIT Connects",
                style: TextStyle(
                  color: AppColours.primaryText,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Connect Students, Alumni & Faculty",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColours.secondaryText, fontSize: 15),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,

                child: ElevatedButton(
                  onPressed: loading ? null : () => login("student"),

                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColours.primaryText,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
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
                    side: const BorderSide(color: AppColours.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: const Text(
                    "Faculty Login",
                    style: TextStyle(
                      color: AppColours.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                "By continuing you agree to community guidelines.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColours.secondaryText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
