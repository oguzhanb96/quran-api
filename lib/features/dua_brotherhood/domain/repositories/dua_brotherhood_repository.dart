import '../entities/dua_chain.dart';

abstract class DuaBrotherhoodRepository {
  Future<List<DuaChain>> getChains();
  Future<DuaChain?> getChain(String chainId);
  Future<void> joinChain(String chainId);
  Future<void> contribute(String chainId, int amount);
  Future<void> registerPushToken();
}
