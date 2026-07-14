import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:igit_connects/core/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shimmer/shimmer.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  NativeAd? _nativeAd;
  bool _nativeAdIsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (!isMobile) return;

    final adUnitId = kDebugMode
        ? (defaultTargetPlatform == TargetPlatform.android
              ? 'ca-app-pub-3940256099942544/2247696110'
              : 'ca-app-pub-3940256099942544/3986624511')
        : (dotenv.env['NATIVE_AD_UNIT_ID'] ??
              'a-app-pub-3940256099942544/2247696110');

    // final adUnitId = dotenv.env['NATIVE_AD_UNIT_ID'];
    _nativeAd = NativeAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('NATIVE AD LOADED');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NATIVE AD FAILED: $error');
          ad.dispose();
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        cornerRadius: 16.0,
      ),
    );

    _nativeAd!.load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  Widget _buildPlaceholder(AppColors colors, bool isDark) {
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 350,
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 20, backgroundColor: Colors.white),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(width: 80, height: 10, color: Colors.white),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 16, color: Colors.white),
            const SizedBox(height: 6),
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 16,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(width: double.infinity, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_nativeAd == null || !_nativeAdIsLoaded) {
      // return _buildPlaceholder(colors, isDark);
      return SizedBox(height: 20);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(
        minWidth: 320,
        maxWidth: double.infinity,
        minHeight: 350,
        maxHeight:
            350, // Fixed height to match PostCard and prevent ListView layout errors
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
