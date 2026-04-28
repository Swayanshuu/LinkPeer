import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../AppColour.dart';

Widget buildField({
  required TextEditingController controller,
  required String hint,
  int maxLines = 1,
  int? maxLength,
  IconData? icon,
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
        counterStyle: const TextStyle(color: AppColours.secondaryText),

        prefixIcon: icon != null
            ? Icon(icon, color: AppColours.secondaryText, size: 20)
            : null,

        hintText: hint,

        hintStyle: const TextStyle(
          color: AppColours.secondaryText,
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