import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';

import 'app/app.dart';
import 'core/config/api_base_url.dart';
import 'core/config/app_config.dart';
import 'core/services/notification_service.dart';
import 'core/services/push_service.dart';
import 'core/settings/app_preferences.dart';
import 'core/sync/dua_brotherhood_sync_service.dart';
import 'core/sync/offline_first_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    if (Platform.isAndroid) {
      await FlutterDisplayMode.setHighRefreshRate();
    }
  } catch (_) {}

  if (AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  await initializeDateFormatting();

  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('prayer_cache');
  await Hive.openBox('quran_cache');
  await Hive.openBox('dua_brotherhood_queue');

  await NotificationService().init();
  await PushService().init();
  final syncDio = Dio(
    BaseOptions(baseUrl: ApiBaseUrl.normalize(AppPreferences.getVpsBaseUrl())),
  );
  await OfflineFirstSyncService(syncDio).runIfNeeded();
  await DuaBrotherhoodSyncService(syncDio).flushQueue();

  runApp(ProviderScope(child: const QuranCompanionApp()));
}
