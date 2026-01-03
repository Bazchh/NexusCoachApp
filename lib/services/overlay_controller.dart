import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class OverlayController {
  static const MethodChannel _channel = MethodChannel('nexuscoach/overlay');

  static Future<bool> canDrawOverlays() async {
    try {
      final allowed = await _channel.invokeMethod<bool>('canDrawOverlays');
      return allowed ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestPermission');
    } catch (_) {}
  }

  static Future<bool> start() async {
    try {
      return (await _channel.invokeMethod<bool>('start')) ?? false;
    } catch (error) {
      debugPrint('Overlay start failed: $error');
      return false;
    }
  }

  static Future<bool> stop() async {
    try {
      return (await _channel.invokeMethod<bool>('stop')) ?? false;
    } catch (error) {
      debugPrint('Overlay stop failed: $error');
      return false;
    }
  }
}
