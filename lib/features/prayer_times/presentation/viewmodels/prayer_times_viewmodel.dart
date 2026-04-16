import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../../../core/settings/app_preferences.dart';
import '../../data/providers.dart';
import '../../domain/entities/coordinates.dart';
import '../../domain/entities/prayer_calc_profile.dart';
import '../../domain/entities/prayer_method.dart';
import '../../domain/entities/prayer_time.dart';
import '../../domain/usecases/get_prayer_times_usecase.dart';

final prayerTimesProvider =
    AsyncNotifierProvider<PrayerTimesViewModel, PrayerTimesState>(
      PrayerTimesViewModel.new,
    );

class PrayerTimesState {
  const PrayerTimesState({
    required this.times,
    required this.coordinates,
    required this.locationLabel,
  });

  final List<PrayerTime> times;
  final Coordinates coordinates;
  final String locationLabel;
}

class PrayerTimesViewModel extends AsyncNotifier<PrayerTimesState> {
  static const _defaultCoordinates = Coordinates(
    latitude: 41.0082,
    longitude: 28.9784,
  );

  Coordinates _coordinates = _defaultCoordinates;
  String _locationLabel = 'Istanbul';
  Timer? _autoRefreshTimer;

  @override
  Future<PrayerTimesState> build() async {
    _autoRefreshTimer ??= Timer.periodic(const Duration(minutes: 15), (_) {
      refresh();
    });
    ref.onDispose(() {
      _autoRefreshTimer?.cancel();
      _autoRefreshTimer = null;
    });
    final applied = await _applySavedCityIfAny();
    if (!applied) {
      _coordinates = _defaultCoordinates;
      _locationLabel = 'Istanbul';
    }
    return _fetch();
  }

  Future<bool> _applySavedCityIfAny() async {
    final savedCity = await AppPreferences.getSelectedCity();
    if (savedCity == null || savedCity.trim().isEmpty) {
      return false;
    }
    final coords = await _geocode(savedCity.trim());
    if (coords == null) {
      return false;
    }
    _coordinates = Coordinates(latitude: coords.lat, longitude: coords.lon);
    _locationLabel = savedCity.trim();
    return true;
  }

  Future<({double lat, double lon})?> _geocode(String query) async {
    return ref.read(geocodingServiceProvider).geocode(query);
  }

  Future<PrayerTimesState> _fetch() async {
    final repo = ref.read(prayerRepositoryProvider);
    final useCase = GetPrayerTimesUseCase(repo);
    final times = await useCase(
      date: DateTime.now(),
      coordinates: _coordinates,
      profile: const PrayerCalcProfile(
        method: PrayerMethod.mwl,
        madhab: 'hanafi',
      ),
    );
    return PrayerTimesState(
      times: times,
      coordinates: _coordinates,
      locationLabel: _locationLabel,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final savedCity = await AppPreferences.getSelectedCity();
      if (savedCity != null && savedCity.trim().isNotEmpty) {
        final coords = await _geocode(savedCity.trim());
        if (coords != null) {
          _coordinates = Coordinates(latitude: coords.lat, longitude: coords.lon);
          _locationLabel = savedCity.trim();
        } else {
          _coordinates = _defaultCoordinates;
          _locationLabel = 'Istanbul';
        }
      } else {
        _coordinates = _defaultCoordinates;
        _locationLabel = 'Istanbul';
      }
      return _fetch();
    });
  }

  Future<bool> setManualCity(String cityName) async {
    final query = cityName.trim();
    if (query.isEmpty) return false;

    final coords = await _geocode(query);
    if (coords == null) return false;

    await AppPreferences.setSelectedCity(query);

    _coordinates = Coordinates(latitude: coords.lat, longitude: coords.lon);
    _locationLabel = query;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
    return true;
  }
}
