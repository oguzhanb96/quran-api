import 'package:dio/dio.dart';

import '../../features/dua_brotherhood/data/datasources/dua_brotherhood_api_service.dart';
import '../../features/dua_brotherhood/data/datasources/dua_queue_local_datasource.dart';

class DuaBrotherhoodSyncService {
  DuaBrotherhoodSyncService(this._dio);

  final Dio _dio;

  Future<void> flushQueue() async {
    final queue = DuaQueueLocalDataSource();
    final api = DuaBrotherhoodApiService(_dio);
    final pending = await queue.loadQueue();
    if (pending.isEmpty) return;
    final failed = <Map<String, dynamic>>[];
    for (final item in pending) {
      try {
        if (item['type'] == 'join') {
          await api.joinChain(item['chainId'] as String);
        } else if (item['type'] == 'contribution') {
          await api.contribute(
            item['chainId'] as String,
            (item['amount'] as num).toInt(),
          );
        }
      } catch (_) {
        failed.add(item);
      }
    }
    await queue.saveQueue(failed);
  }
}
