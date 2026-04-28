import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../AppColour.dart';
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

  final years = List.generate(15, (i) => 2018 + i);

  String college = "IGIT";

  String userType = "";

  String? branch;
  String? stream;
  int? graduatingYear;

  String? department;
  String designation = "";
  String phone = "";

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

  InputDecoration inputStyle(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColours.secondaryText),
      filled: true,
      fillColor: AppColours.cardColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColours.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColours.primaryText),
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

  @override
  Widget build(BuildContext context) {
    final isFaculty = widget.userMode == "faculty";

    return Scaffold(
      backgroundColor: AppColours.bgColor,

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
                  color: AppColours.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColours.borderColor),
                ),
                child: Text(
                  isFaculty ? "Faculty Profile" : "Complete Profile",
                  style: const TextStyle(
                    color: AppColours.primaryText,
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
                        style: const TextStyle(color: AppColours.primaryText),
                        decoration: inputStyle("User Type"),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        readOnly: true,
                        initialValue: college,
                        style: const TextStyle(color: AppColours.primaryText),
                        decoration: inputStyle("College"),
                      ),

                      const SizedBox(height: 12),

                      if (!isFaculty) ...[
                        DropdownButtonFormField<String>(
                          value: branch,
                          dropdownColor: AppColours.cardColor,
                          style: const TextStyle(color: AppColours.primaryText),
                          decoration: inputStyle("Branch"),
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
                          dropdownColor: AppColours.cardColor,
                          style: const TextStyle(color: AppColours.primaryText),
                          decoration: inputStyle("Stream"),
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
                          dropdownColor: AppColours.cardColor,
                          style: const TextStyle(color: AppColours.primaryText),
                          decoration: inputStyle("Graduating Year"),
                          items: years
                              .map(
                                (e) => DropdownMenuItem(
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
                          dropdownColor: AppColours.cardColor,
                          style: const TextStyle(color: AppColours.primaryText),
                          decoration: inputStyle("Department"),
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
                          style: const TextStyle(color: AppColours.primaryText),
                          decoration: inputStyle("Designation"),
                        ),

                        const SizedBox(height: 12),

                        TextFormField(
                          keyboardType: TextInputType.phone,
                          onChanged: (v) => phone = v,
                          style: const TextStyle(color: AppColours.primaryText),
                          decoration: inputStyle("Phone"),
                        ),
                      ],

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColours.primaryText,
                            foregroundColor: Colors.black,
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
