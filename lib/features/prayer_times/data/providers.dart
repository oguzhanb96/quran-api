import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/app_dio.dart';
import 'datasources/geocoding_service.dart';
import 'datasources/prayer_api_service.dart';
import 'repositories/prayer_repository_impl.dart';
import '../domain/repositories/prayer_repository.dart';

final prayerRepositoryProvider = Provider<PrayerRepository>((ref) {
  final dio = ref.read(dioProvider);
  final api = PrayerApiService(dio);
  return PrayerRepositoryImpl(api);
});

final geocodingServiceProvider = Provider<GeocodingService>((ref) {
  return GeocodingService(ref.read(dioProvider));
});
