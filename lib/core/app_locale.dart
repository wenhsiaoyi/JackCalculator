import 'dart:ui' show Locale;

/// App 語系。UI 層概念，不進引擎吃的 `CalcSettings`（spec D1）。
enum AppLocale {
  english('en', '', 'en'),
  simplified('zh', 'Hans', 'zh_Hans'),
  traditional('zh', 'Hant', 'zh_Hant');

  const AppLocale(this.languageCode, this.scriptCode, this.prefsCode);

  final String languageCode;

  /// 空字串代表不帶 script（例如裸 `zh`）。
  final String scriptCode;

  /// 持久化用的穩定字串碼；enum 改名不會毀掉使用者舊設定。
  final String prefsCode;

  Locale get locale => scriptCode.isEmpty
      ? Locale(languageCode)
      : Locale.fromSubtags(languageCode: languageCode, scriptCode: scriptCode);

  /// 壞值與缺 key 一律回 `null`，語意是「跟隨系統」（spec D2／D3）。
  static AppLocale? fromPrefsCode(String? code) {
    for (final locale in AppLocale.values) {
      if (locale.prefsCode == code) return locale;
    }
    return null;
  }
}

/// 從系統偏好清單解析語系（spec D5）。不交給 Flutter 的 matcher：
/// 系統回報 `zh_TW`（無 scriptCode）時 `zh_Hans` 與 `zh_Hant` 同分，
/// 會按 supportedLocales 的字母序誤解析成簡體。
AppLocale resolveFrom(Iterable<Locale?> systemLocales) {
  for (final locale in systemLocales.whereType<Locale>()) {
    if (locale.languageCode == 'en') return AppLocale.english;
    if (locale.languageCode != 'zh') continue;
    final region = locale.countryCode;
    final isHant = locale.scriptCode == 'Hant' ||
        region == 'TW' ||
        region == 'HK' ||
        region == 'MO';
    return isHant ? AppLocale.traditional : AppLocale.simplified;
  }
  return AppLocale.english;
}
