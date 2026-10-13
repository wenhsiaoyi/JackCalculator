import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jack_calculator/main.dart';

void main() {
  testWidgets('computes 2 + 3 = 5', (WidgetTester tester) async {
    await tester.pumpWidget(const JackCalculator());

    await tester.tap(find.text('2'));
    await tester.tap(find.text('+'));
    await tester.tap(find.text('3'));
    await tester.tap(find.text('='));
    await tester.pump();

    final display = find.byKey(const Key('displayValue'));
    expect(tester.widget<Text>(display).data, '5');
  });
}
