import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/data/settings_repository.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SettingsRepository repo;

  setUp(() {
    repo = const SettingsRepository();
  });

  test('空資料 → 回 defaults', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await repo.load(), CalcSettings.defaults);
  });

  test('save → load round-trip', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = CalcSettings(
      taxRate: Decimal.parse('8.5'),
      rounding: RoundingMode.up,
      decimalPlaces: 3,
      grouping: false,
    );
    await repo.save(settings);
    expect(await repo.load(), settings);
  });

  test('壞稅率退回預設、不拋', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.taxRateKey: 'oops',
    });
    expect((await repo.load()).taxRate, CalcSettings.defaults.taxRate);
  });

  test('非法小數位（1）退回 2', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.decimalPlacesKey: 1,
    });
    expect((await repo.load()).decimalPlaces, 2);
  });

  test('未知捨入碼退回 5/4', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.roundingKey: 42,
    });
    expect((await repo.load()).rounding, RoundingMode.halfUp);
  });

  test('只寫 4 個純量鍵', () async {
    SharedPreferences.setMockInitialValues({});
    await repo.save(CalcSettings.defaults);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().length, 4);
  });
}
