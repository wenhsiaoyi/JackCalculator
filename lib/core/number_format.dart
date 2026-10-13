import '../engine/calc_settings.dart';

/// 顯示層格式化：千分位（國際分位）與固定小數位補零。
///
/// 契約：輸入永遠是 engine 產出的 raw 字串（無逗號、無補零）。
/// `F` 模式不補零；輸入中的尾點（`12.`）保留且不補零。
String formatForDisplay(String raw, CalcSettings settings) {
  if (raw.isEmpty || raw == 'Error') return raw;

  var sign = '';
  var body = raw;
  if (body.startsWith('-')) {
    sign = '-';
    body = body.substring(1);
  }

  final editing = body.endsWith('.');
  if (editing) body = body.substring(0, body.length - 1);

  final parts = body.split('.');
  var intPart = parts[0];
  var fracPart = parts.length > 1 ? parts[1] : '';

  final places = settings.effectiveDecimalPlaces;
  if (places != null) {
    if (fracPart.length > places) {
      fracPart = fracPart.substring(0, places);
    } else if (!editing) {
      fracPart = fracPart.padRight(places, '0');
    }
  }

  if (settings.grouping) intPart = _group(intPart);

  final buffer = StringBuffer(sign)..write(intPart);
  if (fracPart.isNotEmpty) {
    buffer
      ..write('.')
      ..write(fracPart);
  }
  if (editing) buffer.write('.');
  return buffer.toString();
}

/// 每三位插一個逗號（國際分位）。
String _group(String digits) {
  if (digits.length <= 3) return digits;
  final chunks = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    chunks.insert(0, digits.substring(start, end));
  }
  return chunks.join(',');
}
