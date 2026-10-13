import 'package:flutter/foundation.dart';

@immutable
class CalculatorState {
  const CalculatorState({
    required this.display,
    required this.hasError,
    this.hasGT = false,
  });

  /// raw 字串：不含逗號、不補零。格式化只發生在 DisplayScreen。
  final String display;
  final bool hasError;
  final bool hasGT;

  @override
  bool operator ==(Object other) =>
      other is CalculatorState &&
      other.display == display &&
      other.hasError == hasError &&
      other.hasGT == hasGT;

  @override
  int get hashCode => Object.hash(display, hasError, hasGT);
}
