import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Screens/FacultyVerificationScreen.dart';
import '../app_colors.dart';
import '../../MainScreen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingUserDetailsScreen extends StatefulWidget {
  final String userMode;

  const OnboardingUserDetailsScreen({super.key, required this.userMode});

  @override
  State<OnboardingUserDetailsScreen> createState() =>
      _OnboardingUserDetailsScreenState();
}

class _OnboardingUserDetailsScreenState
    extends State<OnboardingUserDetailsScreen> {
  // ── Form key (class-level — never inside build) ───────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Year picker controller ─────────────────────────────────────────────────
  final graduationYearController = TextEditingController();

  // ── Static data ───────────────────────────────────────────────────────────
  final departments = [
    "CSE",
    "ECE",
    "EEE",
    "Mechanical",
    "Civil",
    "Production",
    "Chemical",
    "Mathematics",
    "Physics",
    "Chemistry",
    "Humanities",
  ];

  final branches = [
    "CSE",
    "ECE",
    "EEE",
    "Mechanical",
    "Civil",
    "Production",
    "Chemical",
  ];

  final streams = ["BTech", "MTech", "MCA"];

  /// Dynamic year range: 1990 → current year + 4.
  List<int> get years {
    final currentYear = DateTime.now().year;
    return List.generate((currentYear + 4) - 1990 + 1, (i) => 1990 + i);
  }

  // ── State ─────────────────────────────────────────────────────────────────
  String college = "IGIT";
  String userType = "";

  // Student
  String? branch;
  String? stream;
  int? graduatingYear;

  // Faculty
  String? department;
  String designation = "";
  String phone = "";
  String? facultyProof;
  bool isProofUploaded = false;

  bool _saving = false;

  // ── Completion ratio (drives the truthful progress bar) ───────────────────
  double get _completionRatio {
    if (widget.userMode == "faculty") {
      final filled = [
        department != null,
        designation.trim().isNotEmpty,
        phone.trim().length >= 10,
        isProofUploaded,
      ].where((v) => v).length;
      return filled / 4;
    } else {
      final filled = [
        branch != null,
        stream != null,
        graduatingYear != null,
      ].where((v) => v).length;
      return filled / 3;
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    userType = widget.userMode == "faculty" ? "faculty" : "student";
  }

  @override
  void dispose() {
    graduationYearController.dispose();
    super.dispose();
  }

  // ── Graduation year picker (themed to AppColors) ──────────────────────────
  Future<void> pickGraduationYear() async {
    final now = DateTime.now();
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final picked = await showDatePicker(
      context: context,
      initialDate: graduatingYear != null
          ? DateTime(graduatingYear!)
          : DateTime(now.year),
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 4),
      helpText: "Select Graduation Year",
      fieldHintText: "YYYY",
      initialDatePickerMode: DatePickerMode.year,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              brightness: isDark ? Brightness.dark : Brightness.light,
              primary: colors.primaryText,
              onPrimary: isDark ? const Color(0xFF141413) : Colors.white,
              secondary: colors.primaryText,
              onSecondary: isDark ? const Color(0xFF141413) : Colors.white,
              error: const Color(0xFFD32F2F),
              onError: Colors.white,
              surface: colors.cardColor,
              onSurface: colors.primaryText,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: colors.primaryText),
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        graduatingYear = picked.year;
        graduationYearController.text = picked.year.toString();
        detectRole();
      });
    }
  }

  // ── Role detection based on graduation year ───────────────────────────────
  void detectRole() {
    if (graduatingYear == null) return;
    final currentYear = DateTime.now().year;
    setState(() {
      userType = graduatingYear! <= currentYear ? "alumni" : "student";
    });
  }

  // ── Save to Supabase ──────────────────────────────────────────────────────
  Future<void> save() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar(
        icon: Icons.error_outline_rounded,
        message: "Please complete all required fields.",
        color: const Color(0xFFD32F2F),
      );
      return;
    }

    if (widget.userMode == "faculty" && !isProofUploaded) {
      _showSnackBar(
        icon: Icons.verified_user_outlined,
        message: "Please upload your faculty verification proof.",
        color: const Color(0xFFD32F2F),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await Supabase.instance.client
          .from("users")
          .update({
            "user_type": userType,
            "college": college,

            if (widget.userMode == "student") ...{
              "branch": branch,
              "stream": stream,
              "graduating_year": graduatingYear,
              "department": null,
              "designation": null,
              "phone": null,
            },

            if (widget.userMode == "faculty") ...{
              "branch": null,
              "stream": null,
              "graduating_year": null,
              "department": department,
              "designation": designation,
              "phone": phone,
              "faculty_proof": facultyProof,
            },

            "profile_completed": true,
          })
          .eq("id", uid);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("profile_completed_$uid", true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnackBar(
        icon: Icons.cloud_off_rounded,
        message: "Failed to save profile. Please try again.",
        color: const Color(0xFFD32F2F),
      );
    }
  }

  // ── Snack bar helper ──────────────────────────────────────────────────────
  void _showSnackBar({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // ── Input decoration ──────────────────────────────────────────────────────
  InputDecoration _inputDeco(
    String label,
    AppColors colors, {
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.secondaryText, fontSize: 14),
      prefixIcon: icon != null
          ? Icon(icon, color: colors.secondaryText, size: 20)
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: colors.bgColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colors.primaryText, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD32F2F)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFaculty = widget.userMode == "faculty";

    return Scaffold(
      backgroundColor: colors.bgColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // ── 1. Hero Header ────────────────────────────────────────
              _HeroCard(
                isFaculty: isFaculty,
                colors: colors,
                completionRatio: _completionRatio,
              ),

              const SizedBox(height: 20),

              // ── 2. Profile Overview ───────────────────────────────────
              _SectionCard(
                title: "Profile Overview",
                colors: colors,
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.person_outline_rounded,
                      label: "User Type",
                      value: _displayUserType(userType),
                      colors: colors,
                    ),
                    Divider(height: 1, color: colors.borderColor),
                    _InfoTile(
                      icon: Icons.school_outlined,
                      label: "College",
                      value: college,
                      colors: colors,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 3a. Academic Info (Student / Alumni) ──────────────────
              if (!isFaculty) ...[
                _SectionCard(
                  title: "Academic Information",
                  subtitle: "Tell us about your academic background",
                  colors: colors,
                  child: Column(
                    children: [
                      // Branch
                      DropdownButtonFormField<String>(
                        value: branch,
                        dropdownColor: colors.cardColor,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 15,
                        ),
                        decoration: _inputDeco(
                          "Branch",
                          colors,
                          icon: Icons.account_tree_outlined,
                        ),
                        validator: (v) =>
                            v == null ? "Please select your branch" : null,
                        items: branches
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => branch = v),
                      ),

                      const SizedBox(height: 14),

                      // Stream
                      DropdownButtonFormField<String>(
                        value: stream,
                        dropdownColor: colors.cardColor,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 15,
                        ),
                        decoration: _inputDeco(
                          "Stream",
                          colors,
                          icon: Icons.layers_outlined,
                        ),
                        validator: (v) =>
                            v == null ? "Please select your stream" : null,
                        items: streams
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => stream = v),
                      ),

                      const SizedBox(height: 14),

                      // Graduation year — text field + calendar icon picker
                      TextFormField(
                        controller: graduationYearController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 15,
                        ),
                        decoration: _inputDeco(
                          "Graduation Year",
                          colors,
                          icon: Icons.calendar_today_outlined,
                          suffix: IconButton(
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: colors.secondaryText,
                            ),
                            onPressed: pickGraduationYear,
                            tooltip: "Pick year",
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Please enter graduation year";
                          }
                          final year = int.tryParse(value);
                          if (year == null) return "Enter a valid year";
                          final cy = DateTime.now().year;
                          if (year < 1990 || year > cy + 4) {
                            return "Year must be between 1990 and ${cy + 4}";
                          }
                          return null;
                        },
                        onChanged: (value) {
                          final year = int.tryParse(value);
                          if (year != null) {
                            graduatingYear = year;
                            detectRole();
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],

              // ── 3b. Professional Info (Faculty) ──────────────────────
              if (isFaculty) ...[
                _SectionCard(
                  title: "Professional Information",
                  subtitle: "Your faculty details for the community",
                  colors: colors,
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: department,
                        dropdownColor: colors.cardColor,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 15,
                        ),
                        decoration: _inputDeco(
                          "Department",
                          colors,
                          icon: Icons.corporate_fare_outlined,
                        ),
                        validator: (v) =>
                            v == null ? "Please select department" : null,
                        items: departments
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => department = v),
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 15,
                        ),
                        decoration: _inputDeco(
                          "Designation",
                          colors,
                          icon: Icons.badge_outlined,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? "Designation is required"
                            : null,
                        onChanged: (v) => setState(() => designation = v),
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 15,
                        ),
                        decoration: _inputDeco(
                          "Phone Number",
                          colors,
                          icon: Icons.phone_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Phone number is required";
                          }
                          if (v.trim().length < 10) {
                            return "Enter a valid phone number";
                          }
                          return null;
                        },
                        onChanged: (v) => setState(() => phone = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── 4. Faculty Verification ───────────────────────────
                _FacultyVerificationCard(
                  colors: colors,
                  isDark: isDark,
                  isProofUploaded: isProofUploaded,
                  onUpload: () async {
                    final result = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FacultyVerificationScreen(),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        isProofUploaded = true;
                        facultyProof = result;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),
              ],

              // ── 5. Community Benefits ─────────────────────────────────
              _BenefitsCard(colors: colors),

              const SizedBox(height: 24),

              // ── 6. Continue Button ────────────────────────────────────
              _ContinueButton(
                saving: _saving,
                colors: colors,
                isDark: isDark,
                onPressed: save,
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  "Your data is stored securely and privately.",
                  style: TextStyle(color: colors.secondaryText, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayUserType(String type) {
    switch (type) {
      case "student":
        return "Student";
      case "alumni":
        return "Alumni";
      case "faculty":
        return "Faculty";
      default:
        return type;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Hero Header Card
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final bool isFaculty;
  final AppColors colors;
  final double completionRatio;

  const _HeroCard({
    required this.isFaculty,
    required this.colors,
    required this.completionRatio,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (completionRatio * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [colors.primaryText.withOpacity(0.12), colors.cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primaryText.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isFaculty
                  ? Icons.verified_user_rounded
                  : Icons.person_add_alt_1_rounded,
              color: colors.primaryText,
              size: 26,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            "Complete Your Profile",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "One step away from joining the LinkPeer community.",
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          // Progress bar — reflects real field completion
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: completionRatio,
                    minHeight: 5,
                    backgroundColor: colors.borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors.primaryText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "$pct%",
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            pct == 0
                ? "Fill in the details below to continue."
                : pct == 100
                ? "All done! Tap Continue to join LinkPeer."
                : "Almost there! Keep filling in the details.",
            style: TextStyle(color: colors.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Generic Section Card
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final AppColors colors;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(color: colors.secondaryText, fontSize: 13),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Read-only info tile
// ─────────────────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AppColors colors;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.secondaryText, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Faculty Verification Card
// ─────────────────────────────────────────────────────────────────────────────

class _FacultyVerificationCard extends StatelessWidget {
  final AppColors colors;
  final bool isDark;
  final bool isProofUploaded;
  final VoidCallback onUpload;

  const _FacultyVerificationCard({
    required this.colors,
    required this.isDark,
    required this.isProofUploaded,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2E7D32);
    const blue = Color(0xFF1565C0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isProofUploaded
                      ? green.withOpacity(0.12)
                      : blue.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isProofUploaded
                      ? Icons.verified_rounded
                      : Icons.shield_outlined,
                  color: isProofUploaded ? green : blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Faculty Verification",
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isProofUploaded ? "Proof submitted ✓" : "Required",
                      style: TextStyle(
                        color: isProofUploaded ? green : colors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.borderColor),
            ),
            child: Text(
              "Faculty verification helps maintain a trusted academic "
              "network. Verification is reviewed securely by our team "
              "within 48 hours.",
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onUpload,
              style: ElevatedButton.styleFrom(
                backgroundColor: isProofUploaded ? green : colors.primaryText,
                foregroundColor: isProofUploaded
                    ? Colors.white
                    : (isDark ? Colors.black : Colors.white),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isProofUploaded
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isProofUploaded
                        ? "Proof Uploaded Successfully"
                        : "Upload Verification Proof",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. Community Benefits Card
// ─────────────────────────────────────────────────────────────────────────────

class _BenefitsCard extends StatelessWidget {
  final AppColors colors;

  const _BenefitsCard({required this.colors});

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (Icons.people_alt_outlined, "Connect with students and alumni"),
      (Icons.work_outline_rounded, "Discover jobs and internships"),
      (Icons.hub_outlined, "Build your professional network"),
      (Icons.campaign_outlined, "Stay updated with campus activities"),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Why complete your profile?",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 16),

          ...benefits.map((b) {
            final (icon, text) = b;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colors.bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: colors.primaryText, size: 17),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: colors.secondaryText,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. Continue Button
// ─────────────────────────────────────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  final bool saving;
  final AppColors colors;
  final bool isDark;
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.saving,
    required this.colors,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: saving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryText,
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: colors.borderColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: saving
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    "Saving Profile…",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Continue to LinkPeer",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }
}
