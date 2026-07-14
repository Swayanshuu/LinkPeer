import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:igit_connects/core/app_colors.dart';
import 'package:igit_connects/core/app_constants.dart';
import 'package:igit_connects/core/user_provider.dart';
import 'package:igit_connects/utils/profanity_filter.dart';

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
  final githubController = TextEditingController();
  final link2Controller = TextEditingController();
  final descriptionController = TextEditingController();

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
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        maxLines: maxLines,
        maxLength: maxLength,
        style: TextStyle(color: colors.primaryText, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors.secondaryText, fontSize: 14),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? colors.bgColor.withValues(alpha: 0.5)
              : colors.bgColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colors.borderColor.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colors.borderColor.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget dropdownField({
    required BuildContext context,
    required AppColors colors,
    required String label,
    required TextEditingController controller,
    required List<String> items,
  }) {
    final validValue = items.contains(controller.text) ? controller.text : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: validValue,
        dropdownColor: colors.cardColor,
        style: TextStyle(color: colors.primaryText, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colors.secondaryText, fontSize: 14),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? colors.bgColor.withValues(alpha: 0.5)
              : colors.bgColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colors.borderColor.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: colors.borderColor.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() {
              controller.text = v;
            });
          }
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children, AppColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Name and Phone are required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (phone.length != 10 || int.tryParse(phone) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter a valid 10-digit phone number"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (ProfanityFilter.hasProfanity(nameController.text) ||
        ProfanityFilter.hasProfanity(descriptionController.text) ||
        ProfanityFilter.hasProfanity(githubController.text) ||
        ProfanityFilter.hasProfanity(link2Controller.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please remove inappropriate language from your profile.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userType == "faculty") {
      final dept = departmentController.text.trim();
      final desig = designationController.text.trim();
      if (dept.isEmpty || desig.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Department and Designation are required"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else {
      final branch = branchController.text.trim();
      final stream = streamController.text.trim();
      final year = yearController.text.trim();
      if (branch.isEmpty || stream.isEmpty || year.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Branch, Stream, and Graduating Year are required"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    try {
      setState(() {
        saving = true;
      });

      final uid = FirebaseAuth.instance.currentUser!.uid;

      final baseData = {
        "github": githubController.text.trim(),
        "link2": link2Controller.text.trim(),
        "description": descriptionController.text.trim(),
      };

      final data = userType == "faculty"
          ? {
              ...baseData,
              "name": nameController.text.trim(),
              "phone": phoneController.text.trim(),
              "department": departmentController.text.trim(),
              "designation": designationController.text.trim(),
            }
          : userType == "admin"
          ? {
              ...baseData,
              "name": nameController.text.trim(),
              "phone": phoneController.text.trim(),
              "branch": branchController.text.trim(),
              "stream": streamController.text.trim(),
              "graduating_year": int.tryParse(yearController.text.trim()),
              "user_type": "admin",
              "role": "admin",
              "is_verified": true,
            }
          : {
              ...baseData,
              "name": nameController.text.trim(),
              "phone": phoneController.text.trim(),
              "branch": branchController.text.trim(),
              "stream": streamController.text.trim(),
              "graduating_year": int.tryParse(yearController.text.trim()),
              "user_type": getUpdatedUserType(yearController.text.trim()),
            };

      // Update user table
      await Supabase.instance.client.from('users').update(data).eq('id', uid);

      // 2. Update the user's posts so their name/branch/user_type is instantly reflected on all their posts
      try {
        final postUpdateData = {
          "user_name": data["name"],
          "user_type":
              data["user_type"] ?? (userType == "faculty" ? "faculty" : null),
          "department": data["branch"] ?? data["department"],
        };
        // Clean up nulls
        postUpdateData.removeWhere((key, value) => value == null);
        if (postUpdateData.isNotEmpty) {
          await Supabase.instance.client
              .from('posts')
              .update(postUpdateData)
              .eq('user_id', uid);
        }
      } catch (e) {
        debugPrint("Failed to update posts: $e");
      }

      // 3. Invalidate providers to trigger refetch
      ref.invalidate(userProvider);

      // We can't easily import postsProvider here without a circular dependency or adding an import,
      // but wait, postsProvider is in core/post_provider.dart? Let's check imports.
      // Actually we don't have it imported. Let's just invalidate userProvider and wait for it.
      await ref.read(userProvider.future);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving: $e\nDid you run the SQL command?"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
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
    final user = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: colors.bgColor,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: colors.bgColor,
        surfaceTintColor: colors.bgColor,
        iconTheme: IconThemeData(color: colors.primaryText),
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: colors.primaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: saving ? null : save,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: colors.onPrimaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: saving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.onPrimaryAccent,
                      ),
                    )
                  : const Icon(Icons.cloud_download, size: 16),
              label: Text(
                saving ? "Saving..." : "Save",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),

      body: user.when(
        data: (data) {
          if (!initialized) {
            initialized = true;

            // Fetch user type case-insensitively and also check if role is admin
            final fetchedType = (data["user_type"] ?? "student")
                .toString()
                .toLowerCase();
            final fetchedRole = (data["role"] ?? "").toString().toLowerCase();

            if (fetchedRole == "admin" || fetchedType == "admin") {
              userType = "admin";
            } else {
              userType = fetchedType;
            }

            nameController.text = (data["name"] ?? "").toString();

            phoneController.text = (data["phone"] ?? "").toString();

            branchController.text = (data["branch"] ?? "").toString();

            streamController.text = (data["stream"] ?? "").toString();

            yearController.text = (data["graduating_year"] ?? "").toString();

            departmentController.text = (data["department"] ?? "").toString();
            designationController.text = (data["designation"] ?? "").toString();
            githubController.text = (data["github"] ?? "").toString();
            link2Controller.text = (data["link2"] ?? "").toString();
            descriptionController.text = (data["description"] ?? "").toString();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                _buildSection("Personal Information", [
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
                    maxLength: 10,
                  ),
                  field(
                    context: context,
                    colors: colors,
                    label: "Bio / Description",
                    controller: descriptionController,
                    maxLines: 3,
                    maxLength: 150,
                  ),
                ], colors),

                if (userType == "faculty")
                  _buildSection("Academic Details", [
                    dropdownField(
                      context: context,
                      colors: colors,
                      label: "Department",
                      controller: departmentController,
                      items: AppConstants.departments,
                    ),
                    dropdownField(
                      context: context,
                      colors: colors,
                      label: "Designation",
                      controller: designationController,
                      items: AppConstants.designations,
                    ),
                  ], colors)
                else
                  _buildSection("Academic Details", [
                    dropdownField(
                      context: context,
                      colors: colors,
                      label: "Branch",
                      controller: branchController,
                      items: AppConstants.branches,
                    ),
                    dropdownField(
                      context: context,
                      colors: colors,
                      label: "Stream",
                      controller: streamController,
                      items: AppConstants.streams,
                    ),
                    field(
                      context: context,
                      colors: colors,
                      label: "Graduating Year",
                      controller: yearController,
                      keyboard: TextInputType.number,
                    ),
                  ], colors),

                _buildSection("Social Links", [
                  field(
                    context: context,
                    colors: colors,
                    label: "GitHub Username (Optional)",
                    controller: githubController,
                  ),
                  field(
                    context: context,
                    colors: colors,
                    label: "Other link starts with http:// or https://",
                    controller: link2Controller,
                    keyboard: TextInputType.url,
                  ),
                ], colors),

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
