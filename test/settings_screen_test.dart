import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/bloc/settings_cubit.dart';
import 'package:jack_calculator/data/settings_repository.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:jack_calculator/views/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 裸 `MaterialApp` 只自帶 `en` 的 delegate；harness 一旦把 `zh_Hant` 列進
/// `supportedLocales` 並解析成功，`AppBar` 就會因為找不到 `MaterialLocalizations`
/// 而斷言失敗，所以三個語系 harness 都要裝跟 `lib/main.dart` 同一組 delegate。
const _harnessDelegates = <LocalizationsDelegate<dynamic>>[
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

void main() {
  test('parseTaxRate 只接受 0–100、最多一位小數', () {
    expect(parseTaxRate('5'), Decimal.fromInt(5));
    expect(parseTaxRate(' 7.5 '), Decimal.parse('7.5'));
    expect(parseTaxRate('5.'), Decimal.fromInt(5));
    expect(parseTaxRate(''), isNull);
    expect(parseTaxRate('abc'), isNull);
    expect(parseTaxRate('-1'), isNull);
    expect(parseTaxRate('101'), isNull);
    expect(parseTaxRate('5.25'), isNull);
  });

  testWidgets('切換捨入模式與千分位會寫回 Cubit 並持久化', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('CUT'));
    await tester.pump();
    expect(cubit.state.rounding, RoundingMode.cut);

    await tester.tap(find.byKey(const Key('groupingSwitch')));
    await tester.pump();
    expect(cubit.state.grouping, false);

    // runAsync 包裝：bare pumpEventQueue 在此 binding 的 fake-async 下會死鎖。
    await tester.runAsync(pumpEventQueue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(SettingsRepository.roundingKey), RoundingMode.cut.code);
    expect(prefs.getBool(SettingsRepository.groupingKey), false);
  });

  testWidgets('合法稅率即時生效、非法稅率顯示錯誤且不寫入 state', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
          ),
          supportedLocales: const <Locale>[
            Locale('en'),
            Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          ],
          localizationsDelegates: _harnessDelegates,
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('taxRateField')), '7.5');
    await tester.pump();
    expect(cubit.state.taxRate, Decimal.parse('7.5'));

    await tester.enterText(find.byKey(const Key('taxRateField')), '150');
    await tester.pump();
    expect(cubit.state.taxRate, Decimal.parse('7.5')); // 未被寫入
    expect(find.text('請輸入 0–100、最多一位小數'), findsOneWidget);
  });

  testWidgets('非法稅率提示跟隨 locale：繁中', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale.fromSubtags(
            languageCode: 'zh',
            scriptCode: 'Hant',
          ),
          supportedLocales: const <Locale>[
            Locale('en'),
            Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          ],
          localizationsDelegates: _harnessDelegates,
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('taxRateField')), '150');
    await tester.pump();
    expect(find.text('請輸入 0–100、最多一位小數'), findsOneWidget);
  });

  testWidgets('非法稅率提示跟隨 locale：英文', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    addTearDown(cubit.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const <Locale>[
            Locale('en'),
            Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          ],
          localizationsDelegates: _harnessDelegates,
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('taxRateField')), '150');
    await tester.pump();
    expect(find.text('Enter 0–100 with at most 1 decimal'), findsOneWidget);
  });
}
