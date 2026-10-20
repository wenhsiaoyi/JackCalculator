import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/core/app_locale.dart';

void main() {
  group('resolveFrom 依偏好清單順序', () {
    test('繁體線索：Hant 腳本或 TW/HK/MO 地區', () {
      expect(resolveFrom([const Locale('zh', 'TW')]), AppLocale.traditional);
      expect(resolveFrom([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')]), AppLocale.traditional);
      expect(resolveFrom([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK')]), AppLocale.traditional);
      expect(resolveFrom([const Locale('zh', 'MO')]), AppLocale.traditional);
    });

    test('簡體線索：裸 zh、Hans 腳本、CN/SG 地區', () {
      expect(resolveFrom([const Locale('zh')]), AppLocale.simplified);
      expect(resolveFrom([const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')]), AppLocale.simplified);
      expect(resolveFrom([const Locale('zh', 'CN')]), AppLocale.simplified);
      expect(resolveFrom([const Locale('zh', 'SG')]), AppLocale.simplified);
      // M3：zh 配到未列出的地區（此處加拿大）時，规则 3 的「沒有 Hant 線索 → 簡體」
      // 是被斷言的決定，不是哪天會被人順手改動的意外。
      expect(resolveFrom([const Locale('zh', 'CA')]), AppLocale.simplified);
    });

    test('清單順序優先，未識別的語系繼續往後找', () {
      expect(resolveFrom([const Locale('en'), const Locale('zh', 'TW')]),
          AppLocale.english);
      expect(resolveFrom([const Locale('ja'), const Locale('zh', 'TW')]),
          AppLocale.traditional);
    });

    test('其他語系與空清單退回 english', () {
      expect(resolveFrom([const Locale('ja')]), AppLocale.english);
      expect(resolveFrom([const Locale('fr', 'FR')]), AppLocale.english);
      expect(resolveFrom(<Locale?>[]), AppLocale.english);
      expect(resolveFrom([null]), AppLocale.english);
    });
  });

  group('持久化碼', () {
    test('prefsCode 往返一致，壞值與 null 回 null（跟隨系統）', () {
      for (final l in AppLocale.values) {
        expect(AppLocale.fromPrefsCode(l.prefsCode), l);
      }
      expect(AppLocale.fromPrefsCode('zh'), isNull);
      expect(AppLocale.fromPrefsCode('de'), isNull);
      expect(AppLocale.fromPrefsCode(null), isNull);
    });

    test('locale 帶正確 scriptCode，裸 zh 不帶 script', () {
      expect(AppLocale.traditional.locale, const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'));
      expect(AppLocale.simplified.locale, const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));
      expect(AppLocale.english.locale, const Locale('en'));
    });
  });
}
