import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();

    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (isMobile) {
      // final adUnitId = kDebugMode
      //     ? (defaultTargetPlatform == TargetPlatform.android
      //           ? 'ca-app-pub-3940256099942544/6300978111'
      //           : 'ca-app-pub-3940256099942544/2934735716')
      //     : (dotenv.env['ADUNITID'] ??
      //           'ca-app-pub-3940256099942544/6300978111');

      final adUnitId = dotenv.env['ADUNITID'];
      _bannerAd = BannerAd(
        size: AdSize.banner,
        adUnitId: adUnitId!,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('AD LOADED');
            setState(() {
              _isLoaded = true;
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('AD FAILED: $error');
            ad.dispose();
          },
        ),
      );

      _bannerAd!.load();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (_bannerAd == null || !_isLoaded) {
      return const SizedBox();
    }

    return SizedBox(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
