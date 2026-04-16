import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../domain/entities/dua_chain.dart';

final duaChainsProvider =
    AsyncNotifierProvider<DuaBrotherhoodViewModel, List<DuaChain>>(
      DuaBrotherhoodViewModel.new,
    );

class DuaBrotherhoodViewModel extends AsyncNotifier<List<DuaChain>> {
  @override
  Future<List<DuaChain>> build() async {
    final repo = ref.read(duaBrotherhoodRepositoryProvider);
    await repo.registerPushToken();
    return repo.getChains();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(duaBrotherhoodRepositoryProvider).getChains();
    });
  }

  Future<void> joinAndContribute(String chainId, int amount) async {
    // Optimistic update — UI'ı hemen güncelle
    final current = state.value;
    if (current != null) {
      final updated = current.map((chain) {
        if (chain.id != chainId) return chain;
        final newCount = chain.currentCount + amount;
        return DuaChain(
          id: chain.id,
          title: chain.title,
          description: chain.description,
          targetCount: chain.targetCount,
          currentCount: newCount,
          participants: chain.participants,
          isCompleted: newCount >= chain.targetCount,
          category: chain.category,
          createdAt: chain.createdAt,
        );
      }).toList();
      state = AsyncData(updated);
    }

    // Arka planda API'ye gönder
    final repo = ref.read(duaBrotherhoodRepositoryProvider);
    try {
      await repo.joinChain(chainId);
      await repo.contribute(chainId, amount);
    } catch (_) {
      // Hata olsa da optimistic state kalır, queue'ya eklendi
    }
  }
}
