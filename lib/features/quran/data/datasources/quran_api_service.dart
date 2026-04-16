import 'package:dio/dio.dart';

class QuranApiService {
  QuranApiService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getSurahList() async {
    final response = await _dio.get<Map<String, dynamic>>('/surahs');
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getSurah({required int surahNumber}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/surah/$surahNumber',
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> search({
    required String query,
    required String translationEdition,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {'query': query, 'lang': translationEdition},
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getFavorites() async {
    final response = await _dio.get<Map<String, dynamic>>('/favorites');
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> addFavorite({int? surahId, int? verseId}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/favorites',
      data: {'surah_number': surahId, 'ayah_number': verseId},
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> getBookmarks() async {
    final response = await _dio.get<Map<String, dynamic>>('/history');
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> addBookmark({
    required int surahId,
    required int verseNumber,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/history',
      data: {'surah_number': surahId, 'ayah_number': verseNumber},
    );
    return response.data ?? <String, dynamic>{};
  }
}
