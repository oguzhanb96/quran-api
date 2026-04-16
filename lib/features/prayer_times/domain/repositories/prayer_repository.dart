import '../entities/coordinates.dart';
import '../entities/prayer_calc_profile.dart';
import '../entities/prayer_time.dart';

abstract class PrayerRepository {
  Future<List<PrayerTime>> getDailyPrayerTimes({
    required DateTime date,
    required Coordinates coordinates,
    required PrayerCalcProfile profile,
  });
}
