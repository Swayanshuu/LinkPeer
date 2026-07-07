import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';

class CreatePostTopSection extends StatelessWidget {
  final String postType;
  final Function(String) onChanged;

  const CreatePostTopSection({
    super.key,
    required this.postType,
    required this.onChanged,
  });

  IconData _getIconForType(String type) {
    switch (type) {
      case "job":
        return Icons.work_outline_rounded;
      case "announcement":
        return Icons.campaign_outlined;
      case "internship":
        return Icons.school_outlined;
      case "normal":
      default:
        return Icons.people_outline_rounded;
    }
  }

  Color _getColorForType(String type, AppColors colors) {
    switch (type) {
      case "job":
        return colors.categoryJob;
      case "announcement":
        return colors.categoryAnnouncement;
      case "internship":
        return colors.categoryInternship;
      case "normal":
      default:
        return colors.primaryAccent;
    }
  }

  String _getLabelForType(String type) {
    if (type == "normal") return "General";
    return type[0].toUpperCase() + type.substring(1);
  }

  Widget _buildChip(String type, AppColors colors) {
    final selected = postType == type;
    final typeColor = _getColorForType(type, colors);
    final icon = _getIconForType(type);
    final label = _getLabelForType(type);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => onChanged(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? typeColor.withValues(alpha: 0.08) : colors.bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? typeColor : colors.borderColor.withValues(alpha: 0.6),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? typeColor : typeColor.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? typeColor : colors.primaryText,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Post Category",
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.4,
            ),
          ),
          
          const SizedBox(height: 20),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildChip("normal", colors),
                _buildChip("job", colors),
                _buildChip("internship", colors),
                _buildChip("announcement", colors),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          Text(
            "Choose a category that best fits your post.",
            style: TextStyle(color: colors.secondaryText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}


