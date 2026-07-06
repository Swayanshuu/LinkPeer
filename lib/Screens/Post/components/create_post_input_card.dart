import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';

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

  Widget _buildField({
    required BuildContext context,
    required AppColors colors,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderColor),
      ),

      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,

        style: TextStyle(
          color: colors.primaryText,
          fontSize: 15,
          height: 1.4,
        ),

        decoration: InputDecoration(
          border: InputBorder.none,

          prefixIcon: Icon(icon, color: colors.secondaryText, size: 20),

          hintText: hint,

          hintStyle: TextStyle(
            color: colors.secondaryText,
            fontSize: 14,
          ),

          counterStyle: TextStyle(color: colors.secondaryText),

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
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: colors.cardColor,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: colors.borderColor),
      ),

      child: Column(
        children: [
          _buildField(
            context: context,
            colors: colors,
            controller: title,
            hint: "Post title (optional)",
            icon: Icons.title,
          ),

          const SizedBox(height: 14),

          _buildField(
            context: context,
            colors: colors,
            controller: content,
            hint: "Share something with community...",
            icon: Icons.edit_note,
            maxLines: 6,
            maxLength: 2000,
          ),

          const SizedBox(height: 14),

          _buildField(
            context: context,
            colors: colors,
            controller: link,
            hint: "Attach external link",
            icon: Icons.link,
          ),
        ],
      ),
    );
  }
}
