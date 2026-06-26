// Component/Profile/ProfileStatBox.dart

import 'package:flutter/material.dart';

import '../app_colors.dart';

class ProfileStatBox extends StatelessWidget {
  final String title;
  final String value;

  const ProfileStatBox({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          title,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}