import 'package:flutter_bloc/flutter_bloc.dart';

import '../engine/calculator_engine.dart';
import 'calculator_state.dart';

// 讓 UI 只經由此橋接層取得 CalcOp，維持「Cubit 是 UI↔engine 唯一橋」的邊界。
export '../engine/calculator_engine.dart' show CalcOp;

class CalculatorCubit extends Cubit<CalculatorState> {
  final CalculatorEngine _engine = CalculatorEngine();

  CalculatorCubit()
      : super(const CalculatorState(display: '0', hasError: false));

  void _sync() =>
      emit(CalculatorState(display: _engine.display, hasError: _engine.hasError));

  void onDigit(String d) {
    _engine.inputDigit(d);
    _sync();
  }

  void onDecimalPoint() {
    _engine.inputDecimalPoint();
    _sync();
  }

  void applyOperator(CalcOp op) {
    _engine.applyOperator(op);
    _sync();
  }

  void equals() {
    _engine.equals();
    _sync();
  }

  void allClear() {
    _engine.allClear();
    _sync();
  }

  void clearEntry() {
    _engine.clearEntry();
    _sync();
  }

  void backspace() {
    _engine.backspace();
    _sync();
  }

  void toggleSign() {
    _engine.toggleSign();
    _sync();
  }
}
