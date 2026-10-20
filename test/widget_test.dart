import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/core/app_locale.dart';
import 'package:jack_calculator/core/app_strings.dart';
import 'package:jack_calculator/data/settings_repository.dart';
import 'package:jack_calculator/main.dart';
import 'package:jack_calculator/views/components/calc_button.dart';
import 'package:jack_calculator/views/components/display_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/pump_app.dart';

void main() {
  testWidgets('computes 2 + 3 = 5', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    await tester.tap(find.text('2'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();

    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '5.00');
  });

  testWidgets('鎖 2 位時顯示補零：2 + 3 = → 5.00', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    await tester.tap(find.text('2'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();

    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '5.00');
  });

  testWidgets('indicator 顯示目前設定', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);

    expect(tester.widget<Text>(find.byKey(const Key('indTax'))).data, '5%');
    expect(tester.widget<Text>(find.byKey(const Key('indRounding'))).data, '5/4');
    expect(tester.widget<Text>(find.byKey(const Key('indPlaces'))).data, '2位');
    expect(find.byKey(const Key('indGrouping')), findsOneWidget);
  });

  testWidgets('F 模式不顯示位數格', (tester) async {
    SharedPreferences.setMockInitialValues({'rounding_mode': 0}); // float
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(const Key('indRounding'))).data, 'F');
    expect(find.byKey(const Key('indPlaces')), findsNothing);
  });

  testWidgets('預設收起：標準四欄盤存在、商用鍵不存在', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final label in ['AC', 'C', '⌫', '÷', '×', '−', '+', '±', '.', '=']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    for (final label in ['GT', 'MU', 'Tax+', 'Tax−']) {
      expect(find.text(label), findsNothing, reason: label);
    }
    expect(find.text('進階'), findsNothing);
    expect(find.text('收起'), findsNothing);
  });

  testWidgets('chevron 切換：展開出現商用鍵、再收起消失', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();
    for (final label in ['GT', 'MU', 'Tax+', 'Tax−']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('收起'), findsNothing);

    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();
    for (final label in ['GT', 'MU', 'Tax+', 'Tax−']) {
      expect(find.text(label), findsNothing, reason: label);
    }
    expect(find.text('進階'), findsNothing);
  });

  testWidgets('展開後 Tax+ 點擊後顯示含稅值', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final d in ['1', '0', '0', '0']) {
      await tester.tap(find.text(d));
    }
    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();
    await tester.tap(find.text('Tax+'));
    await tester.pump();

    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '1,050.00');
  });

  testWidgets('⚙ 導航到設定頁', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);

    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    expect(find.text('設定'), findsOneWidget);
    expect(find.text('捨入模式'), findsOneWidget);
  });

  testWidgets('改變設定會即時反映到顯示（切到 F 後不補零）', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('F'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    for (final d in ['2', '+', '3', '=']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();
    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '5');
  });

  testWidgets('窄高度不 overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 260);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('超位輸入照原樣顯示、按 = 後才捨入（final review 回歸）', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final d in ['1', '.', '2', '3', '5']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();
    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '1.235');

    for (final d in ['+', '0', '=']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();
    expect(tester.widget<Text>(display).data, '1.24');
  });

  testWidgets('展開後 GT 鍵把總計帶入顯示', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final d in ['2', '+', '3', '=']) {
      await tester.tap(find.text(d));
    }
    await tester.pump();

    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();

    expect(find.text('GT'), findsNWidgets(2)); // 徽章 ＋ 按鍵
    await tester.tap(find.widgetWithText(CalcButton, 'GT'));
    await tester.pump();

    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '5.00');
  });

  testWidgets('收起態鍵位結構：頂列 AC C ± ÷、底列 0 . ⌫ =', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    double dyOf(String label) =>
        tester.getCenter(find.widgetWithText(CalcButton, label)).dy;

    final topDy = dyOf('AC');
    for (final label in ['C', '±', '÷']) {
      expect((dyOf(label) - topDy).abs(), lessThan(1), reason: label);
    }
    expect(dyOf('7'), greaterThan(topDy));

    final bottomDy = dyOf('0');
    for (final label in ['.', '⌫', '=']) {
      expect((dyOf(label) - bottomDy).abs(), lessThan(1), reason: label);
    }
    expect((dyOf('±') - bottomDy).abs(), greaterThan(1));
  });

  testWidgets('形狀：收起態全圓形、展開全膠囊', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final btn in tester.widgetList<CalcButton>(find.byType(CalcButton))) {
      expect(btn.shape, CalcButtonShape.circle);
    }

    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();

    final expanded =
        tester.widgetList<CalcButton>(find.byType(CalcButton)).toList();
    expect(expanded.length, greaterThan(20));
    for (final btn in expanded) {
      expect(btn.shape, CalcButtonShape.capsule);
    }
  });

  testWidgets('窄窗展開態不 overflow', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 260);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('寬窗：內容置中且寬度上限 420', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(DisplayScreen));
    expect(size.width, 420);
    expect(tester.getCenter(find.byType(DisplayScreen)).dx, closeTo(640, 1));
  });

  testWidgets('即時預覽：65 × 4 過程中顯示 260.00，= 後消失', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('livePreview')), findsNothing);

    await tester.tap(find.text('6'));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('×'));
    await tester.pump();
    expect(find.byKey(const Key('livePreview')), findsNothing);

    await tester.tap(find.text('4'));
    await tester.pump();
    final preview = find.byKey(const Key('livePreview'));
    expect(preview, findsOneWidget);
    expect(tester.widget<Text>(preview).data, '260.00');

    await tester.tap(find.text('='));
    await tester.pump();
    expect(find.byKey(const Key('livePreview')), findsNothing);
    expect(tester.widget<Text>(find.byKey(const Key('displayValue'))).data,
        '260.00');
  });

  testWidgets('AC 後即時預覽消失', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    await tester.tap(find.text('6'));
    await tester.tap(find.text('5'));
    await tester.tap(find.text('×'));
    await tester.tap(find.text('4'));
    await tester.pump();
    expect(find.byKey(const Key('livePreview')), findsOneWidget);

    await tester.tap(find.text('AC'));
    await tester.pump();
    expect(find.byKey(const Key('livePreview')), findsNothing);
  });

  testWidgets('chevron 開關觸控高 ≥ 48dp', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    final height =
        tester.getSize(find.byKey(const Key('advancedToggle'))).height;
    expect(height, greaterThanOrEqualTo(48));
  });

  testWidgets('膠囊視覺高 ≥ 0.75×欄寬', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 100,
            height: 90,
            child: CalcButton(
              label: 'GT',
              onPressed: () {},
              variant: CalcButtonVariant.function,
              shape: CalcButtonShape.capsule,
            ),
          ),
        ),
      ),
    );

    final box = find.descendant(
      of: find.byType(CalcButton),
      matching: find.byType(DecoratedBox),
    );
    final decoration =
        tester.widget<DecoratedBox>(box).decoration as BoxDecoration;
    final size = tester.getSize(box);
    expect(decoration.borderRadius, isNotNull);
    expect(size.height, greaterThanOrEqualTo(0.75 * 92));
  });

  testWidgets('觸控區撐滿整格（含 4dp 鍵距，相鄰鍵零死區）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 100,
            height: 90,
            child: CalcButton(
              label: 'GT',
              onPressed: () {},
              variant: CalcButtonVariant.function,
              shape: CalcButtonShape.capsule,
            ),
          ),
        ),
      ),
    );

    final ink = find.descendant(
      of: find.byType(CalcButton),
      matching: find.byType(InkWell),
    );
    expect(tester.getSize(ink), const Size(100, 90));
  });

  testWidgets('手機寬展開態：面板鍵字級 ≥ 22dp', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(361, 794);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('advancedToggle')));
    await tester.pump();

    final gt = tester.widget<Text>(find.descendant(
      of: find.byType(CalcButton),
      matching: find.text('GT'),
    ));
    expect(gt.style!.fontSize, greaterThanOrEqualTo(22));
  });

  testWidgets('預設跟隨系統：zh-TW 裝置顯示繁中 indicator', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    expect(tester.widget<Text>(find.byKey(const Key('indPlaces'))).data, '2位');
  });

  testWidgets('預設跟隨系統：en 裝置也是同一套符號按鍵', (tester) async {
    await pumpApp(tester, locales: const [Locale('en')]);
    for (final label in ['AC', 'C', '⌫', '÷', '=']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(tester.widget<Text>(find.byKey(const Key('indPlaces'))).data, '2位');
  });

  testWidgets('未識別語系退回 english 渲染', (tester) async {
    await pumpApp(tester, locales: const [Locale('ja', 'JP')]);
    // AppStrings 目錄還沒接進視圖（Task 7），此處只驗解析不炸、按鍵仍在。
    expect(find.text('AC'), findsOneWidget);
  });

  testWidgets('語言選單四選項存在，預設選到跟隨系統', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    for (final label in ['跟隨系統', 'English', '繁體中文', '简体中文']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(tester.widget<SegmentedButton<AppLocale?>>(
      find.byKey(const Key('languagePicker'))).selected, {null});
  });

  testWidgets('選『简体中文』後停在設定頁並即時換字', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();

    // 停住 = MaterialApp 原地更新、Navigator state 保留（spec D6 的硬檢查）。
    expect(find.text('设置'), findsOneWidget);
    expect(find.byKey(const Key('languagePicker')), findsOneWidget);
    // 按鍵是符號詞，三語一致（spec D10）。鍵盤路由在被推起的設定路由之後，
    // 屬 offstage，所以要 skipOffstage: false 才找得到。
    expect(find.text('AC', skipOffstage: false), findsOneWidget);
  });

  testWidgets('語言選擇會持久化，重進 App 仍是簡體', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();
    await tester.runAsync(pumpEventQueue); // 等 fire-and-forget 的寫入落地

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsRepository.languageKey), 'zh_Hans');
  });

  testWidgets('手機寬 361dp：語言選單不 overflow', (tester) async {
    tester.view.physicalSize = const Size(361, 794);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('跟隨系統'), findsOneWidget);
  });

  // spec 測試策略 6＋驗收第 1 條：三語各自渲染、且互不殘留。
  testWidgets('三語設定頁：標題與標籤全從目錄來，別語的字不出現', (tester) async {
    final cases = [
      (const <Locale>[Locale('en')], AppStrings.english),
      (const <Locale>[Locale('zh', 'CN')], AppStrings.simplified),
      (const <Locale>[Locale('zh', 'TW')], AppStrings.traditional),
    ];
    final titles = [
      AppStrings.english.settingsTitle,
      AppStrings.simplified.settingsTitle,
      AppStrings.traditional.settingsTitle,
    ];
    for (final (systemLocales, strings) in cases) {
      await pumpApp(tester, locales: systemLocales);
      await tester.tap(find.byKey(const Key('openSettings')));
      await tester.pumpAndSettle();

      for (final label in [
        strings.taxRateLabel,
        strings.taxRateHelper,
        strings.roundingMode,
        strings.decimalPlaces, // 預設 5/4 不是 F，所以這裡不該是 Inactive 變體
        strings.grouping,
        strings.languageLabel,
      ]) {
        expect(find.text(label), findsOneWidget,
            reason: '${strings.appTitle} 少了「$label」');
      }
      for (final title in titles) {
        expect(find.text(title),
            title == strings.settingsTitle ? findsOneWidget : findsNothing,
            reason: 'AppBar 標題不該同時出現兩種語系');
      }
    }
  });

  // spec D6 那句「換語系不會被彈出設定頁」在這裡被證明；紅了請停在原地回報。
  testWidgets('選「跟隨系統」會移除偏好並回到系統語系', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('简体中文'));
    await tester.pumpAndSettle();
    expect(find.text('设置'), findsOneWidget);

    // 切到簡體後，「跟隨系統」這個選項自己也被翻譯成「跟随系统」，
    // 所以要點的是簡體字形——它是四個選項裡唯一會被翻的那個（spec D8）。
    await tester.tap(find.text('跟随系统'));
    await tester.pumpAndSettle();
    expect(find.text('設定'), findsOneWidget); // 回到 zh-TW 系統的繁中

    await tester.runAsync(pumpEventQueue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(SettingsRepository.languageKey), isFalse);
  });

  // spec 測試策略 8：flutter_localizations 對 zh_Hans／zh_Hant 真的有感應。
  testWidgets('delegates 冒煙測試：三語下長按稅率欄都不拋 Localizations assert',
      (tester) async {
    for (final systemLocales in [
      const <Locale>[Locale('en')],
      const <Locale>[Locale('zh', 'CN')],
      const <Locale>[Locale('zh', 'TW')],
    ]) {
      await pumpApp(tester, locales: systemLocales);
      await tester.tap(find.byKey(const Key('openSettings')));
      await tester.pumpAndSettle();
      await tester.longPress(find.byKey(const Key('taxRateField')));
      await tester.pumpAndSettle();
      // 缺 delegate 時 debug mode 會在這裡拋 assert；有異常 takeException 才會吞得到。
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('換語系後舊語言的稅率錯誤訊息不殘留', (tester) async {
    await pumpApp(tester, locales: const [Locale('zh', 'TW')]);
    await tester.tap(find.byKey(const Key('openSettings')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('taxRateField')), '150');
    await tester.pump();
    expect(find.text(AppStrings.traditional.taxRateError), findsOneWidget);
    expect(find.text(AppStrings.simplified.taxRateError), findsNothing);

    await tester.tap(find.text(AppStrings.languageSimplified));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.simplified.taxRateError), findsOneWidget);
    expect(find.text(AppStrings.traditional.taxRateError), findsNothing);
  });
}
