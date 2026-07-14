import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static final ScreenshotController _screenshotController =
      ScreenshotController();

  /// Captures a widget as an image, saves it temporarily, and opens the native share sheet.
  static Future<void> shareWidgetAsImage({
    required Widget widget,
    required String shareUrl,
    required String postTitle,
  }) async {
    try {
      // Capture widget as image
      final imageBytes = await _screenshotController.captureFromWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: widget),
          ),
        ),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
      );

      // Write to temp file
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/share_post.png').create();
      await imagePath.writeAsBytes(imageBytes);

      // Share via native share sheet
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Check out this post on LinkPeer: $postTitle\n\n$shareUrl',
        subject: postTitle,
      );
    } catch (e) {
      debugPrint("Error sharing post: $e");
    }
  }

  /// Generates a universal link for a post instantly
  static Future<String> generateShortLink({
    required String postId,
    required String title,
    String? imageUrl,
  }) async {
    return 'https://linkpeer.swynx.dev/post/$postId';
  }
}
