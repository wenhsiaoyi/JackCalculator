import 'package:decimal/decimal.dart';

/// 捨入模式，對應 UI 標籤 F／CUT／UP／5/4。
enum RoundingMode {
  float(0),
  cut(1),
  up(2),
  halfUp(3);

  const RoundingMode(this.code);

  /// 持久化用的穩定整數碼（宣告順序若變動也不會毀掉舊設定）。
  final int code;

  static RoundingMode fromCode(int code) => RoundingMode.values
      .firstWhere((m) => m.code == code, orElse: () => RoundingMode.halfUp);
}

/// 計算機設定值物件。純 Dart，不 import Flutter。
class CalcSettings {
  CalcSettings({
    required this.taxRate,
    required this.rounding,
    required this.decimalPlaces,
    required this.grouping,
  });

  /// 稅率，存「百分之幾」的數值（5 = 5%）。範圍 0–100、最多一位小數。
  final Decimal taxRate;
  final RoundingMode rounding;

  /// 鎖定小數位：0／2／3／4。[rounding] 為 [RoundingMode.float] 時失效。
  final int decimalPlaces;
  final bool grouping;

  /// F 模式回傳 null —— engine 與 formatter 都讀這裡，不要各自判斷 F。
  int? get effectiveDecimalPlaces =>
      rounding == RoundingMode.float ? null : decimalPlaces;

  /// App 啟動預設值：5%／5-4／2 位／千分位 on。
  static final CalcSettings defaults = CalcSettings(
    taxRate: Decimal.fromInt(5),
    rounding: RoundingMode.halfUp,
    decimalPlaces: 2,
    grouping: true,
  );

  /// engine 自身的預設值：不捨入、不補零、不分位（＝Phase 1 語意）。
  static final CalcSettings raw = CalcSettings(
    taxRate: Decimal.fromInt(5),
    rounding: RoundingMode.float,
    decimalPlaces: 2,
    grouping: false,
  );

  CalcSettings copyWith({
    Decimal? taxRate,
    RoundingMode? rounding,
    int? decimalPlaces,
    bool? grouping,
  }) =>
      CalcSettings(
        taxRate: taxRate ?? this.taxRate,
        rounding: rounding ?? this.rounding,
        decimalPlaces: decimalPlaces ?? this.decimalPlaces,
        grouping: grouping ?? this.grouping,
      );

  @override
  bool operator ==(Object other) =>
      other is CalcSettings &&
      other.taxRate == taxRate &&
      other.rounding == rounding &&
      other.decimalPlaces == decimalPlaces &&
      other.grouping == grouping;

  @override
  int get hashCode => Object.hash(taxRate, rounding, decimalPlaces, grouping);
}
