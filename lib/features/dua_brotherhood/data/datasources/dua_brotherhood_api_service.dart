import 'package:dio/dio.dart';

class DuaBrotherhoodApiService {
  DuaBrotherhoodApiService(this._dio);

  final Dio _dio;

  Future<List<dynamic>> getChains() async {
    final response = await _dio.get('/dua-chains');
    final data = response.data;
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      return data['data'] as List<dynamic>? ?? <dynamic>[];
    }
    return <dynamic>[];
  }

  Future<Map<String, dynamic>?> getChain(String chainId) async {
    final response = await _dio.get('/dua-chains/$chainId');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return data;
    }
    return null;
  }

  Future<void> joinChain(String chainId) async {
    await _dio.post('/dua-chains/$chainId/join');
  }

  Future<void> contribute(String chainId, int amount) async {
    await _dio.post(
      '/dua-chains/$chainId/contributions',
      data: {'amount': amount},
    );
  }

  Future<void> registerPushToken(String token, String platform) async {
    await _dio.post(
      '/devices/push-token',
      data: {'token': token, 'platform': platform},
    );
  }
}
