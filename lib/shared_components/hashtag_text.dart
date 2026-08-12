import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:igit_connects/core/app_colors.dart';

class HashtagText extends StatefulWidget {
  final String text;
  final double fontSize;
  final TextStyle? style;

  const HashtagText({
    super.key,
    required this.text,
    this.fontSize = 14,
    this.style,
  });

  @override
  State<HashtagText> createState() => _HashtagTextState();
}

class _HashtagTextState extends State<HashtagText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  Future<void> _launchURL(String rawUrl) async {
    String url = rawUrl;
    if (url.toLowerCase().startsWith('www.')) {
      url = 'https://$url';
    }
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL $url: $e');
    }
  }

  List<InlineSpan> _buildSpans(AppColors colors) {
    _clearRecognizers();
    final spans = <InlineSpan>[];
    final text = widget.text;

    final combinedRegex = RegExp(
      r'(https?:\/\/[^\s<>()]+|www\.[^\s<>()]+)|(#[A-Za-z0-9_]+)',
      caseSensitive: false,
    );

    final matches = combinedRegex.allMatches(text);
    int lastIndex = 0;

    final defaultStyle = widget.style ??
        TextStyle(
          color: colors.primaryText,
          fontSize: widget.fontSize,
        );

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(
          TextSpan(
            text: text.substring(lastIndex, match.start),
            style: defaultStyle,
          ),
        );
      }

      final matchedText = match.group(0)!;
      final isUrl = match.group(1) != null;

      if (isUrl) {
        String cleanUrl = matchedText;
        String trailing = '';
        while (cleanUrl.isNotEmpty &&
            '.!,;:?)]'.contains(cleanUrl[cleanUrl.length - 1])) {
          trailing = cleanUrl[cleanUrl.length - 1] + trailing;
          cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
        }

        if (cleanUrl.isNotEmpty) {
          final recognizer = TapGestureRecognizer()
            ..onTap = () => _launchURL(cleanUrl);
          _recognizers.add(recognizer);

          spans.add(
            TextSpan(
              text: cleanUrl,
              style: defaultStyle.copyWith(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                decorationColor: Colors.blue,
              ),
              recognizer: recognizer,
            ),
          );
        }

        if (trailing.isNotEmpty) {
          spans.add(
            TextSpan(
              text: trailing,
              style: defaultStyle,
            ),
          );
        }
      } else {
        spans.add(
          TextSpan(
            text: matchedText,
            style: defaultStyle.copyWith(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastIndex),
          style: defaultStyle,
        ),
      );
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return RichText(
      text: TextSpan(
        children: _buildSpans(colors),
      ),
    );
  }
}

