import '../entities/knowledge_item.dart';
import '../entities/knowledge_module.dart';

abstract class KnowledgeRepository {
  Future<List<KnowledgeModule>> getModules();
  Future<List<KnowledgeItem>> getItems(String moduleId);
  Future<KnowledgeItem?> getItem(String moduleId, String itemId);
}
