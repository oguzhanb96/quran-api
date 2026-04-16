import 'dart:io';

import '../../../../core/services/notification_service.dart';
import '../../../../core/services/push_service.dart';
import '../../domain/entities/dua_chain.dart';
import '../../domain/repositories/dua_brotherhood_repository.dart';
import '../datasources/dua_brotherhood_api_service.dart';
import '../datasources/dua_queue_local_datasource.dart';

class DuaBrotherhoodRepositoryImpl implements DuaBrotherhoodRepository {
  DuaBrotherhoodRepositoryImpl(this._api, this._queue);

  final DuaBrotherhoodApiService _api;
  final DuaQueueLocalDataSource _queue;
  final Set<String> _completedNotified = <String>{};

  static const List<DuaChain> _fallbackChains = <DuaChain>[];

  DuaChain _map(dynamic raw) {
    final map = (raw as Map).cast<String, dynamic>();
    final current = (map['current_count'] as num?)?.toInt() ?? 0;
    final target = (map['target_count'] as num?)?.toInt() ?? 1000;
    return DuaChain(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Dua Zinciri',
      description: map['description']?.toString(),
      targetCount: target,
      currentCount: current,
      participants: (map['participants'] as num?)?.toInt() ?? 0,
      isCompleted: (map['is_completed'] as bool?) ?? (current >= target),
      category: map['category']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  @override
  Future<List<DuaChain>> getChains() async {
    final queue = await _queue.loadQueue();
    if (queue.isNotEmpty) {
      final failed = <Map<String, dynamic>>[];
      for (final item in queue) {
        try {
          if (item['type'] == 'join') {
            await _api.joinChain(item['chainId'] as String);
          } else if (item['type'] == 'contribution') {
            await _api.contribute(
              item['chainId'] as String,
              (item['amount'] as num).toInt(),
            );
          }
        } catch (_) {
          failed.add(item);
        }
      }
      await _queue.saveQueue(failed);
    }

    List<DuaChain> chains;
    try {
      final list = await _api.getChains();
      chains = list.map(_map).toList();
    } catch (_) {
      chains = _fallbackChains;
    }
    for (final chain in chains) {
      if (chain.isCompleted && !_completedNotified.contains(chain.id)) {
        _completedNotified.add(chain.id);
        await NotificationService().showNotification(
          id: chain.id.hashCode,
          title: 'Dua zinciri tamamlandı',
          body: '${chain.title} zinciri tamamlandı. Allah kabul etsin.',
        );
      }
    }
    return chains;
  }

  @override
  Future<DuaChain?> getChain(String chainId) async {
    try {
      final data = await _api.getChain(chainId);
      if (data == null) {
        for (final item in _fallbackChains) {
          if (item.id == chainId) {
            return item;
          }
        }
        return null;
      }
      return _map(data);
    } catch (_) {
      for (final item in _fallbackChains) {
        if (item.id == chainId) {
          return item;
        }
      }
      return null;
    }
  }

  @override
  Future<void> joinChain(String chainId) async {
    try {
      await _api.joinChain(chainId);
    } catch (_) {
      await _queue.enqueueJoin(chainId: chainId);
    }
  }

  @override
  Future<void> contribute(String chainId, int amount) async {
    try {
      await _api.contribute(chainId, amount);
    } catch (_) {
      await _queue.enqueueContribution(chainId: chainId, amount: amount);
    }
  }

  @override
  Future<void> registerPushToken() async {
    final token = await PushService().getToken();
    if (token == null || token.isEmpty) return;
    try {
      await _api.registerPushToken(
        token,
        Platform.isAndroid ? 'android' : 'ios',
      );
    } catch (_) {}
  }
}
