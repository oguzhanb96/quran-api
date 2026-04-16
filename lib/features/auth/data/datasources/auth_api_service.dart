import 'package:dio/dio.dart';

/// Kendi backend sunucunuzdan kullanıcı ve kimlik doğrulama servisi
class AuthApiService {
  AuthApiService(this._dio);

  final Dio _dio;

  /// Kayıt ol
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'display_name': displayName,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  /// Giriş yap
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    return response.data ?? <String, dynamic>{};
  }

  /// Mevcut kullanıcı bilgisi
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/auth/me',
    );
    return response.data ?? <String, dynamic>{};
  }

  /// Kullanıcı ayarlarını getir
  Future<Map<String, dynamic>> getSettings() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/auth/settings',
    );
    return response.data ?? <String, dynamic>{};
  }

  /// Kullanıcı ayarlarını güncelle
  Future<Map<String, dynamic>> updateSettings({
    String? language,
    String? theme,
    int? quranFontSize,
    String? translationEdition,
    int? prayerMethod,
    bool? notificationEnabled,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/auth/settings',
      data: {
        'language': ?language,
        'theme': ?theme,
        'quran_font_size': ?quranFontSize,
        'translation_edition': ?translationEdition,
        'prayer_method': ?prayerMethod,
        'notification_enabled': ?notificationEnabled,
      },
    );
    return response.data ?? <String, dynamic>{};
  }
}
