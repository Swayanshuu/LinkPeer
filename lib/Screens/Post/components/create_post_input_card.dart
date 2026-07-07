import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';

class CreatePostInputCard extends StatefulWidget {
  final TextEditingController title;
  final TextEditingController content;
  final TextEditingController link;

  const CreatePostInputCard({
    super.key,
    required this.title,
    required this.content,
    required this.link,
  });

  @override
  State<CreatePostInputCard> createState() => _CreatePostInputCardState();
}

class _CreatePostInputCardState extends State<CreatePostInputCard> {
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    widget.content.addListener(_updateCharCount);
  }

  @override
  void dispose() {
    widget.content.removeListener(_updateCharCount);
    super.dispose();
  }

  void _updateCharCount() {
    setState(() {
      _charCount = widget.content.text.length;
    });
  }

  Widget _buildOptionalField({
    required BuildContext context,
    required AppColors colors,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: colors.primaryText, fontSize: 14.5),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: colors.secondaryText, size: 20),
          hintText: hint,
          hintStyle: TextStyle(color: colors.secondaryText, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Content Field (Blue Outline as in Mockup)
        Container(
          decoration: BoxDecoration(
            color: colors.bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.primaryAccent.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: widget.content,
                maxLines: 7,
                maxLength: 2000,
                style: TextStyle(
                  color: colors.primaryText,
                  fontSize: 15.5,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText:
                      "What's happening today?\nShare opportunities, ideas, projects...",
                  hintStyle: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                  counterText: "", // Hide default counter
                ),
              ),

              // Bottom row with icons and counter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 20, 16),
                child: Row(
                  children: [
                    // Mockup Icons (Only #)
                    Text(
                      "#",
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const Spacer(),

                    // Character Counter
                    Text(
                      "$_charCount / 2000",
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.successColor, // Mockup success dot
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Optional Fields (Title and Link)
        Text(
          "Additional details",
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),

        _buildOptionalField(
          context: context,
          colors: colors,
          controller: widget.title,
          hint: "Post title (optional)",
          icon: Icons.title_rounded,
        ),
        const SizedBox(height: 12),
        _buildOptionalField(
          context: context,
          colors: colors,
          controller: widget.link,
          hint: "Attach external link",
          icon: Icons.link_rounded,
        ),
      ],
    );
  }
}
