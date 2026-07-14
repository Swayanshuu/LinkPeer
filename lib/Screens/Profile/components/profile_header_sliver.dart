// Component/Profile/ProfileHeaderSliver.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/screens/profile/edit_profile_screen.dart';
import 'package:igit_connects/screens/profile/components/profile_stats_row.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const double step = 30.0;

    for (double i = 0; i <= size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i <= size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ProfileHeaderSliver extends StatelessWidget {
  final Map data;
  final AsyncValue posts;
  final WidgetRef ref;
  final PreferredSizeWidget? bottom;
  final bool isOtherUser;

  const ProfileHeaderSliver({
    super.key,
    required this.data,
    required this.posts,
    required this.ref,
    this.bottom,
    this.isOtherUser = false,
  });

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.tryParse(
      urlString.startsWith('http') ? urlString : 'https://$urlString',
    );
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getDomain(String url) {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
      return uri.host.replaceAll('www.', '');
    } catch (e) {
      return "Link";
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final name = data["name"] ?? "User";
    final photo = data["photo_url"] ?? "";
    final role = (data["role"] ?? "user").toString().toLowerCase();
    final isAdmin = role == "admin";

    final userType = isAdmin
        ? "ADMIN"
        : (data["user_type"] ?? "Student").toString().toUpperCase();
    final isStudent = userType.contains("STUDENT");
    final branch = data["branch"] ?? data["department"] ?? "CSE";
    final college = data["college"] ?? "IGIT Sarang";

    final gradYear =
        data["graduating_year"]?.toString() ?? DateTime.now().year.toString();
    final now = DateTime.now().year;
    final gradYearInt = int.tryParse(gradYear) ?? now;
    final isAlumni = gradYearInt <= now;

    int yearOfStudy = 4 - (gradYearInt - now);
    String yearString = "";
    if (isAlumni) {
      yearString = "Batch of $gradYear";
    } else if (yearOfStudy == 1) {
      yearString = "1st Year";
    } else if (yearOfStudy == 2) {
      yearString = "2nd Year";
    } else if (yearOfStudy == 3) {
      yearString = "3rd Year";
    } else if (yearOfStudy == 4) {
      yearString = "4th Year";
    } else {
      yearString = "Batch of $gradYear";
    }

    // Fallback bio if empty
    final bioRaw = data["description"]?.toString().trim() ?? "";
    final String bio = bioRaw.isNotEmpty
        ? bioRaw
        : (isOtherUser ? "" : "(Add a bio from edit profile)");

    final githubRaw = data["github"]?.toString().trim() ?? "";
    final githubUrl = githubRaw.isNotEmpty
        ? (githubRaw.contains('github.com')
              ? githubRaw
              : 'https://github.com/$githubRaw')
        : "";
    final link2 = data["link2"]?.toString().trim() ?? "";

    final String rawPlan = data["subscription_plan"]?.toString() ?? 'free';
    final bool isSubActive = data["subscription_status"] == 'active';
    final String plan = (isSubActive && rawPlan != 'free') ? rawPlan : 'free';

    // Calculate dynamic expandedHeight
    int bioLines = bio.isNotEmpty ? bio.split('\n').length : 0;
    int estimatedLines = bio.isNotEmpty ? (bio.length / 40).ceil() : 0;
    int totalLines = bioLines > estimatedLines ? bioLines : estimatedLines;
    if (totalLines > 4) totalLines = 4; // Max 4 lines

    double calculatedHeight = 460.0; // Base height without bio and links

    if (bio.isNotEmpty) {
      calculatedHeight += (totalLines * 20.0) + 16.0;
    }

    if (link2.isNotEmpty || githubRaw.isNotEmpty) {
      calculatedHeight += 50.0;
    }

    // Calculate profile completion percentage
    int totalFields = 0;
    int filledFields = 0;

    void checkField(String? value) {
      totalFields++;
      if (value != null && value.trim().isNotEmpty) {
        filledFields++;
      }
    }

    checkField(data["name"]?.toString());
    checkField(data["phone"]?.toString());
    checkField(data["photo_url"]?.toString());
    checkField(data["description"]?.toString());
    checkField(data["github"]?.toString());
    checkField(data["link2"]?.toString());

    if (userType.toLowerCase() == "faculty") {
      checkField(data["department"]?.toString());
      checkField(data["designation"]?.toString());
    } else {
      checkField(data["branch"]?.toString());
      checkField(data["stream"]?.toString());
      checkField(data["graduating_year"]?.toString());
    }

    final double completionPercentage = totalFields > 0
        ? (filledFields / totalFields)
        : 0.0;

    return SliverAppBar(
      expandedHeight: calculatedHeight,
      elevation: 0,
      backgroundColor: colors.bgColor,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      pinned: true,
      toolbarHeight: 0,
      bottom: bottom,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Background Gradient with Grid Pattern
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 220,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colors.primaryAccent.withValues(alpha: 0.2),
                          colors.primaryAccent.withValues(alpha: 0.05),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: GridPainter(
                        color: colors.primaryText.withValues(alpha: 0.03),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Top App Bar Icons - Edit Button Moved Here
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isOtherUser)
                    Container(
                      decoration: BoxDecoration(
                        color: colors.cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: colors.primaryText,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    )
                  else
                    const SizedBox(),
                  Row(
                    children: [
                      if (!isOtherUser)
                        Container(
                          decoration: BoxDecoration(
                            color: colors.cardColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: colors.primaryText,
                              size: 20,
                            ),
                            onPressed: () async {
                              final updated = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                              if (updated == true) {
                                ref.invalidate(userProvider);
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Profile Content
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      // Progress Ring
                      if (!isOtherUser)
                        SizedBox(
                          width: 106,
                          height: 106,
                          child: CircularProgressIndicator(
                            value: completionPercentage,
                            strokeWidth: 3,
                            backgroundColor: colors.borderColor.withValues(
                              alpha: 0.3,
                            ),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              completionPercentage >= 1.0
                                  ? Colors.green
                                  : colors.primaryAccent,
                            ),
                          ),
                        ),

                      // Original Avatar
                      Container(
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor: colors.borderColor,
                          backgroundImage: photo.toString().isNotEmpty
                              ? NetworkImage(photo)
                              : null,
                          child: photo.toString().isEmpty
                              ? Icon(
                                  Icons.person,
                                  color: colors.primaryText,
                                  size: 40,
                                )
                              : null,
                        ),
                      ),

                      // Percentage Badge
                      if (!isOtherUser && completionPercentage < 1.0)
                        Positioned(
                          bottom: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryAccent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: colors.bgColor,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              "${(completionPercentage * 100).toInt()}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Name and badge
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (data["is_verified"] == true) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified,
                          color: colors.primaryAccent,
                          size: 20,
                        ),
                      ],
                      if (data["faculty_verified"] == true &&
                          userType.toLowerCase() == "faculty") ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.gpp_good_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // User Type Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? colors.badgeAdminBg
                              : (isStudent
                                    ? colors.badgeStudentBg
                                    : colors.badgeAlumniBg),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isAdmin
                              ? "ADMIN"
                              : (isStudent ? "Student" : userType),
                          style: TextStyle(
                            color: isAdmin
                                ? colors.badgeAdminText
                                : (isStudent
                                      ? colors.badgeStudentText
                                      : colors.badgeAlumniText),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Subscription Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: plan == 'premium_pro'
                              ? Colors.amber.shade700.withValues(alpha: 0.15)
                              : (plan == 'premium_lite'
                                    ? Colors.blueGrey.shade500.withValues(
                                        alpha: 0.15,
                                      )
                                    : colors.badgeAlumniBg),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: plan == 'premium_pro'
                                ? Colors.amber.shade700.withValues(alpha: 0.5)
                                : (plan == 'premium_lite'
                                      ? Colors.blueGrey.shade500.withValues(
                                          alpha: 0.5,
                                        )
                                      : Colors.transparent),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          plan == 'premium_pro'
                              ? "PRO"
                              : (plan == 'premium_lite' ? "LITE" : "FREE"),
                          style: TextStyle(
                            color: plan == 'premium_pro'
                                ? Colors.amber.shade700
                                : (plan == 'premium_lite'
                                      ? Colors.blueGrey.shade500
                                      : colors.secondaryText),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Metadata
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 16,
                        color: colors.secondaryText,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "$branch, $yearString, $college",
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bio
                  if (bio.isNotEmpty) ...[
                    Text(
                      bio,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Links wrapped
                  if (link2.isNotEmpty || githubRaw.isNotEmpty) ...[
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (link2.isNotEmpty)
                          InkWell(
                            onTap: () => _launchUrl(link2),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.public,
                                    size: 16,
                                    color: colors.primaryAccent,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getDomain(link2),
                                    style: TextStyle(
                                      color: colors.primaryAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (githubRaw.isNotEmpty)
                          InkWell(
                            onTap: () => _launchUrl(githubUrl),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.github,
                                    size: 16,
                                    color: colors.secondaryText,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    githubRaw.contains('github.com')
                                        ? _getDomain(githubRaw)
                                        : githubRaw,
                                    style: TextStyle(
                                      color: colors.primaryAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (link2.isEmpty && githubRaw.isEmpty)
                    const SizedBox(height: 8),

                  // Stats Row
                  ProfileStatsRow(data: data, posts: posts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
