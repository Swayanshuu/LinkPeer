import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../Component/Onboarding/OnboardingTemplate.dart';
import '../Component/Onboarding/OnboardingUserDetailsScreen.dart';

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

              effect: const ExpandingDotsEffect(
                dotColor: Colors.white38,
                activeDotColor: Colors.white,
                dotHeight: 12,
                dotWidth: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
