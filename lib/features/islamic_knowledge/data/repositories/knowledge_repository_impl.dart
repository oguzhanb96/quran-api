import '../../../../core/settings/app_preferences.dart';
import '../../domain/entities/knowledge_item.dart';
import '../../domain/entities/knowledge_module.dart';
import '../../domain/repositories/knowledge_repository.dart';
import '../datasources/knowledge_local_datasource.dart';

class KnowledgeRepositoryImpl implements KnowledgeRepository {
  KnowledgeRepositoryImpl(this._local);

  final KnowledgeLocalDataSource _local;

  static const _modules = <KnowledgeModule>[
    KnowledgeModule(
      id: 'pillars_islam',
      title: "İslam'ın Şartları",
      subtitle: '5 temel esas',
    ),
    KnowledgeModule(
      id: 'pillars_faith',
      title: "İmanın Şartları",
      subtitle: '6 iman esası',
    ),
    KnowledgeModule(
      id: 'esmaul_husna',
      title: "Esmaü'l-Hüsna",
      subtitle: "Allah'ın 99 ismi",
    ),
    KnowledgeModule(
      id: 'six_kalima',
      title: '6 Kelime-i Şehadet',
      subtitle: 'Okunuş ve anlam',
    ),
    KnowledgeModule(id: 'siyer', title: 'Siyer-i Nebi', subtitle: 'Özet hayat'),
    KnowledgeModule(
      id: 'fiqh_basics',
      title: 'Fıkhi Bilgiler',
      subtitle: 'Abdest ve namaz',
    ),
    KnowledgeModule(id: 'terms', title: 'İslami Terimler', subtitle: 'Sözlük'),
    KnowledgeModule(
      id: 'interesting_facts',
      title: 'İlginç Bilgiler',
      subtitle: 'Genel kültür',
    ),
  ];

  @override
  Future<List<KnowledgeModule>> getModules() async {
    final lang = AppPreferences.readLocaleCodeSync() ?? 'tr';
    final remote = await _local.fetchModulesRemote(lang);
    if (remote != null && remote.isNotEmpty) {
      final out = <KnowledgeModule>[];
      for (final e in remote) {
        final id = e['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        out.add(
          KnowledgeModule(
            id: id,
            title: e['title']?.toString() ?? '',
            subtitle: e['subtitle']?.toString() ?? '',
          ),
        );
      }
      if (out.isNotEmpty) return out;
    }
    return _modules;
  }

  @override
  Future<List<KnowledgeItem>> getItems(String moduleId) async {
    final lang = AppPreferences.readLocaleCodeSync() ?? 'tr';
    final items = await _local.getItems(moduleId, lang: lang);
    return items
        .map(
          (e) => KnowledgeItem(
            id: e['id']?.toString() ?? '',
            title: e['title']?.toString() ?? '',
            content: e['content']?.toString() ?? '',
            benefit: e['benefit']?.toString() ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<KnowledgeItem?> getItem(String moduleId, String itemId) async {
    final items = await getItems(moduleId);
    for (final item in items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }
}
