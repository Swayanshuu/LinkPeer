import 'package:flutter/material.dart';
import '../../../Component/app_colors.dart';

class CreatePostTopSection extends StatelessWidget {
  final String postType;
  final Function(String) onChanged;

  const CreatePostTopSection({
    super.key,
    required this.postType,
    required this.onChanged,
  });

  Color typeColor(String type) {
    switch (type) {
      case "job":
        return const Color(0xff1E7D45);
      case "announcement":
        return const Color(0xffA8641A);
      case "internship":
        return const Color(0xff2457C5);
      default:
        return Colors.grey;
    }
  }

  Widget chip(String type, AppColors colors) {
    final selected = postType == type;

    return Padding(
      padding: const EdgeInsets.only(right: 8),

      child: GestureDetector(
        onTap: () => onChanged(type),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),

          decoration: BoxDecoration(
            color: selected
                ? typeColor(type)
                : colors.bgColor,

            borderRadius: BorderRadius.circular(16),

            border: Border.all(
              color: selected
                  ? typeColor(type)
                  : colors.borderColor,
            ),
          ),

          child: Text(
            type.toUpperCase(),
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : colors.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: colors.cardColor,

        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color: colors.borderColor,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            "Create Post",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Share updates with your campus network",
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,

            child: Row(
              children: [
                chip("normal", colors),
                chip("job", colors),
                chip("announcement", colors),
                chip("internship", colors),
              ],
            ),
          ),
        ],
      ),
    );
  }
}