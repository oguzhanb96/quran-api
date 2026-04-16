import 'package:hive_flutter/hive_flutter.dart';

import '../config/api_base_url.dart';
import '../config/app_config.dart';

class AppPreferences {
  static const boxName = 'settings';
  static const onboardingDoneKey = 'onboarding_done';
  static const localeCodeKey = 'locale_code';
  static const quranTranslationLangKey = 'quran_translation_lang';
  static const duaTranslationLangKey = 'dua_translation_lang';
  static const selectedCityKey = 'selected_city';
  static const selectedCountryKey = 'selected_country';
  static const vpsBaseUrlKey = 'vps_base_url';
  static const offlineSyncedKey = 'offline_synced';
  static const analyticsConsentKey = 'analytics_consent';
  static const explicitConsentKey = 'explicit_consent';
  static const authTokenKey = 'auth_token';
  static const premiumEnabledKey = 'premium_enabled';
  static const themeModeKey = 'theme_mode';
  static const textScaleKey = 'text_scale';
  static const themeSeedKey = 'theme_seed';
  static const prayerKeys = [
    'imsak',
    'gunes',
    'ogle',
    'ikindi',
    'aksam',
    'yatsi',
  ];

  static const lastReadSurahKey = 'lastReadSurah';
  static const lastReadSurahNameKey = 'lastReadSurahName';
  static const lastReadAyahKey = 'lastReadAyah';

  static const dhikrStreakKey = 'dhikrStreak';
  static const dhikrMonthlyTotalKey = 'dhikrMonthlyTotal';
  static const dhikrLastDateKey = 'dhikrLastDate';

  static const readingGoalMinutesKey = 'readingGoalMinutes';
  static const readingProgressMinutesKey = 'readingProgressMinutes';
  static const readingLastDateKey = 'readingLastDate';

  static const prayerCacheKey = 'prayer_cache';
  static const prayerCacheMonthKey = 'prayer_cache_month';
  static const prayerCacheYearKey = 'prayer_cache_year';

  static const duaPlayCountKey = 'dua_play_count';
  static const totalAppMinutesKey = 'total_app_minutes';
  static const readingHistoryKey = 'reading_history_json';
  static const totalSurahsReadKey = 'total_surahs_read';
  static const downloadedSurahsKey = 'downloaded_surahs';
  static const savedSurahsKey = 'saved_surahs';
  static const _surahAudioUrlsPrefix = 'surah_audio_urls_';

  static Box get box => _box;
  static Box get _box => Hive.box(boxName);

  static void setLastRead(int surah, String surahName, int ayah) {
    _box.put(lastReadSurahKey, surah);
    _box.put(lastReadSurahNameKey, surahName);
    _box.put(lastReadAyahKey, ayah);
  }

  static Map<String, dynamic>? getLastRead() {
    final surah = _box.get(lastReadSurahKey);
    if (surah == null) return null;
    return {
      'surah': surah,
      'surahName': _box.get(lastReadSurahNameKey, defaultValue: ''),
      'ayah': _box.get(lastReadAyahKey, defaultValue: 1),
    };
  }

  static Future<void> incrementDhikrStats() async {
    final lastDateStr = _box.get(dhikrLastDateKey);
    final now = DateTime.now();

    int streak = _box.get(dhikrStreakKey, defaultValue: 0);
    int monthlyTotal = _box.get(dhikrMonthlyTotalKey, defaultValue: 0);

    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      if (lastDate.year == now.year &&
          lastDate.month == now.month &&
          lastDate.day == now.day) {
        monthlyTotal++;
      } else {
        final diff = DateTime(now.year, now.month, now.day)
            .difference(DateTime(lastDate.year, lastDate.month, lastDate.day))
            .inDays;
        if (diff == 1) {
          streak++;
        } else if (diff > 1) {
          streak = 1;
        }

        if (lastDate.year != now.year || lastDate.month != now.month) {
          monthlyTotal = 1;
        } else {
          monthlyTotal++;
        }
      }
    } else {
      streak = 1;
      monthlyTotal = 1;
    }

