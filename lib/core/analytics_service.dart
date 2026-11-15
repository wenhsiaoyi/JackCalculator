import 'dart:io' show Platform;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart' show NavigatorObserver;

/// Analytics 唯一入口；僅 Android／iOS 生效（依賴政策例外，比照 AdService）。
class AnalyticsService {
  const AnalyticsService._();

  static bool get supported => Platform.isAndroid || Platform.isIOS;

  /// 新版 FlutterFire 不再靠原生自動初始化，Dart 側須明確 initializeApp。
  static Future<void> initialize() async {
    if (!supported) return;
    await Firebase.initializeApp();
  }

  static final List<NavigatorObserver> observers = supported
      ? [FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance)]
      : const [];

  static Future<void> logEvent(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    if (!supported) return;
    await FirebaseAnalytics.instance.logEvent(
      name: name,
      parameters: parameters,
    );
  }
}