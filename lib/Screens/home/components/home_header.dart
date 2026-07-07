import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:igit_connects/core/theme_provider.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:auto_size_text/auto_size_text.dart';

class HomeHeader extends ConsumerWidget {
  final Map me;

  const HomeHeader({super.key, required this.me});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),

      decoration: BoxDecoration(
        color: colors.cardColor,

        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),

        border: Border.all(color: colors.borderColor),
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back",
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 6),

                AutoSizeText(
                  me["name"],
                  maxLines: 1,
                  minFontSize: 18,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primaryText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Theme toggle button
          GestureDetector(
            onTap: () => ref.read(themeProvider.notifier).toggle(),
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colors.bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderColor),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: colors.primaryText,
                size: 20,
              ),
            ),
          ),

          if (MediaQuery.of(context).size.width <= 1024)
            GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },

              child: CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(me["photo_url"]),
              ),
            ),
        ],
      ),
    );
  }
}
