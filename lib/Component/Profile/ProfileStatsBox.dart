// Component/Profile/ProfileStatBox.dart

import 'package:flutter/material.dart';

class ProfileStatBox extends StatelessWidget {
  final String title;
  final String value;

  const ProfileStatBox({
    super.key,
    required this.title,
    required this.value,
  });

  @override
  Widget build(
      BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style:
          const TextStyle(
            color:
            Colors.white,
            fontSize: 18,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const SizedBox(
            height: 4),

        Text(
          title,
          style:
          const TextStyle(
            color:
            Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}