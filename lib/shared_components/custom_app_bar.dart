import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final double elevation;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    super.key,
    required this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.onBackPressed,
    this.elevation = 0.5,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPop = parentRoute?.canPop ?? false;

    return AppBar(
      backgroundColor: colors.cardColor,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0.5,
      elevation: elevation,
      centerTitle: false,
      titleSpacing: (showBackButton && canPop) ? 4.0 : 16.0,
      leading: leading ??
          ((showBackButton && canPop)
              ? IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colors.bgColor.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: colors.primaryText,
                      size: 18,
                    ),
                  ),
                  onPressed: onBackPressed ?? () => Navigator.pop(context),
                  tooltip: 'Back',
                )
              : null),
      title: titleWidget ??
          Text(
            title,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      actions: actions,
      bottom: bottom,
    );
  }
}
