import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final double elevation;
  final Clip clipBehavior;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16.0,
    this.elevation = 0.0,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final effectiveBgColor = backgroundColor ?? colors.cardColor;
    final effectiveBorderColor = borderColor ?? colors.borderColor;

    final cardContent = Container(
      padding: padding,
      child: child,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorderColor),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04 * elevation),
                  blurRadius: 4.0 * elevation,
                  offset: Offset(0, 2.0 * elevation),
                ),
              ]
            : null,
      ),
      clipBehavior: clipBehavior,
      child: onTap != null || onLongPress != null
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                splashColor: colors.primaryAccent.withValues(alpha: 0.1),
                highlightColor: colors.primaryAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(borderRadius),
                child: cardContent,
              ),
            )
          : cardContent,
    );
  }
}
