import 'package:flutter/widgets.dart';

import '../../../../core/localization/app_language.dart';

const Map<String, String> _storageNameToAppTextKey = {
  'İmsak': 'prayer_imsak',
  'Güneş': 'prayer_gunes',
  'Öğle': 'prayer_ogle',
  'İkindi': 'prayer_ikindi',
  'Akşam': 'prayer_aksam',
  'Yatsı': 'prayer_yatsi',
};

String localizedPrayerName(BuildContext context, String storageName) {
  final key = _storageNameToAppTextKey[storageName];
  if (key != null) return AppText.of(context, key);
  return storageName;
}

/// Safe short label for narrow prayer rows (grapheme-based, not UTF-16 code units).
String localizedPrayerShortLabel(BuildContext context, String storageName) {
  final full = localizedPrayerName(context, storageName);
  final chars = full.characters;
  if (chars.length <= 4) return full;
  return '${chars.take(3).string}…';
}
