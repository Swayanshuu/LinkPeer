import 'package:flutter/material.dart';

import 'package:igit_connects/core/app_colors.dart';

class FeedFilterBar extends StatelessWidget {
  final String selected;
  final Function(String) onChanged;

  const FeedFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  IconData _getIconFor(String item) {
    switch (item) {
      case "all":
        return Icons.grid_view_rounded;
      case "job":
        return Icons.work_outline_rounded;
      case "announcement":
        return Icons.campaign_outlined;
      case "internship":
        return Icons.school_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  String _getLabelFor(String item) {
    switch (item) {
      case "all":
        return "All";
      case "job":
        return "Job";
      case "announcement":
        return "Announcement";
      case "internship":
        return "Internship";
      default:
        return item;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final items = ["all", "job", "announcement", "internship"];

    return SizedBox(
      height: 52, // Increased height for vertical padding
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final active = selected == item;

          return GestureDetector(
            onTap: () => onChanged(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF3B82F6) : colors.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? const Color(0xFF3B82F6) : colors.borderColor,
                ),
                boxShadow: [
                  if (!active)
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIconFor(item),
                    size: 16,
                    color: active ? Colors.white : colors.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _getLabelFor(item),
                    style: TextStyle(
                      color: active ? Colors.white : colors.primaryText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
