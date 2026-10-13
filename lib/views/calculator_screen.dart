import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calculator_cubit.dart';
import '../bloc/calculator_state.dart';
import 'components/calc_button.dart';
import 'components/display_screen.dart';

class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CalculatorCubit>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<CalculatorCubit, CalculatorState>(
              builder: (_, s) =>
                  DisplayScreen(display: s.display, hasError: s.hasError),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _row([
                      _btn('AC', cubit.allClear, CalcButtonVariant.function),
                      _btn('C', cubit.clearEntry, CalcButtonVariant.function),
                      _btn('⌫', cubit.backspace, CalcButtonVariant.function),
                      _btn('÷', () => cubit.applyOperator(CalcOp.divide),
                          CalcButtonVariant.operator),
                    ]),
                    _row([
                      _num('7', cubit), _num('8', cubit), _num('9', cubit),
                      _btn('×', () => cubit.applyOperator(CalcOp.multiply),
                          CalcButtonVariant.operator),
                    ]),
                    _row([
                      _num('4', cubit), _num('5', cubit), _num('6', cubit),
                      _btn('−', () => cubit.applyOperator(CalcOp.subtract),
                          CalcButtonVariant.operator),
                    ]),
                    _row([
                      _num('1', cubit), _num('2', cubit), _num('3', cubit),
                      _btn('+', () => cubit.applyOperator(CalcOp.add),
                          CalcButtonVariant.operator),
                    ]),
                    _row([
                      _btn('±', cubit.toggleSign, CalcButtonVariant.function),
                      _num('0', cubit),
                      _btn('.', cubit.onDecimalPoint, CalcButtonVariant.number),
                      _btn('=', cubit.equals, CalcButtonVariant.equals),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<Widget> buttons) =>
      Expanded(child: Row(children: buttons));

  Widget _btn(String label, VoidCallback onTap, CalcButtonVariant variant) =>
      Expanded(
        child: CalcButton(label: label, onPressed: onTap, variant: variant),
      );

  Widget _num(String digit, CalculatorCubit cubit) =>
      _btn(digit, () => cubit.onDigit(digit), CalcButtonVariant.number);
}
