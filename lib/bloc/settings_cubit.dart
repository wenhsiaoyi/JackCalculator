import 'dart:async';

import 'package:decimal/decimal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/settings_repository.dart';
import '../engine/calc_settings.dart';

/// 設定的載入與儲存。state 直接就是 [CalcSettings]。
class SettingsCubit extends Cubit<CalcSettings> {
  SettingsCubit(this._repo) : super(CalcSettings.defaults) {
    _load();
  }

  final SettingsRepository _repo;

  Future<void> _load() async {
    final loaded = await _repo.load();
    if (isClosed) return;
    emit(loaded);
  }

  void setTaxRate(Decimal rate) => _update(state.copyWith(taxRate: rate));

  void setRounding(RoundingMode mode) =>
      _update(state.copyWith(rounding: mode));

  void setDecimalPlaces(int places) =>
      _update(state.copyWith(decimalPlaces: places));

  void setGrouping(bool grouping) =>
      _update(state.copyWith(grouping: grouping));

  void _update(CalcSettings next) {
    emit(next);
    unawaited(_repo.save(next)); // fire-and-forget：UI 不等寫入
  }
}
