import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:jack_calculator/bloc/calculator_cubit.dart';
import 'package:jack_calculator/bloc/language_cubit.dart';
import 'package:jack_calculator/bloc/settings_cubit.dart';
import 'package:jack_calculator/data/settings_repository.dart';
import 'package:jack_calculator/views/calculator_screen.dart';
import 'package:jack_calculator/views/components/banner_ad_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Banner 顯示時長鎖定 15 秒（需求：顯示 15 秒後消失）', () {
    expect(BannerAdView.visibleDuration, const Duration(seconds: 15));
  });

  testWidgets('桌面 host 上 BannerAdView 是 zero-size shrink、無 AdWidget',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BannerAdView())),
    );
    expect(find.byType(AdWidget), findsNothing);
    expect(tester.getSize(find.byType(BannerAdView)), Size.zero);
  });

  testWidgets('桌面 host 上 CalculatorScreen 不出現 AdWidget', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsCubit(const SettingsRepository());
    final language = LanguageCubit(const SettingsRepository());
    final calculator = CalculatorCubit();
    addTearDown(settings.close);
    addTearDown(language.close);
    addTearDown(calculator.close);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: settings),
          BlocProvider.value(value: language),
          BlocProvider.value(value: calculator),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: CalculatorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AdWidget), findsNothing);
  });
}