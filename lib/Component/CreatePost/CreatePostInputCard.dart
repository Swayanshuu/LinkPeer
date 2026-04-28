// CreatePostInputCard.dart

import 'package:flutter/material.dart';
import '../AppColour.dart';

class CreatePostInputCard extends StatelessWidget {
  final TextEditingController title;
  final TextEditingController content;
  final TextEditingController link;

  const CreatePostInputCard({
    super.key,
    required this.title,
    required this.content,
    required this.link,
  });

  // Common TextField
  Widget buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColours.bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColours.borderColor),
      ),

      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,

        style: const TextStyle(
          color: AppColours.primaryText,
          fontSize: 15,
          height: 1.4,
        ),

        decoration: InputDecoration(
          border: InputBorder.none,

          prefixIcon: Icon(icon, color: AppColours.secondaryText, size: 20),

          hintText: hint,

          hintStyle: const TextStyle(
            color: AppColours.secondaryText,
            fontSize: 14,
          ),

          counterStyle: const TextStyle(color: AppColours.secondaryText),

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppColours.cardColor,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: AppColours.borderColor),
      ),

      child: Column(
        children: [
          buildField(
            controller: title,
            hint: "Post title (optional)",
            icon: Icons.title,
          ),

          const SizedBox(height: 14),

          buildField(
            controller: content,
            hint: "Share something with community...",
            icon: Icons.edit_note,
            maxLines: 6,
            maxLength: 2000,
          ),

          const SizedBox(height: 14),

          buildField(
            controller: link,
            hint: "Attach external link",
            icon: Icons.link,
          ),
        ],
      ),
    );
  }
}
