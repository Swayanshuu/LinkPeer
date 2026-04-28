import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

import '../AppColour.dart';


class ExactOnboardingUI extends StatelessWidget {
  const ExactOnboardingUI({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColours.bgColor,
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
                  color: AppColours.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColours.borderColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Built for",
                      style: TextStyle(
                        color: AppColours.secondaryText,
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
                          speed: Duration(milliseconds: 120),
                          textStyle: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColours.primaryText,
                          ),
                        ),
                        TypewriterAnimatedText(
                          "Writing",
                          speed: Duration(milliseconds: 120),
                          textStyle: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColours.primaryText,
                          ),
                        ),
                        TypewriterAnimatedText(
                          "Learning",
                          speed: Duration(milliseconds: 120),
                          textStyle: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColours.primaryText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "and much more...",
                      style: TextStyle(
                        color: AppColours.secondaryText,
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
                        const Color(0xff2B2B29), // slight light top fade
                        AppColours.cardColor,   // center card tone
                        AppColours.bgColor,     // blends into background
                      ],
                    ),

                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your AI workspace,\nmade simple",
                          style: TextStyle(
                            color: AppColours.primaryText,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 18),

                        const Text(
                          "Chat, create, code, organize ideas,\nand get answers instantly in one calm,\npowerful workspace.",
                          style: TextStyle(
                            color: AppColours.secondaryText,
                            fontSize: 17,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 26),

                        const Text(
                          "• Instant answers with context\n"
                              "• Smart writing assistance\n"
                              "• Code generation & debugging\n"
                              "• Brainstorming ideas faster\n"
                              "• Summaries in seconds\n"
                              "• Daily productivity support",
                          style: TextStyle(
                            color: AppColours.primaryText,
                            fontSize: 16,
                            height: 1.8,
                          ),
                        ),

                        const SizedBox(height: 28),

                        const Text(
                          "Designed with clarity, speed, and focus — so your work feels effortless every day.",
                          style: TextStyle(
                            color: AppColours.secondaryText,
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