import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/ad_service.dart';

/// 主畫面底部錨定自適應 Banner（spec D4／D5）。
/// 載入前、失敗、桌面一律 zero-size，不佔版面。
/// 顯示滿 [visibleDuration] 後自動消失，本次啟動不再出現。
class BannerAdView extends StatefulWidget {
  const BannerAdView({super.key});

  /// 需求：Banner 顯示 15 秒後消失；計時從實際顯示（onAdLoaded）起算。
  static const Duration visibleDuration = Duration(seconds: 15);

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  BannerAd? _bannerAd;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    if (!AdService.supported) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_loadAd());
    });
  }

  Future<void> _loadAd() async {
    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    final ad = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _bannerAd = ad as BannerAd);
          _hideTimer?.cancel();
          _hideTimer = Timer(BannerAdView.visibleDuration, _hideAd);
        },
        onAdFailedToLoad: (ad, error) {
          // 自動重新整理失敗時 ad 可能正是顯示中的那顆，不能 dispose。
          if (_bannerAd != ad) ad.dispose();
        },
      ),
    );
    // load() 必須在進 widget tree 之前呼叫（規格）；這裡只在 onAdLoaded 後才掛樹。
    unawaited(ad.load());
  }

  void _hideAd() {
    _hideTimer = null;
    final ad = _bannerAd;
    // 先離樹再 dispose，避免 AdWidget 還在樹上時廣告已被釋放。
    setState(() => _bannerAd = null);
    ad?.dispose();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _bannerAd;
    if (ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}