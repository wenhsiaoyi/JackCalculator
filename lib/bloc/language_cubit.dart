import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/app_locale.dart';
import '../data/settings_repository.dart';

/// 語系的載入與儲存。state 是 `AppLocale?`，`null` 代表跟隨系統（spec D2）。
class LanguageCubit extends Cubit<AppLocale?> {
  LanguageCubit(this._repo) : super(null) {
    _load();
  }

  final SettingsRepository _repo;

  Future<void> _load() async {
    final loaded = await _repo.loadLanguage();
    if (isClosed) return;
    emit(loaded);
  }

  void setLanguage(AppLocale? locale) {
    emit(locale);
    unawaited(_repo.saveLanguage(locale)); // 不等寫入：UI 立刻反映，跟 SettingsCubit 一樣
  }
}
