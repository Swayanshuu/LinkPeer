import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:igit_connects/screens/auth/faculty_verification_screen.dart';
import 'package:igit_connects/screens/auth/login_screen.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/app_constants.dart';
import 'package:igit_connects/main_screen.dart';
import 'package:igit_connects/shared_components/app_dropdown_field.dart';
import 'package:igit_connects/storage_backend.dart';

class OnboardingUserDetailsScreen extends StatefulWidget {
  final String userMode;
  final VoidCallback? onPrev;

  const OnboardingUserDetailsScreen({
    super.key,
    required this.userMode,
    this.onPrev,
  });

  @override
  State<OnboardingUserDetailsScreen> createState() =>
      _OnboardingUserDetailsScreenState();
}

class _OnboardingUserDetailsScreenState
    extends State<OnboardingUserDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final graduationYearController = TextEditingController();

  /// Dynamic year range: 1990 → current year + 4.
  List<int> get years {
    final currentYear = DateTime.now().year;
    return List.generate((currentYear + 4) - 1990 + 1, (i) => 1990 + i);
  }

  String selectedUserMode = "student";
  String college = "IGIT";
  String userType = "";

  // Student
  String? branch;
  String? stream;
  int? graduatingYear;

  // Faculty
  String? department;
  String? designation;
  String phone = "";
  String? facultyVerificationImage;
  bool isProofUploaded = false;

  bool _saving = false;
  bool _isUploadingPhoto = false;
  int _currentStep = 0;

  double get _completionRatio {
    if (selectedUserMode == "faculty") {
      final filled = [
        department != null,
        designation != null && designation!.isNotEmpty,
        phone.trim().length == 10,
        isProofUploaded,
      ].where((v) => v).length;
      return filled / 4;
    } else {
      final filled = [
        branch != null,
        stream != null,
        graduatingYear != null,
        phone.trim().length == 10,
      ].where((v) => v).length;
      return filled / 4;
    }
  }

  @override
  void initState() {
    super.initState();
    selectedUserMode = widget.userMode == "faculty" ? "faculty" : "student";
    userType = selectedUserMode == "faculty" ? "faculty" : "student";
  }

  @override
  void dispose() {
    graduationYearController.dispose();
    super.dispose();
  }

  Future<void> pickGraduationYear() async {
    final cy = DateTime.now().year;
    int selected = graduatingYear ?? cy;

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Select Graduation Year",
            style: TextStyle(
              color: AppColors.of(context).primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 250,
            child: YearPicker(
              firstDate: DateTime(1990),
              lastDate: DateTime(cy + 4),
              selectedDate: DateTime(selected),
              onChanged: (DateTime dateTime) {
                Navigator.pop(context, dateTime.year);
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        graduatingYear = result;
        graduationYearController.text = result.toString();
        detectRole();
      });
    }
  }

  void detectRole() {
    if (graduatingYear == null) return;
    final currentYear = DateTime.now().year;
    setState(() {
      userType = graduatingYear! <= currentYear ? "alumni" : "student";
    });
  }

  Future<void> save() async {
    if (selectedUserMode != "faculty") {
      if (branch == null ||
          stream == null ||
          graduatingYear == null ||
          phone.trim().length != 10) {
        _showSnackBar(
          icon: Icons.error_outline_rounded,
          message: "Please complete all mandatory academic fields.",
          color: Theme.of(context).colorScheme.error,
        );
        return;
      }
    } else {
      if (department == null ||
          designation == null ||
          designation!.isEmpty ||
          phone.trim().length != 10) {
        _showSnackBar(
          icon: Icons.error_outline_rounded,
          message: "Please complete all mandatory faculty fields.",
          color: Theme.of(context).colorScheme.error,
        );
        return;
      }
    }

    if (selectedUserMode == "faculty" && !isProofUploaded) {
      _showSnackBar(
        icon: Icons.verified_user_outlined,
        message: "Please upload your faculty verification proof.",
        color: Theme.of(context).colorScheme.error,
      );
      return;
    }

    setState(() {
      _saving = true;
      _isUploadingPhoto = false;
    });

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      final uid = firebaseUser?.uid ?? '';
      final userName = firebaseUser?.displayName ?? 'User';
      final userEmail = firebaseUser?.email;
      final userPhoto = firebaseUser?.photoURL ?? '';

      String? finalFacultyImageUrl = facultyVerificationImage;

      // Deferred upload of local verification selfie to Supabase storage on final profile submit
      if (selectedUserMode == "faculty" &&
          facultyVerificationImage != null &&
          facultyVerificationImage!.isNotEmpty &&
          !facultyVerificationImage!.startsWith("http")) {
        setState(() => _isUploadingPhoto = true);
        final uploadedUrl = await StorageBackend().uploadImage(
          XFile(facultyVerificationImage!),
        );
        finalFacultyImageUrl = uploadedUrl;
        if (mounted) setState(() => _isUploadingPhoto = false);
      }

      final payload = <String, dynamic>{
        "id": uid,
        "name": userName,
        if (userEmail != null && userEmail.isNotEmpty) "email": userEmail,
        "photo_url": userPhoto,
        "user_type": selectedUserMode == "faculty" ? "user" : userType,
        "college": college,
        "phone": phone,
        "profile_completed": true,
        "last_login": DateTime.now().toIso8601String(),

        if (selectedUserMode != "faculty") ...{
          "branch": branch,
          "stream": stream,
          "graduating_year": graduatingYear,
          "department": null,
          "designation": null,
        },

        if (selectedUserMode == "faculty") ...{
          "branch": null,
          "stream": null,
          "graduating_year": null,
          "department": department,
          "designation": designation,
          "faculty_verification_image": finalFacultyImageUrl,
          "faculty_verified": false,
        },
      };

      await Supabase.instance.client.from("users").upsert(payload);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool("profile_completed_$uid", true);
      await prefs.setString("user_mode_$uid", selectedUserMode);
      await prefs.remove("pending_user_mode_$uid");
      await prefs.remove("pending_user_mode");

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e, stack) {
      debugPrint("Error saving user profile: $e\n$stack");
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnackBar(
        icon: Icons.cloud_off_rounded,
        message: "Failed to save profile. Please try again.",
        color: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> cancelAndGoToLogin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid;

      // Delete uploaded faculty verification proof image from Supabase storage if present
      if (facultyVerificationImage != null &&
          facultyVerificationImage!.isNotEmpty &&
          facultyVerificationImage!.startsWith("http")) {
        await StorageBackend().removeFacultyImage(facultyVerificationImage!);
      }

      // Clear SharedPreferences pending user mode & onboarding state
      final prefs = await SharedPreferences.getInstance();
      if (uid != null) {
        await prefs.remove('pending_user_mode_$uid');
        await prefs.remove('profile_completed_$uid');
      }
      await prefs.remove('pending_user_mode');

      // Sign out from Firebase & Supabase so user starts completely clean
      await FirebaseAuth.instance.signOut();
      await Supabase.instance.client.auth.signOut();
    } catch (e) {
      debugPrint("Error clearing onboarding data on cancel: $e");
    } finally {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen2()),
        );
      }
    }
  }

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
                child: AutoSizeText(
                  message,
                  maxLines: 2,
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
        borderSide: BorderSide(color: colors.primaryAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.error,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isFaculty = selectedUserMode == "faculty";
    final isDesktop = MediaQuery.of(context).size.width > 800;

    final heroCard = _HeroCard(
      isFaculty: isFaculty,
      colors: colors,
      completionRatio: _completionRatio,
      onPrev: widget.onPrev,
    );

    final currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? "";

    final overviewSection = <Widget>[
      _HighlightedMandatoryUserTypeCard(
        selectedUserMode: selectedUserMode,
        onSelected: (mode) {
          setState(() {
            selectedUserMode = mode;
            if (mode == "student") {
              detectRole();
            } else {
              userType = "faculty";
            }
          });
        },
        colors: colors,
      ),
      const SizedBox(height: 16),
      _SectionCard(
        title: "Profile Overview",
        colors: colors,
        child: Column(
          children: [
            _InfoTile(
              icon: Icons.email_outlined,
              label: "Email Address",
              value: currentUserEmail.isNotEmpty
                  ? currentUserEmail
                  : "Signed in via Google",
              colors: colors,
            ),
            Divider(height: 1, color: colors.borderColor),
            _InfoTile(
              icon: Icons.school_outlined,
              label: "College",
              value: college,
              colors: colors,
            ),
            const SizedBox(height: 16),
            TextFormField(
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: TextStyle(color: colors.primaryText, fontSize: 15),
              decoration: _inputDeco(
                "Phone Number",
                colors,
                icon: Icons.phone_outlined,
              ).copyWith(counterText: ""),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return "Phone number is required";
                }
                if (v.trim().length != 10 || int.tryParse(v.trim()) == null) {
                  return "Enter a valid 10-digit phone number";
                }
                return null;
              },
              onChanged: (v) => setState(() => phone = v),
            ),
          ],
        ),
      ),
    ];

    final academicSection = !isFaculty
        ? <Widget>[
            _SectionCard(
              title: "Academic Information",
              subtitle: "Select your branch, stream, and year",
              colors: colors,
              child: Column(
                children: [
                  AppDropdownFormField<String>(
                    value: branch,
                    label: "Branch",
                    icon: Icons.account_tree_outlined,
                    items: AppConstants.branches,
                    validator: (v) =>
                        v == null ? "Please select your branch" : null,
                    onChanged: (v) => setState(() => branch = v),
                  ),
                  const SizedBox(height: 14),
                  AppDropdownFormField<String>(
                    value: stream,
                    label: "Stream",
                    icon: Icons.layers_outlined,
                    items: AppConstants.streams,
                    validator: (v) =>
                        v == null ? "Please select your stream" : null,
                    onChanged: (v) => setState(() => stream = v),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: graduationYearController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colors.primaryText, fontSize: 15),
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
          ]
        : <Widget>[];

    final professionalSection = isFaculty
        ? <Widget>[
            _SectionCard(
              title: "Professional Information",
              colors: colors,
              child: Column(
                children: [
                  AppDropdownFormField<String>(
                    value: department,
                    label: "Department",
                    icon: Icons.corporate_fare_outlined,
                    items: AppConstants.departments,
                    validator: (v) =>
                        v == null ? "Please select department" : null,
                    onChanged: (v) => setState(() => department = v),
                  ),
                  const SizedBox(height: 14),
                  AppDropdownFormField<String>(
                    value: designation,
                    label: "Designation",
                    icon: Icons.badge_outlined,
                    items: AppConstants.designations,
                    validator: (v) =>
                        v == null ? "Please select designation" : null,
                    onChanged: (v) => setState(() => designation = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _FacultyVerificationCard(
              colors: colors,
              isProofUploaded: isProofUploaded,
              facultyVerificationImage: facultyVerificationImage,
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
                    facultyVerificationImage = result;
                  });
                }
              },
              onDelete: () async {
                if (facultyVerificationImage != null &&
                    facultyVerificationImage!.isNotEmpty &&
                    facultyVerificationImage!.startsWith("http")) {
                  await StorageBackend().removeFacultyImage(
                    facultyVerificationImage!,
                  );
                }
                setState(() {
                  isProofUploaded = false;
                  facultyVerificationImage = null;
                });
              },
            ),
          ]
        : <Widget>[];

    final submitSection = <Widget>[
      _ContinueButton(
        saving: _saving,
        isUploadingPhoto: _isUploadingPhoto,
        colors: colors,
        onPressed: save,
      ),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: cancelAndGoToLogin,
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: colors.secondaryText, fontSize: 13),
              children: [
                const TextSpan(text: "Already have an account? "),
                TextSpan(
                  text: "Log in",
                  style: TextStyle(
                    color: colors.primaryAccent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    Widget formContent;
    if (isDesktop) {
      formContent = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: heroCard,
          ),
          Expanded(
            child: Stepper(
              currentStep: _currentStep,
              type: StepperType.vertical,
              physics: const ClampingScrollPhysics(),
              onStepTapped: (step) => setState(() => _currentStep = step),
              onStepContinue: () {
                if (_currentStep < 1) {
                  setState(() => _currentStep += 1);
                } else {
                  save();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                }
              },
              controlsBuilder: (context, details) {
                final isLastStep = _currentStep == 1;
                return Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Row(
                    children: [
                      if (!isLastStep)
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryAccent,
                            foregroundColor: colors.onPrimaryAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const AutoSizeText("Next", maxLines: 1),
                        ),
                      if (isLastStep)
                        Expanded(child: Column(children: submitSection)),
                      if (!isLastStep && _currentStep > 0) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: details.onStepCancel,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.secondaryText,
                          ),
                          child: const AutoSizeText("Back", maxLines: 1),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: AutoSizeText(
                    "Overview",
                    maxLines: 1,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Column(children: overviewSection),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: AutoSizeText(
                    "Details",
                    maxLines: 1,
                    style: TextStyle(
                      color: colors.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: Column(
                    children: isFaculty ? professionalSection : academicSection,
                  ),
                  isActive: _currentStep >= 1,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      formContent = ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          heroCard,
          const SizedBox(height: 20),
          ...overviewSection,
          const SizedBox(height: 16),
          if (!isFaculty) ...academicSection,
          if (isFaculty) ...professionalSection,
          const SizedBox(height: 24),
          ...submitSection,
        ],
      );
    }

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: colors.bgColor,
        body: Stack(
          children: [
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Form(key: _formKey, child: formContent),
                ),
              ),
            ),
            if (_saving)
              _FullScreenLoadingOverlay(
                isUploadingPhoto: _isUploadingPhoto,
                colors: colors,
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isFaculty;
  final AppColors colors;
  final double completionRatio;
  final VoidCallback? onPrev;

  const _HeroCard({
    required this.isFaculty,
    required this.colors,
    required this.completionRatio,
    this.onPrev,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (completionRatio * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/images/LinkPeer.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              if (onPrev != null)
                IconButton(
                  onPressed: onPrev,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: colors.primaryText,
                    size: 20,
                  ),
                  tooltip: "Back",
                  style: IconButton.styleFrom(
                    backgroundColor: colors.bgColor,
                    side: BorderSide(color: colors.borderColor),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          AutoSizeText(
            "Build your LinkPeer.",
            maxLines: 1,
            minFontSize: 18,
            maxFontSize: 24,
            style: TextStyle(
              color: colors.primaryText,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 4),

          AutoSizeText(
            "Create your profile and start building meaningful connections within your college community.",
            maxLines: 2,
            minFontSize: 12,
            maxFontSize: 14,
            style: TextStyle(color: colors.secondaryText),
          ),

          const SizedBox(height: 18),

          // Professional Sleek 3px Progress Bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completionRatio,
                    minHeight: 3,
                    backgroundColor: colors.borderColor.withValues(alpha: 0.6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colors.primaryAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AutoSizeText(
                "$pct%",
                maxLines: 1,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
          AutoSizeText(
            title,
            maxLines: 1,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            AutoSizeText(
              subtitle!,
              maxLines: 2,
              minFontSize: 11,
              maxFontSize: 13,
              style: TextStyle(color: colors.secondaryText),
            ),
          ],
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

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
                AutoSizeText(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                AutoSizeText(
                  value,
                  maxLines: 1,
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

class _FacultyVerificationCard extends StatelessWidget {
  final AppColors colors;
  final bool isProofUploaded;
  final String? facultyVerificationImage;
  final VoidCallback onUpload;
  final VoidCallback onDelete;

  const _FacultyVerificationCard({
    required this.colors,
    required this.isProofUploaded,
    this.facultyVerificationImage,
    required this.onUpload,
    required this.onDelete,
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
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isProofUploaded
                      ? colors.primaryAccent.withValues(alpha: 0.1)
                      : colors.bgColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Icon(
                  isProofUploaded
                      ? Icons.verified_user_rounded
                      : Icons.verified_user_outlined,
                  color: colors.primaryAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      "Faculty Verification Proof",
                      maxLines: 1,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AutoSizeText(
                      isProofUploaded
                          ? "Proof uploaded • Ready for verification"
                          : "Live selfie with Faculty ID required",
                      maxLines: 1,
                      style: TextStyle(
                        color: isProofUploaded
                            ? colors.primaryAccent
                            : colors.secondaryText,
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

          if (isProofUploaded && facultyVerificationImage != null) ...[
            // Inline Proof Image Preview with Fullscreen Dialog Option
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: facultyVerificationImage!.startsWith("http")
                              ? Image.network(
                                  facultyVerificationImage!,
                                  fit: BoxFit.contain,
                                )
                              : Image.file(
                                  File(facultyVerificationImage!),
                                  fit: BoxFit.contain,
                                ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: colors.bgColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: colors.borderColor),
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: facultyVerificationImage!.startsWith("http")
                          ? Image.network(
                              facultyVerificationImage!,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(facultyVerificationImage!),
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.zoom_in_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Tap to preview",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons: Retake & Delete
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: onUpload,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.primaryText,
                        side: BorderSide(color: colors.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: colors.primaryText,
                      ),
                      label: AutoSizeText(
                        "Retake Photo",
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: onDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      label: AutoSizeText(
                        "Delete Photo",
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  foregroundColor: colors.onPrimaryAccent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: Icon(
                  Icons.camera_alt_rounded,
                  size: 18,
                  color: colors.onPrimaryAccent,
                ),
                label: AutoSizeText(
                  "Capture Verification Selfie",
                  maxLines: 1,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: colors.onPrimaryAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final bool saving;
  final bool isUploadingPhoto;
  final AppColors colors;
  final VoidCallback onPressed;

  const _ContinueButton({
    required this.saving,
    required this.isUploadingPhoto,
    required this.colors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonText = saving
        ? (isUploadingPhoto
              ? "Uploading Verification Selfie..."
              : "Creating Profile...")
        : "Create Profile";

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: saving ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.primaryAccent,
          foregroundColor: colors.onPrimaryAccent,
          disabledBackgroundColor: colors.borderColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: saving
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: colors.onPrimaryAccent,
                ),
              )
            : Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: colors.onPrimaryAccent,
              ),
        label: AutoSizeText(
          buttonText,
          maxLines: 1,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: colors.onPrimaryAccent,
          ),
        ),
      ),
    );
  }
}

class _HighlightedMandatoryUserTypeCard extends StatelessWidget {
  final String selectedUserMode;
  final ValueChanged<String> onSelected;
  final AppColors colors;

  const _HighlightedMandatoryUserTypeCard({
    required this.selectedUserMode,
    required this.onSelected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isFaculty = selectedUserMode == "faculty";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colors.primaryAccent.withValues(alpha: 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primaryAccent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mandatory Badge Chip Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colors.primaryAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.stars_rounded,
                  size: 13,
                  color: colors.primaryAccent,
                ),
                const SizedBox(width: 6),
                AutoSizeText(
                  "STEP 1 • MANDATORY ROLE SELECTION",
                  maxLines: 1,
                  style: TextStyle(
                    color: colors.primaryAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          AutoSizeText(
            "Select Your Role in LinkPeer",
            maxLines: 1,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          AutoSizeText(
            "Choose your account category to set up your profile.",
            maxLines: 2,
            minFontSize: 11,
            maxFontSize: 13,
            style: TextStyle(color: colors.secondaryText),
          ),

          const SizedBox(height: 16),

          // Role Selection Option Cards
          Row(
            children: [
              Expanded(
                child: _RoleCardTile(
                  title: "Student / Alumni",
                  subtitle: "Peers & Network",
                  icon: Icons.school_rounded,
                  isSelected: !isFaculty,
                  colors: colors,
                  onTap: () => onSelected("student"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleCardTile(
                  title: "Faculty",
                  subtitle: "Academic Staff",
                  icon: Icons.badge_rounded,
                  isSelected: isFaculty,
                  colors: colors,
                  onTap: () => onSelected("faculty"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleCardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final AppColors colors;
  final VoidCallback onTap;

  const _RoleCardTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primaryAccent.withValues(alpha: 0.08)
              : colors.bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primaryAccent : colors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? colors.primaryAccent
                      : colors.secondaryText,
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: colors.primaryAccent,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            AutoSizeText(
              title,
              maxLines: 1,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            AutoSizeText(
              subtitle,
              maxLines: 1,
              style: TextStyle(color: colors.secondaryText, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullScreenLoadingOverlay extends StatelessWidget {
  final bool isUploadingPhoto;
  final AppColors colors;

  const _FullScreenLoadingOverlay({
    required this.isUploadingPhoto,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.85),
      child: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: colors.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.borderColor),
            boxShadow: [
              BoxShadow(
                color: colors.primaryAccent.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  color: colors.primaryAccent,
                ),
              ),
              const SizedBox(height: 24),
              AutoSizeText(
                "Setting Up LinkPeer Account",
                maxLines: 1,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: AutoSizeText(
                  isUploadingPhoto
                      ? "Uploading faculty verification proof to secure storage..."
                      : "Saving your profile preferences & details...",
                  key: ValueKey(isUploadingPhoto),
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  minFontSize: 11,
                  maxFontSize: 13,
                  style: TextStyle(
                    color: colors.secondaryText,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      size: 13,
                      color: colors.primaryAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Encrypted & Secure Transfer",
                      style: TextStyle(
                        color: colors.primaryAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
