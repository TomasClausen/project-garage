import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class UpdateNotifier {
  bool get supported;
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<void> showUpdate(String version);
  Future<void> setTapHandler(VoidCallback handler);
}

class UpdateNotificationService implements UpdateNotifier {
  static const _channel = MethodChannel(
    'com.projectgarage.app/update_notifications',
  );

  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> hasPermission() async {
    if (!supported) return false;
    return await _channel.invokeMethod<bool>('hasPermission') ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (!supported) return false;
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  @override
  Future<void> showUpdate(String version) async {
    if (!supported) return;
    await _channel.invokeMethod<void>('showUpdate', {'version': version});
  }

  @override
  Future<void> setTapHandler(VoidCallback handler) async {
    if (!supported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'notificationTap') handler();
    });
    final initialTap =
        await _channel.invokeMethod<bool>('consumeInitialNotificationTap') ??
        false;
    if (initialTap) handler();
  }
}
