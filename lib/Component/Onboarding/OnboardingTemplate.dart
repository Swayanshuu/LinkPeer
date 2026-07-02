import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:url_launcher/url_launcher.dart';

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
                height: media.height * 0.32,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: colors.bgColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.hub_rounded,
                            color: colors.primaryText,
                            size: 20,
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            "Built for the next generation",
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    AnimatedTextKit(
                      repeatForever: true,
                      animatedTexts: [
                        TypewriterAnimatedText(
                          speed: const Duration(milliseconds: 100),
                          "Networking",
                          textStyle: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: colors.primaryText,
                          ),
                        ),
                        TypewriterAnimatedText(
                          speed: const Duration(milliseconds: 100),
                          "Growth",
                          textStyle: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: colors.primaryText,
                          ),
                        ),
                        TypewriterAnimatedText(
                          speed: const Duration(milliseconds: 100),
                          "Opportunities",
                          textStyle: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: colors.primaryText,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Tag("Alumni"),
                        _Tag("Careers"),
                        _Tag("Campus"),
                        _Tag("Faculty"),
                        _Tag("Growth"),
                        _Tag("Community"),
                      ],
                    ),

                    const Spacer(),

                    Row(
                      children: [
                        Icon(
                          Icons.people_alt_outlined,
                          size: 16,
                          color: colors.secondaryText,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          "Students • Alumni • Faculty",
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
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
                        colors.borderColor, // slight light top fade
                        colors.cardColor, // center card tone
                        colors.bgColor, // blends into background
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "One community,\nendless possibilities",
                          style: TextStyle(
                            color: colors.primaryText,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          "Connect with students, alumni and faculty.\nDiscover opportunities and grow together.",
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 28),

                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _FeatureChip(
                              icon: Icons.people_outline,
                              text: "Network",
                            ),
                            _FeatureChip(
                              icon: Icons.work_outline,
                              text: "Jobs",
                            ),
                            _FeatureChip(
                              icon: Icons.school_outlined,
                              text: "Campus",
                            ),
                            _FeatureChip(
                              icon: Icons.emoji_events_outlined,
                              text: "Achievements",
                            ),
                            _FeatureChip(
                              icon: Icons.notifications_outlined,
                              text: "Updates",
                            ),
                            _FeatureChip(
                              icon: Icons.person_outline,
                              text: "Profile",
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.cardColor,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: colors.borderColor),
                          ),
                          child: Text(
                            "Designed to help every student build connections, discover opportunities, and grow beyond campus.",
                            style: TextStyle(
                              color: colors.secondaryText,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                        ),

                        const Spacer(),

                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colors.cardColor,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: colors.borderColor),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swipe_rounded,
                                  size: 18,
                                  color: colors.secondaryText,
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  "Swipe to continue",
                                  style: TextStyle(
                                    color: colors.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: colors.secondaryText,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                const TextSpan(text: "Powered by "),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: GestureDetector(
                                    onTap: () async {
                                      final uri = Uri.parse(
                                        "https://swynx.dev",
                                      );
                                      await launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    },
                                    child: Text(
                                      "swynx.dev",
                                      style: TextStyle(
                                        color: const Color(
                                          0xFF6366F1,
                                        ), // Indigo
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
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

class _Tag extends StatelessWidget {
  final String text;

  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: colors.primaryText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(text)],
      ),
    );
  }
}
