import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/core/app_strings.dart';

/// 13 個欄位的存取器，讓下面三個 `_fields` 遍歷測試不用逐條複製。
/// 值是閉包，Dart 不能宣告成 `const`，這裡用 `final`（plan 原文的 `const` 無法編譯）。
final Map<String, String Function(AppStrings)> _fields = {
  'appTitle': (s) => s.appTitle,
  'settingsTitle': (s) => s.settingsTitle,
  'taxRateLabel': (s) => s.taxRateLabel,
  'taxRateHelper': (s) => s.taxRateHelper,
  'taxRateError': (s) => s.taxRateError,
  'roundingMode': (s) => s.roundingMode,
  'decimalPlaces': (s) => s.decimalPlaces,
  'decimalPlacesInactive': (s) => s.decimalPlacesInactive,
  'grouping': (s) => s.grouping,
  'placesSuffix': (s) => s.placesSuffix,
  'indicatorSeparator': (s) => s.indicatorSeparator,
  'languageLabel': (s) => s.languageLabel,
  'languageSystem': (s) => s.languageSystem,
};

void main() {
  test('of() 對映三個語系，未知 locale 退回 english', () {
    expect(AppStrings.of(const Locale('en')), AppStrings.english);
    expect(AppStrings.of(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')), AppStrings.simplified);
    expect(AppStrings.of(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')), AppStrings.traditional);
    // 解析規則本身在 app_locale_test 測；這裡只確認 fallback 不拋、不回 null。
    expect(AppStrings.of(const Locale('und')), AppStrings.english);
    expect(AppStrings.of(const Locale('zh', 'TW')), AppStrings.traditional);
  });

  test('每個欄位在三語下都已填（不允許空字串）', () {
    for (final catalog in [
      AppStrings.english,
      AppStrings.simplified,
      AppStrings.traditional,
    ]) {
      for (final entry in _fields.entries) {
        expect(entry.value(catalog).trim(), isNotEmpty, reason: entry.key);
      }
    }
  });

  test('繁簡只差在字形：刻意相同的三欄以外不得相同', () {
    const sharedByDesign = {'grouping', 'placesSuffix', 'indicatorSeparator'};
    for (final entry in _fields.entries) {
      final hant = entry.value(AppStrings.traditional);
      final hans = entry.value(AppStrings.simplified);
      if (sharedByDesign.contains(entry.key)) {
        expect(hans, hant, reason: '${entry.key} 繁簡本就同字');
      } else {
        expect(hans, isNot(hant), reason: '${entry.key} 繁簡應有差異');
      }
    }
  });

  test('英文目錄不與任一中文目錄撞字', () {
    for (final entry in _fields.entries) {
      final en = entry.value(AppStrings.english);
      expect(en, isNot(entry.value(AppStrings.traditional)), reason: entry.key);
      expect(en, isNot(entry.value(AppStrings.simplified)), reason: entry.key);
    }
  });

  test('語言選項標籤三語都不翻（spec D8）', () {
    expect(AppStrings.languageEnglish, 'English');
    expect(AppStrings.languageTraditional, '繁體中文');
    expect(AppStrings.languageSimplified, '简体中文');
  });

  test('zh-Hans 用道地大陸用語，不是繁簡字形轉換', () {
    expect(AppStrings.simplified.settingsTitle, '设置');
    expect(AppStrings.simplified.taxRateError, contains('请输入'));
    expect(AppStrings.simplified.decimalPlaces, '小数位数');
    expect(AppStrings.simplified.languageSystem, '跟随系统');
  });
}
