import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../Component/AppColour.dart';
import '../../Controllers/UserProvider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final nameController = TextEditingController();

  final phoneController = TextEditingController();

  final branchController = TextEditingController();

  final streamController = TextEditingController();

  final yearController = TextEditingController();

  final departmentController = TextEditingController();

  final designationController = TextEditingController();

  bool initialized = false;
  bool saving = false;

  String userType = "student";

  String getUpdatedUserType(String year) {
    final now = DateTime.now().year;

    final grad = int.tryParse(year) ?? now;

    return grad <= now ? "alumni" : "student";
  }

  Widget field({
    required String label,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: const TextStyle(color: AppColours.primaryText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColours.secondaryText),
          filled: true,
          fillColor: AppColours.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> save() async {
    try {
      setState(() {
        saving = true;
      });

      final uid = FirebaseAuth.instance.currentUser!.uid;

      final data = userType == "faculty"
          ? {
              "name": nameController.text.trim(),
              "phone": phoneController.text.trim(),
              "department": departmentController.text.trim(),
              "designation": designationController.text.trim(),
            }
          : {
              "name": nameController.text.trim(),
              "phone": phoneController.text.trim(),
              "branch": branchController.text.trim(),
              "stream": streamController.text.trim(),
              "graduating_year": yearController.text.trim(),
              "user_type": getUpdatedUserType(yearController.text.trim()),
            };

      await Supabase.instance.client.from('users').update(data).eq('id', uid);

      ref.invalidate(userProvider);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: AppColours.bgColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColours.bgColor,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: AppColours.primaryText),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        elevation: 10,
        backgroundColor: AppColours.primaryText,
        foregroundColor: AppColours.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColours.borderColor),
        ),
        icon: const Icon(Icons.cloud_download, size: 18),
        label: saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Text(
                "Save Changes",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        onPressed: saving ? null : save,
      ),

      body: user.when(
        data: (data) {
          if (!initialized) {
            initialized = true;

            userType = (data["user_type"] ?? "student").toString();

            nameController.text = (data["name"] ?? "").toString();

            phoneController.text = (data["phone"] ?? "").toString();

            branchController.text = (data["branch"] ?? "").toString();

            streamController.text = (data["stream"] ?? "").toString();

            yearController.text = (data["graduating_year"] ?? "").toString();

            departmentController.text = (data["department"] ?? "").toString();

            designationController.text = (data["designation"] ?? "").toString();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                field(label: "Full Name", controller: nameController),

                field(
                  label: "Phone",
                  controller: phoneController,
                  keyboard: TextInputType.phone,
                ),

                if (userType == "faculty") ...[
                  field(label: "Department", controller: departmentController),

                  field(
                    label: "Designation",
                    controller: designationController,
                  ),
                ] else ...[
                  field(label: "Branch", controller: branchController),

                  field(label: "Stream", controller: streamController),

                  field(
                    label: "Graduating Year",
                    controller: yearController,
                    keyboard: TextInputType.number,
                  ),
                ],

                const SizedBox(height: 20),

                // SizedBox(
                //   width: double.infinity,
                //   height: 54,
                //   child: ElevatedButton(
                //     onPressed: saving ? null : save,
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: AppColours.primaryText,
                //       foregroundColor: Colors.black,
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(18),
                //       ),
                //     ),
                //     child: saving
                //         ? const SizedBox(
                //             width: 20,
                //             height: 20,
                //             child: CircularProgressIndicator(
                //               strokeWidth: 2,
                //               color: Colors.black,
                //             ),
                //           )
                //         : const Text(
                //             "Save Changes",
                //             style: TextStyle(fontWeight: FontWeight.bold),
                //           ),
                //   ),
                // ),
              ],
            ),
          );
        },

        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, s) => const Center(child: Text("Failed to load profile")),
      ),
    );
  }
}
