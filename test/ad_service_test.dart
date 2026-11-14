import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/core/ad_service.dart';

void main() {
  test('Windows／Linux host 上 supported 為 false', () {
    expect(AdService.supported, isFalse);
  });

  test('initialize() 在不支援平台是 no-op（不觸碰 MobileAds）', () async {
    // 若誤呼叫 MobileAds，test binding 無 platform channel 會拋
    // MissingPluginException；能完成即證明 guard 生效。
    await AdService.initialize();
  });

  test('bannerAdUnitIdFor 按平台選官方測試 ID', () {
    expect(AdService.bannerAdUnitIdFor(isAndroid: true),
        'ca-app-pub-3940256099942544/9214589741');
    expect(AdService.bannerAdUnitIdFor(isAndroid: false),
        'ca-app-pub-3940256099942544/2435281174');
  });

  test('interstitialAdUnitIdFor 按平台選官方測試 ID', () {
    expect(AdService.interstitialAdUnitIdFor(isAndroid: true),
        'ca-app-pub-3940256099942544/1033173712');
    expect(AdService.interstitialAdUnitIdFor(isAndroid: false),
        'ca-app-pub-3940256099942544/4411468910');
  });
}