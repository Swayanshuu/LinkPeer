// Component/Profile/ProfileStatsRow.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:igit_connects/core/app_colors.dart';

class ProfileStatsRow extends StatelessWidget {
  final Map data;
  final AsyncValue posts;

  const ProfileStatsRow({super.key, required this.data, required this.posts});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    final count = posts.maybeWhen(
      data: (list) => list.where((p) => p["user_id"] == data["id"]).length.toString(),
      orElse: () => "0",
    );
    
    final savedCount = posts.maybeWhen(
      data: (list) {
        final saved = list.where((p) {
          final savedList = p["saved_posts"] as List? ?? [];
          return savedList.any((s) => s["user_id"] == data["id"]);
        }).toList();
        return saved.length.toString();
      },
      orElse: () => "0",
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(count, "Posts", Icons.article_outlined, Colors.purple, colors),
          _buildDivider(colors),
          _buildStatItem(savedCount, "Saved Posts", Icons.bookmark_outline_rounded, Colors.green, colors),
        ],
      ),
    );
  }

  Widget _buildDivider(AppColors colors) {
    return Container(
      height: 32,
      width: 1,
      color: colors.borderColor.withValues(alpha: 0.5),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color iconColor, AppColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor.withValues(alpha: 0.8)),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: colors.secondaryText,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

