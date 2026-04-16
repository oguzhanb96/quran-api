import '../entities/coordinates.dart';
import '../entities/prayer_calc_profile.dart';
import '../entities/prayer_time.dart';
import '../repositories/prayer_repository.dart';

class GetPrayerTimesUseCase {
  const GetPrayerTimesUseCase(this._repository);

  final PrayerRepository _repository;

  Future<List<PrayerTime>> call({
    required DateTime date,
    required Coordinates coordinates,
    required PrayerCalcProfile profile,
  }) {
    return _repository.getDailyPrayerTimes(
      date: date,
      coordinates: coordinates,
      profile: profile,
    );
  }
}
