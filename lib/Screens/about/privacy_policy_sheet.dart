import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/shared_components/policy_section.dart';

class PrivacyPolicySheet extends StatelessWidget {
  const PrivacyPolicySheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.98,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),

              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.borderColor,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),

              const SizedBox(height: 18),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/LinkPeer.png',
                      height: 32,
                      width: 32,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(width: 10),

                    Text(
                      "Privacy Policy",
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: colors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: colors.borderColor),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: colors.bgColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: colors.primaryText.withValues(
                              alpha: .08,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'assets/images/LinkPeer.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            "Your Privacy Matters",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.primaryText,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "LinkPeer is committed to protecting your information while helping students, alumni and faculty build meaningful connections.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.secondaryText,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    PolicySection(
                      title: "Information We Collect",
                      icon: Icons.badge_outlined,
                      items: const [
                        "Name and profile information",
                        "Email address",
                        "Profile picture",
                        "Institution details",
                        "Academic and professional information",
                      ],
                    ),

                    PolicySection(
                      title: "How We Use Information",
                      icon: Icons.insights_outlined,
                      items: const [
                        "Authentication and account access",
                        "Networking and community building",
                        "Profile discovery",
                        "Career opportunities",
                        "Event participation",
                      ],
                    ),

                    PolicySection(
                      title: "Data Protection",
                      icon: Icons.security_outlined,
                      items: const [
                        "Data is stored securely",
                        "Reasonable safeguards are applied",
                        "Authorized access only",
                        "Users remain responsible for account security",
                      ],
                    ),

                    PolicySection(
                      title: "Community Guidelines",
                      icon: Icons.groups_outlined,
                      items: const [
                        "Respect all community members",
                        "Avoid harmful or misleading content",
                        "Do not impersonate others",
                        "Maintain professional conduct",
                      ],
                    ),

                    PolicySection(
                      title: "Faculty Verification",
                      icon: Icons.verified_user_outlined,
                      items: const [
                        "Faculty accounts may require manual verification",
                        "Verification helps maintain trust and authenticity",
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.blue.withValues(alpha: .08),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: .20),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              "By continuing to use LinkPeer, you agree to our privacy practices and community guidelines.",
                              style: TextStyle(
                                color: colors.primaryText,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Image.asset(
                        'assets/images/LinkPeer.png',
                        height: 36,
                        width: 36,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Center(
                      child: Text(
                        "LinkPeer",
                        style: TextStyle(
                          color: colors.primaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Center(
                      child: Text(
                        "One Community. Endless Possibilities.",
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        "Last Updated • July 2026",
                        style: TextStyle(
                          color: colors.secondaryText,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
