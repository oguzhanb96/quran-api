import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../datasources/prayer_api_service.dart';
import '../../domain/entities/coordinates.dart';
import '../../domain/entities/prayer_calc_profile.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/repositories/prayer_repository.dart';
import '../../../../core/settings/app_preferences.dart';

class PrayerRepositoryImpl implements PrayerRepository {
  PrayerRepositoryImpl(this._api);

  final PrayerApiService _api;

  static const _aladhanToTurkish = {
    'Imsak': 'İmsak',
    'Fajr': 'İmsak',
    'Sunrise': 'Güneş',
    'Dhuhr': 'Öğle',
    'Asr': 'İkindi',
    'Maghrib': 'Akşam',
    'Isha': 'Yatsı',
  };

  @override
  Future<List<PrayerTime>> getDailyPrayerTimes({
    required DateTime date,
    required Coordinates coordinates,
    required PrayerCalcProfile profile,
  }) async {
    final month = date.month.toString();
    final year = date.year.toString();
    final day = date.day;

    try {
      final data = await _api.getPrayerCalendar(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
        method: '13',
        month: month,
        year: year,
      );
      final list = data['data'] as List<dynamic>?;
      if (list == null || list.isEmpty) return _fallback(date);

      await _saveCache(data, date.month, date.year);

      return _parseDay(list, day, date);
    } catch (_) {
      final cached = _fromCache(date);
      if (cached != null) return cached;
      return _fallback(date);
    }
  }

  List<PrayerTime> _parseDay(List<dynamic> list, int day, DateTime baseDate) {
    for (final item in list) {
      final greg = item['date']?['gregorian'] as Map<String, dynamic>?;
      if (greg == null) continue;
      final d = int.tryParse(greg['day']?.toString() ?? '') ?? 0;
      if (d != day) continue;

      final timings = item['timings'] as Map<String, dynamic>? ?? {};
      final order = ['Imsak', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
      final result = <PrayerTime>[];

      for (final key in order) {
        final raw = timings[key]?.toString() ?? '';
        final hm = raw.split(' ').first;
        final parts = hm.split(':');
        final hour = int.tryParse(parts.first) ?? 0;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final dt = DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
        final name = _aladhanToTurkish[key] ?? key;
        result.add(PrayerTime(name: name, time: dt));
      }
      return result;
    }
    return _fallback(baseDate);
  }

  List<PrayerTime> _fallback(DateTime date) {
    final n = DateTime(date.year, date.month, date.day);
    return [
      PrayerTime(name: 'İmsak', time: n.add(const Duration(hours: 5, minutes: 30))),
      PrayerTime(name: 'Güneş', time: n.add(const Duration(hours: 7, minutes: 0))),
      PrayerTime(name: 'Öğle', time: n.add(const Duration(hours: 13, minutes: 0))),
      PrayerTime(name: 'İkindi', time: n.add(const Duration(hours: 16, minutes: 30))),
      PrayerTime(name: 'Akşam', time: n.add(const Duration(hours: 19, minutes: 0))),
      PrayerTime(name: 'Yatsı', time: n.add(const Duration(hours: 20, minutes: 30))),
    ];
  }

  Future<void> _saveCache(
    Map<String, dynamic> data,
    int month,
    int year,
  ) async {
    final box = Hive.box('prayer_cache');
    await box.put(AppPreferences.prayerCacheKey, jsonEncode(data));
    await box.put(AppPreferences.prayerCacheMonthKey, month);
    await box.put(AppPreferences.prayerCacheYearKey, year);
  }

  List<PrayerTime>? _fromCache(DateTime date) {
    final box = Hive.box('prayer_cache');
    final month = box.get(AppPreferences.prayerCacheMonthKey);
    final year = box.get(AppPreferences.prayerCacheYearKey);
    if (month != date.month || year != date.year) return null;

    final jsonStr = box.get(AppPreferences.prayerCacheKey);
    if (jsonStr == null || jsonStr is! String) return null;

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final list = data['data'] as List<dynamic>?;
      if (list == null) return null;
      return _parseDay(list, date.day, date);
    } catch (_) {
      return null;
    }
  }
}
