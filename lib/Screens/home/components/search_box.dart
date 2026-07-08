import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: colors.secondaryText),
          const SizedBox(width: 10),
          Text(
            "Search jobs, alumni...",
            style: TextStyle(color: colors.secondaryText),
          ),
        ],
      ),
    );
  }
}
