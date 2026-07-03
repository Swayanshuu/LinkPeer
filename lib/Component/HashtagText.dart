import 'package:flutter/material.dart';

import 'app_colors.dart';

class HashtagText extends StatelessWidget {
  final String text;
  final double fontSize;

  const HashtagText({super.key, required this.text, this.fontSize = 14});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final regex = RegExp(r'#[A-Za-z0-9_]+|\n|[^\n#]+');

    final matches = regex.allMatches(text);

    return RichText(
      text: TextSpan(
        children: matches.map((m) {
          final word = m.group(0)!;

          final isHash = word.startsWith('#');

          return TextSpan(
            text: word,
            style: TextStyle(
              color: isHash ? Colors.blue : colors.primaryText,
              fontSize: fontSize,
              fontWeight: isHash ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }
}
