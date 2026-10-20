import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 以指定「系統語系」起 App。走真實解析路徑（spec 測試策略 1）：
/// 塞 `TestPlatformDispatcher.localesTestValue`，而不是在 App 裡留 test-only 參數。
/// 不傳 `locales` 時保持 flutter_test 預設（en）。
Future<void> pumpApp(
  WidgetTester tester, {
  List<Locale> locales = const <Locale>[],
}) async {
  SharedPreferences.setMockInitialValues({});
  if (locales.isNotEmpty) {
    tester.platformDispatcher.localesTestValue = locales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  }
  // 同測試內重複呼叫要重新冷開機：const 根 Widget 相同會被框架短路、不重建樹。
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(const JackCalculator());
  await tester.pumpAndSettle();
}
