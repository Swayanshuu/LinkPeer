import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:igit_connects/core/app_colors.dart';

Widget buildField({
  required BuildContext context,
  required TextEditingController controller,
  required String hint,
  int maxLines = 1,
  int? maxLength,
  IconData? icon,
}) {
  final colors = AppColors.of(context);

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
        counterStyle: TextStyle(color: colors.secondaryText),

        prefixIcon: icon != null
            ? Icon(icon, color: colors.secondaryText, size: 20)
            : null,

        hintText: hint,

        hintStyle: TextStyle(
          color: colors.secondaryText,
          fontSize: 14,
        ),

        border: InputBorder.none,

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    ),
  );
}