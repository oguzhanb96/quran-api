import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class KnowledgeLocalDataSource {
  KnowledgeLocalDataSource(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>?> fetchModulesRemote(String lang) async {
    try {
      final response = await _dio.get<dynamic>(
        '/knowledge/modules',
        queryParameters: {'lang': lang},
      );
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (data is Map<String, dynamic>) {
        final modules = data['modules'];
        if (modules is List) {
          return modules
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getItems(
    String moduleId, {
    required String lang,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/knowledge/$moduleId',
        queryParameters: {'lang': lang},
      );
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      if (data is Map<String, dynamic>) {
        final items = data['items'];
        if (items is List) {
          return items
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }
    } catch (_) {}

    final raw =
        await rootBundle.loadString('assets/content/$moduleId/tr.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
