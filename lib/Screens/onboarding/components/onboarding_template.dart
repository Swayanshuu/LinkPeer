import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:igit_connects/core/app_colors.dart';

/// Screen 1 — Welcome Slide (Rich Notion-Inspired Layout with App Logo)
class OnboardingSlideWelcome extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingSlideWelcome({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingSlideTemplate(
      headline: "Your campus.\nYour network.",
      supportingText:
          "Connect with students, alumni, faculty, and opportunities from your college community.",
      visual: const _StaticNetworkLogoVisual(),
      ctaText: "Get Started",
      highlights: const [
        "Verified Community",
        "Direct Mentorship",
        "Campus Opportunities",
      ],
      onNext: onNext,
    );
  }
}

/// Screen 2 — Connect Slide (Rich Notion-Inspired Profile Rows)
class OnboardingSlideConnect extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingSlideConnect({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingSlideTemplate(
      headline: "Meet people\nwho matter.",
      supportingText:
          "Discover people from your campus, connect with seniors, alumni, and peers, and grow your network.",
      visual: const _NotionProfileCardsVisual(),
      ctaText: "Continue",
      highlights: const [
        "Peer Connections",
        "Alumni Directory",
        "Faculty Access",
      ],
      onNext: onNext,
    );
  }
}

/// Screen 3 — Discover Slide (Rich Notion-Inspired Feed Card)
class OnboardingSlideDiscover extends StatelessWidget {
  final VoidCallback onNext;

  const OnboardingSlideDiscover({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return _OnboardingSlideTemplate(
      headline: "Explore your\ncommunity.",
      supportingText:
          "Share ideas, discover projects, find opportunities, and stay updated with what’s happening around your campus.",
      visual: const _NotionFeedCardsVisual(),
      ctaText: "Continue",
      highlights: const ["Campus Events", "Project Showcase", "Career Updates"],
      onNext: onNext,
    );
  }
}

/// Base Notion-Inspired Slide Template (Rich, Balanced & Non-Empty Layout)
class _OnboardingSlideTemplate extends StatelessWidget {
  final String headline;
  final String supportingText;
  final Widget visual;
  final String ctaText;
  final List<String> highlights;
  final VoidCallback onNext;

  const _OnboardingSlideTemplate({
    required this.headline,
    required this.supportingText,
    required this.visual,
    required this.ctaText,
    required this.highlights,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top App Logo Brand Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/LinkPeer.png',
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AutoSizeText(
                    "LinkPeer",
                    maxLines: 1,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Headline
            AutoSizeText(
              headline,
              maxLines: 2,
              minFontSize: 24,
              maxFontSize: 30,
              style: TextStyle(
                color: colors.primaryText,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                height: 1.15,
              ),
            ),

            const SizedBox(height: 8),

            // Supporting Text
            AutoSizeText(
              supportingText,
              maxLines: 3,
              minFontSize: 12,
              maxFontSize: 14,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),

            const SizedBox(height: 20),

            // Central Rich Visual Area
            Expanded(child: Center(child: visual)),

            const SizedBox(height: 20),

            // Feature Highlight Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: highlights.map((h) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 13,
                            color: colors.primaryAccent,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            h,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // Bottom Primary CTA Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  foregroundColor: colors.onPrimaryAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AutoSizeText(
                      ctaText,
                      maxLines: 1,
                      style: TextStyle(
                        color: colors.onPrimaryAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );

    if (isDesktop) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: content,
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.bgColor,
      body: SafeArea(child: content),
    );
  }
}

/// Screen 1 Visual — Rich LinkPeer Logo & Network Showcase
class _StaticNetworkLogoVisual extends StatelessWidget {
  const _StaticNetworkLogoVisual();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Image.asset(
                  'assets/images/LinkPeer.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "LinkPeer Campus Network",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "One unified hub for your college community",
            style: TextStyle(color: colors.secondaryText, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CommunityBadge(
                icon: Icons.school_outlined,
                label: "Students",
                colors: colors,
              ),
              const SizedBox(width: 8),
              _CommunityBadge(
                icon: Icons.workspace_premium_outlined,
                label: "Alumni",
                colors: colors,
              ),
              const SizedBox(width: 8),
              _CommunityBadge(
                icon: Icons.local_library_outlined,
                label: "Faculty",
                colors: colors,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CommunityBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;

  const _CommunityBadge({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.primaryAccent),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen 2 Visual — Rich Notion Profile Preview Cards
class _NotionProfileCardsVisual extends StatelessWidget {
  const _NotionProfileCardsVisual();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ProfileRowCard(
          name: "Swayanshu",
          role: "Software Engineer @ LinkPeer",
          badge: "Alumni • CSE '24",
          imageAsset: "assets/images/codex.jpeg",
          colors: colors,
        ),
        const SizedBox(height: 10),
        _ProfileRowCard(
          name: "Priya Dash",
          role: "Building AI & Robotics",
          badge: "Student • EE '25",
          imageAsset: "assets/images/LinkPeer.png",
          colors: colors,
        ),
        const SizedBox(height: 10),
        _ProfileRowCard(
          name: "Dr. R. K. Sahoo",
          role: "Department Head • Mech",
          badge: "Faculty",
          imageAsset: "assets/images/LinkPeer.png",
          colors: colors,
        ),
      ],
    );
  }
}

class _ProfileRowCard extends StatelessWidget {
  final String name;
  final String role;
  final String badge;
  final String imageAsset;
  final AppColors colors;

  const _ProfileRowCard({
    required this.name,
    required this.role,
    required this.badge,
    required this.imageAsset,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.cardColor,
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderColor),
            ),
            child: ClipOval(
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/LinkPeer.png',
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      badge,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  role,
                  style: TextStyle(color: colors.secondaryText, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen 3 Visual — Rich Notion Campus Feed Card
class _NotionFeedCardsVisual extends StatelessWidget {
  const _NotionFeedCardsVisual();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.borderColor),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/codex.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/LinkPeer.png',
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Swayanshu Sarthak",
                    style: TextStyle(
                      color: colors.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "15m ago • Campus Project Lead",
                    style: TextStyle(color: colors.secondaryText, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Annual Hackathon & Project Showcase 🚀",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Registration is open! Team up with peers, get alumni mentorship, and present your ideas.",
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Text(
                  "Opportunities",
                  style: TextStyle(
                    color: colors.primaryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 14,
                    color: colors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "42",
                    style: TextStyle(color: colors.secondaryText, fontSize: 11),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 14,
                    color: colors.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "12",
                    style: TextStyle(color: colors.secondaryText, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fallback compatibility class
class ExactOnboardingUI extends StatelessWidget {
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final bool hideNextButton;

  const ExactOnboardingUI({
    super.key,
    this.onNext,
    this.onPrev,
    this.hideNextButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return OnboardingSlideWelcome(onNext: onNext ?? () {});
  }
}
