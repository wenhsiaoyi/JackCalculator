import 'package:flutter/foundation.dart';

@immutable
class CalculatorState {
  final String display;
  final bool hasError;

  const CalculatorState({required this.display, required this.hasError});
}
