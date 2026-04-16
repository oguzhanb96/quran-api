import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';

class PrayerApiService {
  PrayerApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getPrayerCalendar({
    required double latitude,
    required double longitude,
    required String method,
    required String month,
    required String year,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${AppConfig.prayerApiBase}/calendar/$year/$month',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'method': method,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: <String, String>{
          'Accept': 'application/json',
        },
      ),
    );
    return response.data ?? <String, dynamic>{};
  }
}
