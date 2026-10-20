import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/settings_cubit.dart';
import '../core/app_strings.dart';
import '../engine/calc_settings.dart';

/// 稅率輸入驗證：只接受 0–100、最多一位小數；非法回 null。
Decimal? parseTaxRate(String raw) {
  var text = raw.trim();
  if (text.endsWith('.')) text = text.substring(0, text.length - 1);
  if (text.isEmpty) return null;
  final parsed = Decimal.tryParse(text);
  if (parsed == null) return null;
  if (parsed < Decimal.zero || parsed > Decimal.fromInt(100)) return null;
  if (parsed.scale > 1) return null;
  return parsed;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _taxController;
  bool _taxInvalid = false;

  @override
  void initState() {
    super.initState();
    _taxController = TextEditingController(
      text: context.read<SettingsCubit>().state.taxRate.toString(),
    );
  }

  @override
  void dispose() {
    _taxController.dispose();
    super.dispose();
  }

  void _onTaxChanged(SettingsCubit cubit, String value) {
    final parsed = parseTaxRate(value);
    // 存「原因」不存字串：切語系後舊語言的錯誤訊息不會留著（spec D9）。
    setState(() => _taxInvalid = parsed == null);
    if (parsed == null) return;
    cubit.setTaxRate(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final strings = AppStrings.of(Localizations.localeOf(context));
    return Scaffold(
      appBar: AppBar(title: Text(strings.settingsTitle)),
      body: BlocBuilder<SettingsCubit, CalcSettings>(
        builder: (context, settings) {
          final isFloat = settings.rounding == RoundingMode.float;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(strings.taxRateLabel),
              TextField(
                key: const Key('taxRateField'),
                controller: _taxController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) => _onTaxChanged(cubit, value),
                decoration: InputDecoration(
                  errorText: _taxInvalid ? strings.taxRateError : null,
                  helperText: strings.taxRateHelper,
                ),
              ),
              const SizedBox(height: 24),
              Text(strings.roundingMode),
              const SizedBox(height: 8),
              SegmentedButton<RoundingMode>(
                segments: const [
                  ButtonSegment(value: RoundingMode.float, label: Text('F')),
                  ButtonSegment(value: RoundingMode.cut, label: Text('CUT')),
                  ButtonSegment(value: RoundingMode.up, label: Text('UP')),
                  ButtonSegment(value: RoundingMode.halfUp, label: Text('5/4')),
                ],
                selected: {settings.rounding},
                showSelectedIcon: false,
                onSelectionChanged: (selection) =>
                    cubit.setRounding(selection.first),
              ),
              const SizedBox(height: 24),
              Text(isFloat
                  ? strings.decimalPlacesInactive
                  : strings.decimalPlaces),
              const SizedBox(height: 8),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('0')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                  ButtonSegment(value: 4, label: Text('4')),
                ],
                selected: {settings.decimalPlaces},
                showSelectedIcon: false,
                onSelectionChanged: isFloat
                    ? null
                    : (selection) => cubit.setDecimalPlaces(selection.first),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                key: const Key('groupingSwitch'),
                title: Text(strings.grouping),
                value: settings.grouping,
                onChanged: cubit.setGrouping,
              ),
            ],
          );
        },
      ),
    );
  }
}
