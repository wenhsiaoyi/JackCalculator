import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 廣告設定唯一入口（spec D2）；僅 Android／iOS 生效（spec D1）。
class AdService {
  const AdService._();

  static bool get supported => Platform.isAndroid || Platform.isIOS;

  /// 模擬器測試裝置 ID（spec D3）：Task 6 從 logcat 取得後填入。
  /// 模擬器本就會自動成為測試裝置，此清單是需求 2 的明確註冊。
  /// 上架前必須清空並移除相關呼叫。
  static const List<String> testDeviceIds = <String>[];

  static Future<void> initialize() async {
    if (!supported) return;
    await MobileAds.instance.initialize();
    if (kDebugMode && testDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
    }
  }

  static String bannerAdUnitIdFor({required bool isAndroid}) => isAndroid
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-3940256099942544/2435281174';

  static String interstitialAdUnitIdFor({required bool isAndroid}) => isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  static String get bannerAdUnitId =>
      bannerAdUnitIdFor(isAndroid: Platform.isAndroid);

  static String get interstitialAdUnitId =>
      interstitialAdUnitIdFor(isAndroid: Platform.isAndroid);

  /// 失敗回 null（spec D13：不拋、不擋操作）。僅行動平台會走到。
  static Future<InterstitialAd?> loadInterstitial() {
    final completer = Completer<InterstitialAd?>();
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: completer.complete,
        onAdFailedToLoad: (_) => completer.complete(null),
      ),
    );
    return completer.future;
  }
}