import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/calculator_cubit.dart';
import 'bloc/settings_cubit.dart';
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
        BlocProvider(create: (_) => CalculatorCubit()),
      ],
      child: MaterialApp(
        title: 'Jack計算機',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const CalculatorScreen(),
      ),
    );
  }
}
