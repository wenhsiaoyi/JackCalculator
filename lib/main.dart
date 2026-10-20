import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'bloc/calculator_cubit.dart';
import 'bloc/language_cubit.dart';
import 'bloc/settings_cubit.dart';
import 'core/app_locale.dart';
import 'core/app_strings.dart';
import 'core/theme.dart';
import 'data/settings_repository.dart';
import 'views/calculator_screen.dart';

void main() => runApp(const JackCalculator());

class JackCalculator extends StatelessWidget {
  const JackCalculator({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SettingsCubit(const SettingsRepository())),
        BlocProvider(create: (_) => LanguageCubit(const SettingsRepository())),
        BlocProvider(create: (_) => CalculatorCubit()),
      ],
      // 切語系要讓 MaterialApp 換 locale，所以整棵包在 BlocBuilder 裡。
      child: BlocBuilder<LanguageCubit, AppLocale?>(
        builder: (context, selected) {
          final effective = selected ??
              resolveFrom(WidgetsBinding.instance.platformDispatcher.locales);
          return MaterialApp(
            title: AppStrings.of(effective.locale).appTitle,
            locale: selected?.locale,
            supportedLocales: const [
              Locale('en'),
              Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
              Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
            ],
            localeListResolutionCallback: (locales, supportedLocales) =>
                resolveFrom(locales ?? const <Locale?>[]).locale,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            home: const CalculatorScreen(),
          );
        },
      ),
    );
  }
}
