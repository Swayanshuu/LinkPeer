import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/about/about_providers.dart';
import 'package:igit_connects/core/about/developer_profile_model.dart';
import 'package:igit_connects/core/about/support_links_model.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString.isEmpty) return;
    try {
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Could not open link")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final devProfileAsync = ref.watch(developerProfileProvider);
    final supportLinksAsync = ref.watch(supportLinksProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        backgroundColor: colors.bgColor,
        surfaceTintColor: colors.bgColor,
        title: Text(
          "About",
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: colors.primaryText),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            _buildAppHeader(colors),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildDeveloperCard(colors, devProfileAsync),
                  const SizedBox(height: 24),

                  _buildSpecialThanks(colors),
                  const SizedBox(height: 24),
                  _buildAboutLinkPeer(colors),
                  // const SizedBox(height: 24),
                  // _buildAppStatistics(colors),
                  const SizedBox(height: 24),
                  _buildCommunitySection(colors),
                  const SizedBox(height: 24),
                  _buildSupportLegalCard(colors, supportLinksAsync),
                  const SizedBox(height: 24),
                  _buildSwynxCard(colors),
                  const SizedBox(height: 48),
                  _buildFooter(colors),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section 1: App Header
  Widget _buildAppHeader(AppColors colors) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Hero(
          tag: 'about_logo',
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primaryAccent.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              image: const DecorationImage(
                image: AssetImage('assets/images/LinkPeer.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          "LinkPeer",
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Academic Networking Platform for IGIT",
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.primaryAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _packageInfo != null
                ? "Version ${_packageInfo!.version} (Build ${_packageInfo!.buildNumber})"
                : "Loading Version...",
            style: TextStyle(
              color: colors.primaryAccent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  //Developer Card
  Widget _buildDeveloperCard(
    AppColors colors,
    AsyncValue<DeveloperProfileModel?> asyncProfile,
  ) {
    return asyncProfile.when(
      data: (profile) {
        final name = profile?.name.isNotEmpty == true
            ? profile!.name
            : "Swayanshu Sarthak Sadangi";
        final role = "Mobile & Backend Developer";

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.primaryAccent.withValues(alpha: 0.15),
                colors.primaryAccent.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: colors.primaryAccent.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primaryAccent.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "DEVELOPED BY",
                  style: TextStyle(
                    color: colors.primaryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colors.primaryAccent,
                      colors.primaryAccent.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 56,
                  backgroundColor: colors.bgColor,
                  backgroundImage: profile?.imageUrl.isNotEmpty == true
                      ? NetworkImage(profile!.imageUrl)
                      : null,
                  child: profile?.imageUrl.isEmpty ?? true
                      ? Icon(
                          Icons.person,
                          size: 40,
                          color: colors.primaryAccent,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(
                  color: colors.primaryAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (profile?.github.isNotEmpty == true)
                    _socialBtn(
                      colors,
                      FaIcon(
                        FontAwesomeIcons.github,
                        size: 20,
                        color: colors.primaryText,
                      ),
                      profile!.github,
                    ),
                  if (profile?.linkedin.isNotEmpty == true)
                    _socialBtn(
                      colors,
                      FaIcon(
                        FontAwesomeIcons.linkedin,
                        size: 20,
                        color: colors.primaryText,
                      ),
                      profile!.linkedin,
                    ),
                  if (profile?.instagram.isNotEmpty == true)
                    _socialBtn(
                      colors,
                      FaIcon(
                        FontAwesomeIcons.instagram,
                        size: 20,
                        color: colors.primaryText,
                      ),
                      profile!.instagram,
                    ),
                  if (profile?.x.isNotEmpty == true)
                    _socialBtn(
                      colors,
                      FaIcon(
                        FontAwesomeIcons.xTwitter,
                        size: 20,
                        color: colors.primaryText,
                      ),
                      profile!.x,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (profile?.portfolio.isNotEmpty == true)
                    _socialBtn(
                      colors,
                      Icon(
                        Icons.language_rounded,
                        size: 20,
                        color: colors.primaryText,
                      ),
                      profile!.portfolio,
                    ),
                  if (profile?.website.isNotEmpty == true)
                    _socialBtn(
                      colors,
                      Icon(
                        Icons.public_rounded,
                        size: 20,
                        color: colors.primaryText,
                      ),
                      profile!.website,
                    ),
                  if (profile?.email.isNotEmpty == true)
                    _socialBtn(
                      colors,
                      Icon(
                        Icons.email_rounded,
                        size: 20,
                        color: colors.primaryText,
                      ),
                      profile!.email,
                    ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _shimmerBox(colors, height: 250),
      error: (e, s) => const SizedBox(),
    );
  }

  Widget _socialBtn(AppColors colors, Widget iconWidget, String url) {
    return InkWell(
      onTap: () => _launchURL(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
        ),
        child: iconWidget,
      ),
    );
  }

  // Section 3: Swynx Card
  Widget _buildSwynxCard(AppColors colors) {
    return GestureDetector(
      onTap: () => _launchURL("https://swynx.dev"),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                Icons.rocket_launch_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "SWYNX",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Building products that matter.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Visit swynx.dev",
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF0F172A),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section 4: Special Thanks Card
  Widget _buildSpecialThanks(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primaryAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primaryAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.primaryAccent.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: const DecorationImage(
                  image: AssetImage('assets/images/codex.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: colors.primaryAccent),
              const SizedBox(width: 12),
              Text(
                "Special Thanks",
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "A heartfelt thank you to the Codex Community for believing in this vision, supporting development, sharing feedback, testing features, and helping transform LinkPeer from an idea into a platform used by students.\n\nYour encouragement, suggestions, and contributions played a significant role in making this project a reality.\n\nThank you for being part of this journey.",
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 15,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // Section 5: About LinkPeer
  Widget _buildAboutLinkPeer(AppColors colors) {
    final features = [
      "Academic Networking",
      "Student Communities",
      "Alumni Connections",
      "Faculty Interaction",
      "Knowledge Sharing",
      "Career Growth",
      "Professional Networking",
      "Resource Sharing",
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About LinkPeer",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "LinkPeer is an academic networking platform designed to help students connect with peers, seniors, alumni, and faculty members.\n\nThe platform enables meaningful academic collaboration, knowledge sharing, professional networking, and community engagement within educational institutions.\n\nWhether you're looking for guidance, opportunities, resources, or connections, LinkPeer aims to bring the academic community together in one place.",
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features
                .map(
                  (f) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.borderColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // // Section 6: App Statistics
  // Widget _buildAppStatistics(AppColors colors) {
  //   return Row(
  //     children: [
  //       Expanded(child: _statCard(colors, "3000+", "Users")),
  //       const SizedBox(width: 12),
  //       Expanded(child: _statCard(colors, "10000+", "Posts")),
  //       const SizedBox(width: 12),
  //       Expanded(child: _statCard(colors, "100+", "Communities")),
  //     ],
  //   );
  // }

  // Widget _statCard(AppColors colors, String value, String label) {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
  //     decoration: _cardDecoration(colors),
  //     child: Column(
  //       children: [
  //         Text(
  //           value,
  //           style: TextStyle(
  //             color: colors.primaryText,
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         const SizedBox(height: 4),
  //         Text(
  //           label,
  //           style: TextStyle(
  //             color: colors.secondaryText,
  //             fontSize: 12,
  //             fontWeight: FontWeight.w500,
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Section 7: Built for the Community
  Widget _buildCommunitySection(AppColors colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups_rounded, color: colors.primaryText),
              const SizedBox(width: 12),
              Text(
                "Built for the Community",
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "LinkPeer was created with the vision of making academic networking more accessible, meaningful, and collaborative.\n\nEvery piece of feedback, bug report, feature request, and contribution helps shape the future of the platform.\n\nTogether, we're building something valuable for students and educational communities.",
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Section 8: Support & Legal
  Widget _buildSupportLegalCard(
    AppColors colors,
    AsyncValue<SupportLinksModel?> asyncLinks,
  ) {
    return asyncLinks.when(
      data: (links) {
        if (links == null) return const SizedBox();
        return Container(
          width: double.infinity,
          decoration: _cardDecoration(colors),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  "Support & Legal",
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (links.privacyPolicy.isNotEmpty)
                _linkTile(
                  colors,
                  "Privacy Policy",
                  Icons.privacy_tip_outlined,
                  links.privacyPolicy,
                ),
              if (links.accountDeletion.isNotEmpty)
                _linkTile(
                  colors,
                  "Account Deletion",
                  Icons.person_remove_outlined,
                  links.accountDeletion,
                ),
              if (links.childSafety.isNotEmpty)
                _linkTile(
                  colors,
                  "Child Safety Standards",
                  Icons.health_and_safety_outlined,
                  links.childSafety,
                ),
              if (links.supportWebsite.isNotEmpty)
                _linkTile(
                  colors,
                  "Support Website",
                  Icons.help_outline_rounded,
                  links.supportWebsite,
                ),
              if (links.supportEmail.isNotEmpty)
                _linkTile(
                  colors,
                  "Contact Support",
                  Icons.mail_outline_rounded,
                  links.supportEmail,
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
      loading: () => _shimmerBox(colors, height: 300),
      error: (e, s) => const SizedBox(),
    );
  }

  Widget _linkTile(AppColors colors, String title, IconData icon, String url) {
    return ListTile(
      onTap: () => _launchURL(url),
      leading: Icon(icon, color: colors.secondaryText),
      title: Text(
        title,
        style: TextStyle(
          color: colors.primaryText,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: colors.secondaryText,
        size: 16,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }

  // Section 9: Footer
  Widget _buildFooter(AppColors colors) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Made with ",
              style: TextStyle(color: colors.secondaryText, fontSize: 14),
            ),
            const Icon(
              Icons.favorite_rounded,
              color: Colors.redAccent,
              size: 16,
            ),
            Text(
              " in Odisha, India",
              style: TextStyle(color: colors.secondaryText, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Powered by ",
              style: TextStyle(color: colors.secondaryText, fontSize: 13),
            ),
            GestureDetector(
              onTap: () => _launchURL("https://swynx.dev"),
              child: Text(
                "swynx.dev",
                style: TextStyle(
                  color: colors.primaryAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration(AppColors colors) {
    return BoxDecoration(
      color: colors.cardColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _shimmerBox(AppColors colors, {required double height}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[850]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[800]! : Colors.grey[100]!,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
