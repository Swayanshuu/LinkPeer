import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';

class UpdateFeatureTile extends StatelessWidget {
  final String feature;

  const UpdateFeatureTile({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: colors.primaryAccent,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
