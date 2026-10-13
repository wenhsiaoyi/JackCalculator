import 'package:decimal/decimal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/calc_settings.dart';

/// `shared_preferences` 在整個 repo 內唯一的接觸點。
///
/// 只存 4 個純量；稅率以字串存放以保留 Decimal 精度。
class SettingsRepository {
  const SettingsRepository();

  static const String taxRateKey = 'tax_rate';
  static const String roundingKey = 'rounding_mode';
  static const String decimalPlacesKey = 'decimal_places';
  static const String groupingKey = 'grouping';

  static const List<int> allowedDecimalPlaces = <int>[0, 2, 3, 4];

  /// 讀不到、壞值、平台異常一律退回 [CalcSettings.defaults]，不拋。
  Future<CalcSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final taxRate = Decimal.tryParse(prefs.getString(taxRateKey) ?? '') ??
          CalcSettings.defaults.taxRate;
      return CalcSettings(
        taxRate: taxRate,
        rounding: RoundingMode.fromCode(
          prefs.getInt(roundingKey) ?? CalcSettings.defaults.rounding.code,
        ),
        decimalPlaces: _normalizePlaces(
          prefs.getInt(decimalPlacesKey) ?? CalcSettings.defaults.decimalPlaces,
        ),
        grouping: prefs.getBool(groupingKey) ?? CalcSettings.defaults.grouping,
      );
    } catch (_) {
      return CalcSettings.defaults;
    }
  }

  Future<void> save(CalcSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(taxRateKey, settings.taxRate.toString());
    await prefs.setInt(roundingKey, settings.rounding.code);
    await prefs.setInt(decimalPlacesKey, settings.decimalPlaces);
    await prefs.setBool(groupingKey, settings.grouping);
  }

  static int _normalizePlaces(int value) => allowedDecimalPlaces.contains(value)
      ? value
      : CalcSettings.defaults.decimalPlaces;
}
