import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/main.dart';
import 'package:jack_calculator/views/components/calc_button.dart';
import 'package:jack_calculator/views/components/display_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

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
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

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
}
