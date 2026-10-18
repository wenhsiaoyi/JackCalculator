import 'package:flutter/foundation.dart';

@immutable
class CalculatorState {
  const CalculatorState({
    required this.display,
    required this.hasError,
    this.hasGT = false,
    this.livePreview,
  });

  /// raw 字串：不含逗號、不補零。格式化只發生在 DisplayScreen。
  final String display;
  final bool hasError;
  final bool hasGT;

  /// 即時運算預覽（raw 字串），null＝不顯示。
  final String? livePreview;

  @override
  bool operator ==(Object other) =>
      other is CalculatorState &&
      other.display == display &&
      other.hasError == hasError &&
      other.hasGT == hasGT &&
      other.livePreview == livePreview;

  @override
  int get hashCode => Object.hash(display, hasError, hasGT, livePreview);
}
