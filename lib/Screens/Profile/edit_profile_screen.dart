import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/user_provider.dart';

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
    required BuildContext context,
    required AppColors colors,
    required String label,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        style: TextStyle(color: colors.primaryText),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors.secondaryText),
          filled: true,
          fillColor: colors.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: colors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: colors.primaryText),
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
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.bgColor,
        iconTheme: IconThemeData(color: colors.primaryText),
        title: Text(
          "Edit Profile",
          style: TextStyle(color: colors.primaryText),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        elevation: 10,
        backgroundColor: colors.primaryText,
        foregroundColor: isDark ? colors.cardColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.borderColor),
        ),
        icon: const Icon(Icons.cloud_download, size: 18),
        label: saving
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? Colors.black : Colors.white,
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
                field(
                  context: context,
                  colors: colors,
                  label: "Full Name",
                  controller: nameController,
                ),

                field(
                  context: context,
                  colors: colors,
                  label: "Phone",
                  controller: phoneController,
                  keyboard: TextInputType.phone,
                ),

                if (userType == "faculty") ...[
                  field(
                    context: context,
                    colors: colors,
                    label: "Department",
                    controller: departmentController,
                  ),

                  field(
                    context: context,
                    colors: colors,
                    label: "Designation",
                    controller: designationController,
                  ),
                ] else ...[
                  field(
                    context: context,
                    colors: colors,
                    label: "Branch",
                    controller: branchController,
                  ),

                  field(
                    context: context,
                    colors: colors,
                    label: "Stream",
                    controller: streamController,
                  ),

                  field(
                    context: context,
                    colors: colors,
                    label: "Graduating Year",
                    controller: yearController,
                    keyboard: TextInputType.number,
                  ),
                ],

                const SizedBox(height: 80),
              ],
            ),
          );
        },

        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, s) => Center(
          child: Text(
            "Failed to load profile",
            style: TextStyle(color: colors.primaryText),
          ),
        ),
      ),
    );
  }
}