    await _box.put(dhikrStreakKey, streak);
    await _box.put(dhikrMonthlyTotalKey, monthlyTotal);
    await _box.put(dhikrLastDateKey, now.toIso8601String());
  }

  static int getDhikrStreak() => _box.get(dhikrStreakKey, defaultValue: 0);
  static int getDhikrMonthlyTotal() =>
      _box.get(dhikrMonthlyTotalKey, defaultValue: 0);

  static Future<void> incrementReadingProgress() async {
    final lastDateStr = _box.get(readingLastDateKey);
    final now = DateTime.now();
    double progress = _box.get(readingProgressMinutesKey, defaultValue: 0.0);

    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      if (lastDate.year != now.year ||
          lastDate.month != now.month ||
          lastDate.day != now.day) {
        progress = 0;
      }
    } else {
      progress = 0;
    }

    progress += 1.0;
    await _box.put(readingProgressMinutesKey, progress);
    await _box.put(readingLastDateKey, now.toIso8601String());
  }

  static double getReadingProgress() {
    final lastDateStr = _box.get(readingLastDateKey);
    final now = DateTime.now();
    if (lastDateStr != null) {
      final lastDate = DateTime.parse(lastDateStr);
      if (lastDate.year != now.year ||
          lastDate.month != now.month ||
          lastDate.day != now.day) {
        return 0.0;
      }
    }
    return _box.get(readingProgressMinutesKey, defaultValue: 0.0);
  }

  static double getReadingGoal() =>
      _box.get(readingGoalMinutesKey, defaultValue: 0.0);

  static Future<void> incrementDuaPlayCount() async {
    final current = _box.get(duaPlayCountKey, defaultValue: 0) as int;
    await _box.put(duaPlayCountKey, current + 1);
  }

  static int getDuaPlayCount() =>
      _box.get(duaPlayCountKey, defaultValue: 0) as int;

  static Future<void> incrementTotalAppMinutes() async {
    final current = _box.get(totalAppMinutesKey, defaultValue: 0) as int;
    await _box.put(totalAppMinutesKey, current + 1);
  }

  static int getTotalAppMinutes() =>
      _box.get(totalAppMinutesKey, defaultValue: 0) as int;

  static Set<int> getDownloadedSurahs() {
    final raw = _box.get(downloadedSurahsKey, defaultValue: <int>[]);
    if (raw is! List) return {};
    final out = <int>{};
    for (final e in raw) {
      if (e is int) {
        out.add(e);
      } else if (e is num) {
        out.add(e.toInt());
      }
    }
    return out;
  }

  static Future<void> addDownloadedSurah(int surahNumber) async {
    final set = getDownloadedSurahs()..add(surahNumber);
    await _box.put(downloadedSurahsKey, set.toList());
  }

  static Future<void> removeDownloadedSurah(int surahNumber) async {
    final set = getDownloadedSurahs()..remove(surahNumber);
    await _box.put(downloadedSurahsKey, set.toList());
  }

  static Set<int> getSavedSurahs() {
    final raw = _box.get(savedSurahsKey, defaultValue: <int>[]);
    if (raw is! List) return {};
    final out = <int>{};
    for (final e in raw) {
      if (e is int) {
        out.add(e);
      } else if (e is num) {
        out.add(e.toInt());
      }
    }
    return out;
  }

  static Future<void> toggleSavedSurah(int surahNumber) async {
    final set = getSavedSurahs();
    if (set.contains(surahNumber)) {
      set.remove(surahNumber);
    } else {
      set.add(surahNumber);
    }
    await _box.put(savedSurahsKey, set.toList());
  }

  static Future<void> saveSurahAudioUrls(int surahNumber, List<String> urls) async {
    await _box.put('$_surahAudioUrlsPrefix$surahNumber', urls);
  }

  static List<String> getSurahAudioUrls(int surahNumber) {
    final raw = _box.get('$_surahAudioUrlsPrefix$surahNumber', defaultValue: <String>[]);
    if (raw is List) return raw.whereType<String>().toList();
    return [];
  }

  static Future<void> clearSurahAudioUrls(int surahNumber) async {
    await _box.put('$_surahAudioUrlsPrefix$surahNumber', <String>[]);
  }

  static Future<void> incrementTotalSurahsRead() async {
    final current = _box.get(totalSurahsReadKey, defaultValue: 0) as int;
    await _box.put(totalSurahsReadKey, current + 1);
  }

  static int getTotalSurahsRead() =>
      _box.get(totalSurahsReadKey, defaultValue: 0) as int;

  static Future<void> recordDailyReading(double minutes) async {
    final today = DateTime.now();
    final key = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final raw = _box.get(readingHistoryKey, defaultValue: '{}') as String;
    final map = <String, double>{};
    try {
      final decoded = raw.split(',').where((e) => e.contains(':')).map((e) {
        final parts = e.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '').trim().split(':');
        if (parts.length == 2) return MapEntry(parts[0].trim(), double.tryParse(parts[1].trim()) ?? 0.0);
        return null;
      }).whereType<MapEntry<String, double>>();
      map.addEntries(decoded);
    } catch (_) {}
    map[key] = (map[key] ?? 0.0) + minutes;
    final entries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    if (entries.length > 30) entries.removeRange(0, entries.length - 30);
    final encoded = '{${entries.map((e) => '"${e.key}":${e.value}').join(',')}}';
    await _box.put(readingHistoryKey, encoded);
  }

  static Map<String, double> getReadingHistory() {
    final raw = _box.get(readingHistoryKey, defaultValue: '{}') as String;
    final map = <String, double>{};
    try {
      final decoded = raw.split(',').where((e) => e.contains(':')).map((e) {
        final parts = e.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '').trim().split(':');
        if (parts.length == 2) return MapEntry(parts[0].trim(), double.tryParse(parts[1].trim()) ?? 0.0);
        return null;
      }).whereType<MapEntry<String, double>>();
      map.addEntries(decoded);
    } catch (_) {}
    return map;
  }

  static Future<void> setReadingGoal(double goal) async {
    await _box.put(readingGoalMinutesKey, goal);
  }

  static Future<bool> isOnboardingDone() async {
    return _box.get(onboardingDoneKey, defaultValue: false);
  }

  static bool readOnboardingDoneSync() =>
      (_box.get(onboardingDoneKey, defaultValue: false) as bool?) ?? false;

  static String? readLocaleCodeSync() => _box.get(localeCodeKey) as String?;

  static Future<void> setOnboardingDone(bool value) async {
    await _box.put(onboardingDoneKey, value);
  }

  static Future<String?> getLocaleCode() async {
    return _box.get(localeCodeKey);
  }

  static Future<void> setLocaleCode(String code) async {
    await _box.put(localeCodeKey, code);
  }

  static String? getQuranTranslationLang() => _box.get(quranTranslationLangKey) as String?;

  static Future<void> setQuranTranslationLang(String lang) async {
    await _box.put(quranTranslationLangKey, lang);
  }

  static String? getDuaTranslationLang() => _box.get(duaTranslationLangKey) as String?;

  static Future<void> setDuaTranslationLang(String lang) async {
    await _box.put(duaTranslationLangKey, lang);
  }

  static Future<String?> getSelectedCity() async {
    return _box.get(selectedCityKey);
  }

  static Future<void> setSelectedCity(String city) async {
    await _box.put(selectedCityKey, city);
  }

  static Future<String?> getSelectedCountry() async {
    return _box.get(selectedCountryKey);
  }

  static Future<void> setSelectedCountry(String country) async {
    await _box.put(selectedCountryKey, country);
  }

  static String getVpsBaseUrl() {
    final raw = _box.get(vpsBaseUrlKey);
    if (raw is String && raw.trim().isNotEmpty) {
      return ApiBaseUrl.normalize(raw.trim());
    }
    return ApiBaseUrl.normalize(AppConfig.vpsBaseUrl);
  }

  static Future<void> setVpsBaseUrl(String value) async {
    final t = value.trim();
    if (t.isEmpty) {
      await _box.delete(vpsBaseUrlKey);
      return;
    }
    await _box.put(vpsBaseUrlKey, ApiBaseUrl.normalize(t));
  }

  static String? getAuthToken() => _box.get(authTokenKey) as String?;

  static Future<void> setAuthToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _box.delete(authTokenKey);
      return;
    }
    await _box.put(authTokenKey, token);
  }

  static bool isPremiumEnabled() =>
      _box.get(premiumEnabledKey, defaultValue: false) as bool;

  static Future<void> setPremiumEnabled(bool value) async {
    await _box.put(premiumEnabledKey, value);
  }

  static String getThemeMode() =>
      _box.get(themeModeKey, defaultValue: 'system') as String;

  static Future<void> setThemeMode(String value) async {
    await _box.put(themeModeKey, value);
  }

  static double getTextScale() =>
      (_box.get(textScaleKey, defaultValue: 1.0) as num).toDouble();

  static Future<void> setTextScale(double value) async {
    await _box.put(textScaleKey, value.clamp(0.85, 1.5));
  }

  static int getThemeSeed() =>
      (_box.get(themeSeedKey, defaultValue: 0xFF006D44) as num).toInt();

  static Future<void> setThemeSeed(int value) async {
    await _box.put(themeSeedKey, value);
  }

  static Future<Map<String, bool>> loadOnTimeToggles() async {
    final result = <String, bool>{};
    for (final key in prayerKeys) {
      result[key] = _box.get('notify_${key}_on_time', defaultValue: true);
    }
    return result;
  }

  static Future<Map<String, bool>> loadBeforeToggles() async {
    final result = <String, bool>{};
    for (final key in prayerKeys) {
      result[key] = _box.get('notify_${key}_before', defaultValue: true);
    }
    return result;
  }

  static Future<void> saveToggles({
    required Map<String, bool> onTime,
    required Map<String, bool> before,
  }) async {
    for (final key in prayerKeys) {
      await _box.put('notify_${key}_on_time', onTime[key] ?? true);
      await _box.put('notify_${key}_before', before[key] ?? true);
    }
  }
}
