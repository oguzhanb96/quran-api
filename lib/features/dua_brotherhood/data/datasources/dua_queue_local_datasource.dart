import 'package:hive_flutter/hive_flutter.dart';

class DuaQueueLocalDataSource {
  static const _boxName = 'dua_brotherhood_queue';

  Future<void> enqueueContribution({
    required String chainId,
    required int amount,
  }) async {
    final box = Hive.box(_boxName);
    final existing =
        (box.get('queue', defaultValue: <dynamic>[]) as List<dynamic>).toList();
    existing.add({
      'chainId': chainId,
      'amount': amount,
      'type': 'contribution',
    });
    await box.put('queue', existing);
  }

  Future<void> enqueueJoin({required String chainId}) async {
    final box = Hive.box(_boxName);
    final existing =
        (box.get('queue', defaultValue: <dynamic>[]) as List<dynamic>).toList();
    existing.add({'chainId': chainId, 'type': 'join'});
    await box.put('queue', existing);
  }

  Future<List<Map<String, dynamic>>> loadQueue() async {
    final box = Hive.box(_boxName);
    final raw = (box.get('queue', defaultValue: <dynamic>[]) as List<dynamic>);
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<void> clearQueue() async {
    final box = Hive.box(_boxName);
    await box.put('queue', <dynamic>[]);
  }

  Future<void> saveQueue(List<Map<String, dynamic>> queue) async {
    final box = Hive.box(_boxName);
    await box.put('queue', queue);
  }
}
