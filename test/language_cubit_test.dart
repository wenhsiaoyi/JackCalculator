import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/bloc/language_cubit.dart';
import 'package:jack_calculator/core/app_locale.dart';
import 'package:jack_calculator/data/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('初始是 null（跟隨系統），載入完成後讀回持久化值', () async {
    SharedPreferences.setMockInitialValues({SettingsRepository.languageKey: 'zh_Hans'});
    final cubit = LanguageCubit(const SettingsRepository());
    expect(cubit.state, isNull); // emit 是非同步的，建構後還沒讀到
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, AppLocale.simplified);
    await cubit.close();
  });

  test('setLanguage 會 emit 並寫入 prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final cubit = LanguageCubit(const SettingsRepository());
    await Future<void>.delayed(Duration.zero);

    cubit.setLanguage(AppLocale.traditional);
    expect(cubit.state, AppLocale.traditional);

    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsRepository.languageKey), 'zh_Hant');
    await cubit.close();
  });

  test('setLanguage(null) 寫回跟隨系統：key 被移除', () async {
    SharedPreferences.setMockInitialValues({SettingsRepository.languageKey: 'en'});
    final cubit = LanguageCubit(const SettingsRepository());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, AppLocale.english);

    cubit.setLanguage(null);
    await Future<void>.delayed(Duration.zero);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(SettingsRepository.languageKey), isFalse);
    await cubit.close();
  });

  test('prefs 裡是壞值時 state 退回 null 而不是崩潰', () async {
    SharedPreferences.setMockInitialValues({SettingsRepository.languageKey: 'klingon'});
    final cubit = LanguageCubit(const SettingsRepository());
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state, isNull);
    await cubit.close();
  });
}
