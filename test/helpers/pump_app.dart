import 'dart:ui' show Locale;

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
  await tester.pumpWidget(const JackCalculator());
  await tester.pumpAndSettle();
}
