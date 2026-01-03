import 'package:flutter/services.dart';

class MinimapReminderController {
  static const MethodChannel _channel = MethodChannel('nexuscoach/minimap');

  static Future<void> start({
    required int intervalSeconds,
    required String message,
    required String locale,
  }) async {
    try {
      await _channel.invokeMethod('start', {
        'intervalSeconds': intervalSeconds,
        'message': message,
        'locale': locale,
      });
    } catch (_) {
      // Ignore if channel is unavailable (e.g., non-Android platforms).
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {
      // Ignore if channel is unavailable.
    }
  }
}
