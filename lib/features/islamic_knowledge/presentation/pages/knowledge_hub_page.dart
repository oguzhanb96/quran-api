import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_language.dart';
import '../../data/providers.dart';
import '../../domain/entities/knowledge_module.dart';
import 'knowledge_list_page.dart';

class KnowledgeHubPage extends ConsumerStatefulWidget {
  const KnowledgeHubPage({super.key});

  static String localizedModuleTitle(BuildContext context, KnowledgeModule m) {
    final key = 'km_${m.id}_t';
    final localized = AppText.of(context, key);
    if (localized != key) return localized;
    return m.title.isNotEmpty ? m.title : localized;
  }

  static String localizedModuleSubtitle(BuildContext context, KnowledgeModule m) {
    final key = 'km_${m.id}_s';
    final localized = AppText.of(context, key);
    if (localized != key) return localized;
    return m.subtitle.isNotEmpty ? m.subtitle : localized;
  }

  static const _moduleColors = <String, Color>{
    'pillars_islam': Color(0xFF064E3B),
    'pillars_faith': Color(0xFF1D4ED8),
    'esmaul_husna': Color(0xFF7C3AED),
    'six_kalima': Color(0xFFB45309),
    'siyer': Color(0xFF0369A1),
    'fiqh_basics': Color(0xFF065F46),
    'terms': Color(0xFF6D28D9),
    'interesting_facts': Color(0xFFBE185D),
  };

  static const _moduleIcons = <String, IconData>{
    'pillars_islam': Icons.mosque_rounded,
    'pillars_faith': Icons.star_rounded,
    'esmaul_husna': Icons.auto_awesome_rounded,
    'six_kalima': Icons.menu_book_rounded,
    'siyer': Icons.history_edu_rounded,
    'fiqh_basics': Icons.balance_rounded,
    'terms': Icons.translate_rounded,
    'interesting_facts': Icons.lightbulb_rounded,
  };

  @override
  ConsumerState<KnowledgeHubPage> createState() => _KnowledgeHubPageState();
}

class _KnowledgeHubPageState extends ConsumerState<KnowledgeHubPage> {
  late Future<List<KnowledgeModule>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    _modulesFuture = _loadModules();
  }

  Future<List<KnowledgeModule>> _loadModules() =>
      ref.read(knowledgeRepositoryProvider).getModules();

  Future<void> _onRefresh() async {
    setState(() {
      _modulesFuture = _loadModules();
    });
    await _modulesFuture;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              floating: true,
              title: Text(
                AppText.of(context, 'knowledgeHubTitle'),
                style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: FutureBuilder<List<KnowledgeModule>>(
                future: _modulesFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final modules = snapshot.data!;
                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.05,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final module = modules[index];
                        final color =
                            KnowledgeHubPage._moduleColors[module.id] ??
                                scheme.primary;
                        final icon =
                            KnowledgeHubPage._moduleIcons[module.id] ??
                                Icons.book_rounded;

                        return _ModuleCard(
                          module: module,
                          color: color,
                          icon: icon,
                          isDark: isDark,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => KnowledgeListPage(
                                moduleId: module.id,
                                moduleColor: color,
                                moduleIcon: icon,
                                moduleTitle: KnowledgeHubPage.localizedModuleTitle(
                                  context,
                                  module,
                                ),
                                moduleSubtitle:
                                    KnowledgeHubPage.localizedModuleSubtitle(
                                  context,
                                  module,
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fade(
                              duration: 400.ms,
                              delay: Duration(milliseconds: index * 60),
                            )
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              curve: Curves.easeOutQuad,
                            );
                      },
                      childCount: modules.length,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.color,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final KnowledgeModule module;
  final Color color;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: isDark ? 0.25 : 0.12),
                color.withValues(alpha: isDark ? 0.12 : 0.06),
              ],
            ),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.3 : 0.2),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                KnowledgeHubPage.localizedModuleTitle(context, module),
                style: GoogleFonts.notoSerif(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                KnowledgeHubPage.localizedModuleSubtitle(context, module),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.45),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
