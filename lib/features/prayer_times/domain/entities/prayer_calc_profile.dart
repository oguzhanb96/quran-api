import 'prayer_method.dart';

class PrayerCalcProfile {
  const PrayerCalcProfile({
    required this.method,
    required this.madhab,
    this.fajrOffsetMinutes = 0,
    this.ishaOffsetMinutes = 0,
  });

  final PrayerMethod method;
  final String madhab;
  final int fajrOffsetMinutes;
  final int ishaOffsetMinutes;
}
