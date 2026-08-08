import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:igit_connects/Screens/onboarding/components/onboarding_template.dart';
import 'package:igit_connects/Screens/onboarding/components/onboarding_user_details_screen.dart';

class OnBoardingscreen extends StatefulWidget {
  final String userMode;

  const OnBoardingscreen({super.key, required this.userMode});

  @override
  State<OnBoardingscreen> createState() => _OnBoardingscreenState();
}

class _OnBoardingscreenState extends State<OnBoardingscreen> {
  final PageController controller = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = controller.page?.round() ?? 0;
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  void dispose() {
    controller.removeListener(_onPageChanged);
    controller.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page >= 0 && page <= 3) {
      controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _goToPage(_currentPage + 1);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: colors.bgColor,
        body: Row(
          children: [
            Expanded(child: OnboardingSlideWelcome(onNext: () {})),
            Container(width: 1, color: colors.borderColor),
            Expanded(
              child: OnboardingUserDetailsScreen(userMode: widget.userMode),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Subtle 4-Step Progress Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.borderColor),
              ),
              child: SmoothPageIndicator(
                controller: controller,
                count: 4,
                effect: ExpandingDotsEffect(
                  dotColor: colors.borderColor,
                  activeDotColor: colors.primaryAccent,
                  dotHeight: 6,
                  dotWidth: 6,
                  expansionFactor: 3,
                  spacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // 4-Screen PageView Flow
            Expanded(
              child: PageView(
                controller: controller,
                physics: isDesktop
                    ? const NeverScrollableScrollPhysics()
                    : null,
                children: [
                  // Screen 1 — Welcome
                  OnboardingSlideWelcome(onNext: _nextPage),

                  // Screen 2 — Connect
                  OnboardingSlideConnect(onNext: _nextPage),

                  // Screen 3 — Discover
                  OnboardingSlideDiscover(onNext: _nextPage),

                  // Screen 4 — Join & Profile Setup
                  OnboardingUserDetailsScreen(
                    userMode: widget.userMode,
                    onPrev: _prevPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
