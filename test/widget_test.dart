import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/main.dart';
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

  testWidgets('5×5 鍵盤：新鍵存在', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final label in ['GT', 'MU', 'Tax+', 'Tax−', 'AC', 'C', '⌫', '±', '=']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('Tax+ 點擊後顯示含稅值', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const JackCalculator());
    await tester.pumpAndSettle();

    for (final d in ['1', '0', '0', '0']) {
      await tester.tap(find.text(d));
    }
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
}
