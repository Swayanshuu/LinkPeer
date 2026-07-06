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
      // 1. Capture the widget as an image
      final imageBytes = await _screenshotController.captureFromWidget(
        widget,
        delay: const Duration(milliseconds: 200),
        context:
            null, // Ideally we pass context if needed, but this works for basic widgets
      );

      // 2. Save the image temporarily
      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/share_post.png').create();
      await imagePath.writeAsBytes(imageBytes);

      // 3. Share via native share sheet
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Check out this post on LinkPeer: $postTitle\n\n$shareUrl',
        subject: postTitle,
      );
    } catch (e) {
      debugPrint("Error sharing post: $e");
    }
  }

  /// Calls the Spring Boot API to generate a short link for a post
  static Future<String> generateShortLink({
    required String postId,
    required String title,
    String? imageUrl,
  }) async {
    const apiUrl = 'https://go.swynx.dev/api/links';
    final targetUrl = 'linkpeer://post/$postId'; // Custom scheme deep link

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(apiUrl));
      request.headers.set('Content-Type', 'application/json');

      final payload = {'targetUrl': targetUrl, 'title': title};
      if (imageUrl != null && imageUrl.isNotEmpty) {
        payload['imageUrl'] = imageUrl;
      }

      request.add(utf8.encode(jsonEncode(payload)));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return data['shortUrl'];
      } else {
        debugPrint('Failed to generate short link: $responseBody');
        return targetUrl;
      }
    } catch (e) {
      debugPrint('Error generating short link: $e');
      return targetUrl;
    }
  }
}
