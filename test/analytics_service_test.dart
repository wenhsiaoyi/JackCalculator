import 'package:flutter_test/flutter_test.dart';
import 'package:jack_calculator/core/analytics_service.dart';

void main() {
  test('非行動平台：observers 為空、logEvent no-op 不拋', () async {
    if (AnalyticsService.supported) return;
    expect(AnalyticsService.observers, isEmpty);
    await AnalyticsService.initialize();
    await AnalyticsService.logEvent('probe', {'k': 'v'});
  });
}