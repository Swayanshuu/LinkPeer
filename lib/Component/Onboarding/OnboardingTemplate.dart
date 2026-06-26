import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../app_colors.dart';


class ExactOnboardingUI extends StatelessWidget {
  const ExactOnboardingUI({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: colors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            /// TOP CARD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Container(
                width: double.infinity,
                height: media.height * 0.30,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colors.borderColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Built for",
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 15,
                      ),
                    ),

                    const Spacer(),

                    AnimatedTextKit(
                      repeatForever: true,
                      pause: const Duration(milliseconds: 600),
                      animatedTexts: [
                        TypewriterAnimatedText(
                          "Coding",
                          speed: const Duration(milliseconds: 120),
                          textStyle: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                        TypewriterAnimatedText(
                          "Writing",
                          speed: const Duration(milliseconds: 120),
                          textStyle: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                        TypewriterAnimatedText(
                          "Learning",
                          speed: const Duration(milliseconds: 120),
                          textStyle: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: colors.primaryText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "and much more...",
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            /// BOTTOM CARD
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.08, 1.0],
                      colors: [
                        colors.borderColor,   // slight light top fade
                        colors.cardColor,     // center card tone
                        colors.bgColor,       // blends into background
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Your campus network,\nmade simple",
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          "Connect, share, discover jobs,\nannouncements and internships\nin one calm, powerful workspace.",
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 17,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 26),

                        Text(
                          "• Discover jobs & internships\n"
                              "• Campus announcements\n"
                              "• Connect with alumni & faculty\n"
                              "• Share your achievements\n"
                              "• Stay updated in real-time\n"
                              "• Build your campus profile",
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 16,
                            height: 1.8,
                          ),
                        ),

                        const SizedBox(height: 28),

                        Text(
                          "Designed with clarity, speed, and focus — so your campus life feels effortless.",
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),

                        const Spacer()
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}