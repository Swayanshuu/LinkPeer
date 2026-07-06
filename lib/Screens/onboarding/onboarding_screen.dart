import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:igit_connects/screens/onboarding/components/onboarding_template.dart';
import 'package:igit_connects/screens/onboarding/components/onboarding_user_details_screen.dart';

class OnBoardingscreen extends StatefulWidget {
  final String userMode;

  const OnBoardingscreen({super.key, required this.userMode});

  @override
  State<OnBoardingscreen> createState() => _OnBoardingscreenState();
}

class _OnBoardingscreenState extends State<OnBoardingscreen> {
  final PageController controller = PageController();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          PageView(
            controller: controller,

            children: [
              const ExactOnboardingUI(),

              OnboardingUserDetailsScreen(userMode: widget.userMode),
            ],
          ),

          Align(
            alignment: const Alignment(0, -0.85),

            child: SmoothPageIndicator(
              controller: controller,
              count: 2,

              effect: ExpandingDotsEffect(
                dotColor: colors.borderColor,
                activeDotColor: colors.primaryText,
                dotHeight: 8,
                dotWidth: 8,
                expansionFactor: 4,
                spacing: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
