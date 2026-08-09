import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:igit_connects/core/app_colors.dart';

class NoticeImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const NoticeImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  Future<void> _openBrowser() async {
    try {
      final uri = Uri.parse(imageUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  Future<void> _shareImage() async {
    await Share.share(imageUrl, subject: title);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareImage,
            tooltip: 'Share Image',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser, color: Colors.white),
            onPressed: _openBrowser,
            tooltip: 'Open in Browser',
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => Center(
              child: CircularProgressIndicator(color: colors.primaryAccent),
            ),
            errorWidget: (context, url, error) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.broken_image, size: 64, color: Colors.redAccent),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _openBrowser,
                  icon: const Icon(Icons.open_in_new, color: Colors.white),
                  label: const Text('Open Externally', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
