import 'package:flutter/material.dart';
import 'package:igit_connects/core/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    
    return Scaffold(
      backgroundColor: colors.bgColor,
      appBar: AppBar(
        title: Text("About", style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: colors.bgColor,
        iconTheme: IconThemeData(color: colors.primaryText),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "LinkPeer",
              style: TextStyle(
                color: colors.primaryText,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Connecting Students • Alumni • Faculty",
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Version 1.0.0",
              style: TextStyle(
                color: colors.primaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
