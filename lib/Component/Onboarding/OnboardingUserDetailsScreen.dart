import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:igit_connects/Storage_Backend.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Screens/FacultyVerificationScreen.dart';
import '../app_colors.dart';
import '../../MainScreen.dart';

class OnboardingUserDetailsScreen extends StatefulWidget {
  final String userMode;

  const OnboardingUserDetailsScreen({super.key, required this.userMode});

  @override
  State<OnboardingUserDetailsScreen> createState() =>
      _OnboardingUserDetailsScreenState();
}

class _OnboardingUserDetailsScreenState
    extends State<OnboardingUserDetailsScreen> {
  final departments = [
    "CSE", "ECE", "EEE", "Mechanical", "Civil",
    "Production", "Chemical", "Mathematics", "Physics", "Chemistry", "Humanities",
  ];

  final branches = [
    "CSE", "ECE", "EEE", "Mechanical", "Civil", "Production", "Chemical",
  ];

  final streams = ["BTech", "MTech", "MCA"];

  final years = List.generate(15, (i) => 2018 + i);

  String college = "IGIT";

  String userType = "";

  String? branch;
  String? stream;
  int? graduatingYear;

  String? department;
  String designation = "";
  String phone = "";

  String? facultyProof;

  @override
  void initState() {
    super.initState();

    if (widget.userMode == "faculty") {
      userType = "faculty";
    } else {
      userType = "student";
    }
  }

  void detectRole() {
    if (graduatingYear == null) return;

    final currentYear = DateTime.now().year;

    setState(() {
      userType = graduatingYear! <= currentYear ? "alumni" : "student";
    });
  }

  InputDecoration inputStyle(String label, AppColors colors) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.secondaryText),
      filled: true,
      fillColor: colors.cardColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: colors.primaryText),
      ),
    );
  }

  Future<void> save() async {
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
        "faculty_proof": facultyProof
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
  }

  String? imageUrl;
  bool isProofUploaded = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFaculty = widget.userMode == "faculty";

    return Scaffold(
      backgroundColor: colors.bgColor,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),

          child: Column(
            children: [
              const SizedBox(height: 40),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: colors.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: colors.borderColor),
                ),
                child: Text(
                  isFaculty ? "Faculty Profile" : "Complete Profile",
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        readOnly: true,
                        initialValue: userType,
                        style: TextStyle(color: colors.primaryText),
                        decoration: inputStyle("User Type", colors),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        readOnly: true,
                        initialValue: college,
                        style: TextStyle(color: colors.primaryText),
                        decoration: inputStyle("College", colors),
                      ),

                      const SizedBox(height: 12),

                      if (!isFaculty) ...[
                        DropdownButtonFormField<String>(
                          value: branch,
                          dropdownColor: colors.cardColor,
                          style: TextStyle(color: colors.primaryText),
                          decoration: inputStyle("Branch", colors),
                          items: branches
                              .map(
                                (e) =>
                                DropdownMenuItem(value: e, child: Text(e)),
                          )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              branch = v;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: stream,
                          dropdownColor: colors.cardColor,
                          style: TextStyle(color: colors.primaryText),
                          decoration: inputStyle("Stream", colors),
                          items: streams
                              .map(
                                (e) =>
                                DropdownMenuItem(value: e, child: Text(e)),
                          )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              stream = v;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<int>(
                          value: graduatingYear,
                          dropdownColor: colors.cardColor,
                          style: TextStyle(color: colors.primaryText),
                          decoration: inputStyle("Graduating Year", colors),
                          items: years
                              .map(
                                (e) =>
                                DropdownMenuItem(
                                  value: e,
                                  child: Text("$e"),
                                ),
                          )
                              .toList(),
                          onChanged: (v) {
                            graduatingYear = v;
                            detectRole();
                          },
                        ),
                      ],

                      if (isFaculty) ...[
                        DropdownButtonFormField<String>(
                          value: department,
                          dropdownColor: colors.cardColor,
                          style: TextStyle(color: colors.primaryText),
                          decoration: inputStyle("Department", colors),
                          items: departments
                              .map(
                                (e) =>
                                DropdownMenuItem(value: e, child: Text(e)),
                          )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              department = v;
                            });
                          },
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          onChanged: (v) => designation = v,
                          style: TextStyle(color: colors.primaryText),
                          decoration: inputStyle("Designation", colors),
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          keyboardType: TextInputType.phone,
                          onChanged: (v) => phone = v,
                          style: TextStyle(color: colors.primaryText),
                          decoration: inputStyle("Phone", colors),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red),
                            color: colors.cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Faculty Verification Required\nPlease submit a live photo for verification. Our team will review it securely and verify your faculty account within 48 hours.',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 12),

                        SizedBox(
                          width: 200,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isProofUploaded
                                  ? Colors.green
                                  : colors.primaryText,
                              foregroundColor: isProofUploaded
                                  ? Colors.white
                                  : (isDark ? Colors.black : Colors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isProofUploaded) ...[
                                  const Icon(Icons.check_circle, size: 22),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  isProofUploaded ? "Uploaded" : "Upload Proof",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primaryText,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            "Continue",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
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
    );
  }
}
