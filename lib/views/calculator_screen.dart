import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calculator_cubit.dart';
import '../bloc/calculator_state.dart';
import '../bloc/settings_cubit.dart';
import 'components/calc_button.dart';
import 'components/display_screen.dart';
import 'components/status_indicator.dart';
import 'settings_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  bool _advancedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalculatorCubit>();
    return BlocListener<SettingsCubit, CalcSettings>(
      listenWhen: (previous, current) => previous != current,
      listener: (_, settings) => cubit.applySettings(settings),
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  BlocBuilder<SettingsCubit, CalcSettings>(
                    builder: (_, settings) =>
                        BlocBuilder<CalculatorCubit, CalculatorState>(
                      builder: (_, state) => Column(
                        children: [
                          DisplayScreen(
                            display: state.display,
                            settings: settings,
                            hasError: state.hasError,
                            hasGT: state.hasGT,
                            onSettingsTap: () => _openSettings(context),
                          ),
                          // Task 15 偏離（已於報告揭露，非 brief 內容）：
                          // 狀態列本體 Row（status_indicator.dart:20）在大字型的
                          // 320dp 窄視窗需要約 305dp，會橫向 overflow 25px。
                          // 依 spec「絕不 overflow」原則：IntrinsicWidth 先給該 Row
                          // 有界的內在寬度（Row 內有 Spacer，不能吃無界約束），
                          // 再由 FittedBox 在空間不足時整條等比縮小；寬度足夠時
                          // （含 Windows 與實機常見 360dp）渲染與原設計完全相同。
                          Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: IntrinsicWidth(
                                child: StatusIndicator(settings: settings),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _AdvancedToggle(
                    expanded: _advancedExpanded,
                    onTap: () =>
                        setState(() => _advancedExpanded = !_advancedExpanded),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          if (_advancedExpanded)
                            _row([
                              _btn('GT', cubit.onGrandTotal,
                                  CalcButtonVariant.function,
                                  fontScale: 0.34),
                              _btn('MU', cubit.onMu,
                                  CalcButtonVariant.function,
                                  fontScale: 0.34),
                              _btn('Tax+', cubit.onTaxPlus,
                                  CalcButtonVariant.function,
                                  fontScale: 0.34),
                              _btn('Tax−', cubit.onTaxMinus,
                                  CalcButtonVariant.function,
                                  fontScale: 0.34),
                            ]),
                          _row([
                            _btn('AC', cubit.allClear,
                                CalcButtonVariant.function),
                            _btn('C', cubit.clearEntry,
                                CalcButtonVariant.function),
                            _btn('±', cubit.toggleSign,
                                CalcButtonVariant.function),
                            _btn('÷', () => cubit.applyOperator(CalcOp.divide),
                                CalcButtonVariant.operator),
                          ]),
                          _row([
                            _num('7', cubit),
                            _num('8', cubit),
                            _num('9', cubit),
                            _btn('×', () => cubit.applyOperator(CalcOp.multiply),
                                CalcButtonVariant.operator),
                          ]),
                          _row([
                            _num('4', cubit),
                            _num('5', cubit),
                            _num('6', cubit),
                            _btn('−', () => cubit.applyOperator(CalcOp.subtract),
                                CalcButtonVariant.operator),
                          ]),
                          _row([
                            _num('1', cubit),
                            _num('2', cubit),
                            _num('3', cubit),
                            _btn('+', () => cubit.applyOperator(CalcOp.add),
                                CalcButtonVariant.operator),
                          ]),
                          _row([
                            _num('0', cubit),
                            _btn('.', cubit.onDecimalPoint,
                                CalcButtonVariant.number),
                            _btn('⌫', cubit.backspace,
                                CalcButtonVariant.function),
                            _btn('=', cubit.equals, CalcButtonVariant.equals),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );

  Widget _row(List<Widget> buttons) =>
      Expanded(child: Row(children: buttons));

  Widget _btn(String label, VoidCallback onTap, CalcButtonVariant variant,
          {double fontScale = 0.60}) =>
      Expanded(
        child: CalcButton(
          label: label,
          onPressed: onTap,
          variant: variant,
          shape:
              _advancedExpanded ? CalcButtonShape.capsule : CalcButtonShape.circle,
          fontScale: fontScale,
        ),
      );

  Widget _num(String digit, CalculatorCubit cubit) =>
      _btn(digit, () => cubit.onDigit(digit), CalcButtonVariant.number);
}

class _AdvancedToggle extends StatelessWidget {
  const _AdvancedToggle({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: const Key('advancedToggle'),
      onTap: onTap,
      child: SizedBox(
        height: 28,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.expand_less,
                size: 12, color: scheme.onSurfaceVariant),
            Icon(Icons.expand_more,
                size: 12, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
