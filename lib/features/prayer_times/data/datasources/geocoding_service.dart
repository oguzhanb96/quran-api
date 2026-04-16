import 'package:dio/dio.dart';

import '../../../../core/config/app_config.dart';

class GeocodingService {
  GeocodingService(this._dio);

  final Dio _dio;

  Future<({double lat, double lon})?> geocode(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;

    final om = await _geocodeOpenMeteo(q);
    if (om != null) return om;

    return _geocodeNominatimFallback(q);
  }

  Future<({double lat, double lon})?> _geocodeOpenMeteo(String q) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        AppConfig.geocodingApiBase,
        queryParameters: <String, dynamic>{
          'name': q,
          'count': 1,
          'language': 'en',
          'format': 'json',
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 12),
          sendTimeout: const Duration(seconds: 12),
        ),
      );
      final results = response.data?['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final first = results.first as Map<String, dynamic>;
      final lat = (first['latitude'] as num?)?.toDouble();
      final lon = (first['longitude'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;
      return (lat: lat, lon: lon);
    } catch (_) {
      return null;
    }
  }

  Future<({double lat, double lon})?> _geocodeNominatimFallback(String q) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        AppConfig.nominatimBase,
        queryParameters: <String, dynamic>{
          'q': q,
          'format': 'json',
          'limit': 1,
          'addressdetails': 0,
        },
        options: Options(
          headers: <String, String>{
            'User-Agent': 'HidayaApp/1.0 (Flutter; contact: app@localhost.invalid)',
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 12),
        ),
      );
      final list = response.data;
      if (list == null || list.isEmpty) return null;
      final item = list.first as Map<String, dynamic>;
      final lat = (item['lat'] as num?)?.toDouble();
      final lon = (item['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;
      return (lat: lat, lon: lon);
    } catch (_) {
      return null;
    }
  }
}
