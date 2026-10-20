import 'dart:ui' show Locale;

import 'app_locale.dart';

/// 三語字串目錄（spec D4：不建 Localizations delegate，視覺層直接查表）。
/// 新增字串時三份都要補，`test/app_strings_test.dart` 會抓到漏填。
class AppStrings {
  const AppStrings({
    required this.appTitle,
    required this.settingsTitle,
    required this.taxRateLabel,
    required this.taxRateHelper,
    required this.taxRateError,
    required this.roundingMode,
    required this.decimalPlaces,
    required this.decimalPlacesInactive,
    required this.grouping,
    required this.placesSuffix,
    required this.indicatorSeparator,
    required this.languageLabel,
    required this.languageSystem,
  });

  /// `MaterialApp.title`；原生啟動器名稱不受它影響（spec OUT 項）。
  final String appTitle;
  final String settingsTitle;
  final String taxRateLabel;
  final String taxRateHelper;
  final String taxRateError;
  final String roundingMode;
  final String decimalPlaces;
  final String decimalPlacesInactive;
  final String grouping;

  /// 小數位數後綴：中文「2位」、英文「2 dp」，由 StatusIndicator 拼接。
  final String placesSuffix;

  /// 狀態列分隔符：中文用全形｜，英文用半形直線加空格。
  final String indicatorSeparator;

  final String languageLabel;

  /// 唯一會被翻譯的語言選項；其餘三個是自稱，見下方常數。
  final String languageSystem;

  static const String languageEnglish = 'English';
  static const String languageTraditional = '繁體中文';

  /// 刻意寫簡體：語言選項以該語言自己的書寫系統呈現（spec D8），不是錯字。
  static const String languageSimplified = '简体中文';

  static const AppStrings english = AppStrings(
    appTitle: 'Jack Calculator',
    settingsTitle: 'Settings',
    taxRateLabel: 'Tax rate (%)',
    taxRateHelper: 'Range 0–100, up to 1 decimal',
    taxRateError: 'Enter 0–100 with at most 1 decimal',
    roundingMode: 'Rounding mode',
    decimalPlaces: 'Decimal places',
    decimalPlacesInactive: 'Decimal places (off in F mode)',
    grouping: 'Thousands separator',
    placesSuffix: ' dp',
    indicatorSeparator: '   |   ',
    languageLabel: 'Language',
    languageSystem: 'System',
  );

  static const AppStrings simplified = AppStrings(
    appTitle: 'Jack计算器',
    settingsTitle: '设置',
    taxRateLabel: '税率 (%)',
    taxRateHelper: '范围 0–100，最多一位小数',
    taxRateError: '请输入 0–100，最多一位小数',
    roundingMode: '舍入模式',
    decimalPlaces: '小数位数',
    decimalPlacesInactive: '小数位数（F 模式下无效）',
    grouping: '千分位',
    placesSuffix: '位',
    indicatorSeparator: '  ｜  ',
    languageLabel: '语言',
    languageSystem: '跟随系统',
  );

  static const AppStrings traditional = AppStrings(
    appTitle: 'Jack計算機',
    settingsTitle: '設定',
    taxRateLabel: '稅率 (%)',
    taxRateHelper: '範圍 0–100，最多一位小數',
    taxRateError: '請輸入 0–100、最多一位小數',
    roundingMode: '捨入模式',
    decimalPlaces: '小數位',
    decimalPlacesInactive: '小數位（F 模式下無效）',
    grouping: '千分位',
    placesSuffix: '位',
    indicatorSeparator: '  ｜  ',
    languageLabel: '語言',
    languageSystem: '跟隨系統',
  );

  /// 沒有對照表的 locale 一律退回 English，所以呼叫端不必先檢查支援與否。
  static AppStrings of(Locale locale) => switch (resolveFrom([locale])) {
        AppLocale.english => english,
        AppLocale.simplified => simplified,
        AppLocale.traditional => traditional,
      };
}
