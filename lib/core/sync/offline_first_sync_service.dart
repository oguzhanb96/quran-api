import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../settings/app_preferences.dart';

class OfflineFirstSyncService {
  OfflineFirstSyncService(this._dio);
  final Dio _dio;

  Future<void> runIfNeeded() async {
    final isSynced = AppPreferences.box.get(AppPreferences.offlineSyncedKey, defaultValue: false) as bool;
    if (isSynced) {
      return;
    }
    await _downloadBootstrapContent();
    await AppPreferences.box.put(AppPreferences.offlineSyncedKey, true);
  }

  Future<void> forceSync() async {
    await _downloadBootstrapContent();
    await AppPreferences.box.put(AppPreferences.offlineSyncedKey, true);
  }

  Future<void> _downloadBootstrapContent() async {
    final quranCache = Hive.box('quran_cache');
    final prayerCache = Hive.box('prayer_cache');
    try {
      final manifest = await _dio.get<Map<String, dynamic>>('/sync/bootstrap');
      await quranCache.put('bootstrap_manifest', manifest.data ?? <String, dynamic>{});
      await prayerCache.put('bootstrap_at', DateTime.now().toIso8601String());
    } catch (_) {
      await prayerCache.put('bootstrap_at', DateTime.now().toIso8601String());
    }
  }
}
