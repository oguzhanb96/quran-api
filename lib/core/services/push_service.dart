import '../settings/app_preferences.dart';

class PushService {
  static final PushService _instance = PushService._internal();
  factory PushService() => _instance;
  PushService._internal();

  Future<void> init() async {}

  Future<String?> getToken() async {
    final existing = AppPreferences.box.get('device_push_token') as String?;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = 'hidaya-${DateTime.now().millisecondsSinceEpoch}';
    await AppPreferences.box.put('device_push_token', generated);
    return generated;
  }
}
