import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/bloc/settings_cubit.dart';
import 'package:jack_calculator/data/settings_repository.dart';
import 'package:jack_calculator/engine/calc_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('初始 state 是 defaults（不等載入）', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    expect(cubit.state, CalcSettings.defaults);
    await cubit.close();
  });

  test('載入完成後以實際設定取代初始值', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.roundingKey: RoundingMode.cut.code,
      SettingsRepository.decimalPlacesKey: 4,
      SettingsRepository.groupingKey: false,
    });
    final cubit = SettingsCubit(const SettingsRepository());
    // bloc 的 stream 是 broadcast 且「不 replay」：訂閱發生在 load 完成之前，
    // 所以這裡收到的第一個事件就是載入完成的那次 emit（用 `.first` 即可）。
    final loaded = await cubit.stream.first;
    expect(loaded.rounding, RoundingMode.cut);
    expect(loaded.decimalPlaces, 4);
    expect(loaded.grouping, false);
    await cubit.close();
  });

  test('setter 更新 state 並寫入 repo', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = SettingsCubit(const SettingsRepository());
    cubit.setTaxRate(Decimal.parse('12.5'));
    expect(cubit.state.taxRate, Decimal.parse('12.5'));
    cubit.setRounding(RoundingMode.up);
    cubit.setDecimalPlaces(0);
    cubit.setGrouping(false);
    await pumpEventQueue();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsRepository.taxRateKey), '12.5');
    expect(prefs.getInt(SettingsRepository.roundingKey),
        RoundingMode.up.code);
    expect(prefs.getInt(SettingsRepository.decimalPlacesKey), 0);
    expect(prefs.getBool(SettingsRepository.groupingKey), false);
    await cubit.close();
  });

  test('close 之後載入完成不會 emit', () async {
    SharedPreferences.setMockInitialValues({
      SettingsRepository.groupingKey: false,
    });
    final cubit = SettingsCubit(const SettingsRepository());
    await cubit.close();
    await pumpEventQueue();
    // 若 isClosed 守衛失效，這裡會拋 StateError 讓測試失敗。
  });
}
