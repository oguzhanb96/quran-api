import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/providers.dart';
import '../../domain/entities/knowledge_item.dart';

class KnowledgeDetailPage extends ConsumerWidget {
  const KnowledgeDetailPage({
    super.key,
    required this.moduleId,
    required this.itemId,
    this.moduleColor,
    this.moduleIcon,
  });

  final String moduleId;
  final String itemId;
  final Color? moduleColor;
  final IconData? moduleIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5),
      body: FutureBuilder<(KnowledgeItem?, List<KnowledgeItem>)>(
        future: () async {
          final repo = ref.read(knowledgeRepositoryProvider);
          final results = await Future.wait([
            repo.getItem(moduleId, itemId),
            repo.getItems(moduleId),
          ]);
          return (results[0] as KnowledgeItem?, results[1] as List<KnowledgeItem>);
        }(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final item = snapshot.data!.$1;
          final allItems = snapshot.data!.$2;

          if (item == null) {
            return Scaffold(
              backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              body: Center(
                child: Text(
                  'İçerik bulunamadı.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          final color = moduleColor ?? scheme.primary;
          final icon = moduleIcon ?? Icons.book_rounded;

          final currentIndex = allItems.indexWhere((i) => i.id == itemId);
          final hasPrev = currentIndex > 0;
          final hasNext = currentIndex < allItems.length - 1;

          final contentLines = item.content
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                floating: true,
                title: Text(
                  item.title,
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([

                    // Hero başlık banner
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            color.withValues(alpha: isDark ? 0.45 : 0.9),
                            color.withValues(alpha: isDark ? 0.28 : 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -10,
                            bottom: -10,
                            child: Icon(
                              icon,
                              size: 90,
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(icon, color: Colors.white, size: 26),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: GoogleFonts.notoSerif(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.3,
                                      ),
                                    ),
                                    if (allItems.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${currentIndex + 1} / ${allItems.length}',
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fade(duration: 400.ms).slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 16),

                    // İçerik kartı
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.article_rounded, size: 17, color: color),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'İÇERİK',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (contentLines.length > 1)
                            ...contentLines.asMap().entries.map((entry) {
                              final i = entry.key;
                              final line = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      margin: const EdgeInsets.only(top: 1, right: 12),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: color,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        line,
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 15,
                                          height: 1.65,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                          else
                            Text(
                              item.content,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 15,
                                height: 1.7,
                                color: scheme.onSurface,
                              ),
                            ),
                        ],
                      ),
                    ).animate().fade(duration: 400.ms, delay: 80.ms).slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 16),

                    // Fazilet kartı
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF064E3B).withValues(alpha: isDark ? 0.35 : 0.12),
                            const Color(0xFF065F46).withValues(alpha: isDark ? 0.18 : 0.06),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border(
                          left: BorderSide(
                            color: const Color(0xFF10B981),
                            width: 4,
                          ),
                          top: BorderSide(
                            color: const Color(0xFF064E3B).withValues(alpha: 0.2),
                          ),
                          right: BorderSide(
                            color: const Color(0xFF064E3B).withValues(alpha: 0.2),
                          ),
                          bottom: BorderSide(
                            color: const Color(0xFF064E3B).withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.star_rounded,
                                  size: 17,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'FAZİLET & ÖNEMİ',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '"',
                                style: TextStyle(
                                  fontFamily: 'Noto Serif',
                                  fontSize: 48,
                                  height: 0.8,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.benefit,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 14,
                                    height: 1.7,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : const Color(0xFF064E3B),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fade(duration: 400.ms, delay: 160.ms).slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 20),

                    // Önceki / Sonraki navigasyon
                    if (hasPrev || hasNext)
                      Row(
                        children: [
                          if (hasPrev)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  final prevItem = allItems[currentIndex - 1];
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => KnowledgeDetailPage(
                                        moduleId: moduleId,
                                        itemId: prevItem.id,
                                        moduleColor: moduleColor,
                                        moduleIcon: moduleIcon,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                label: const Text(
                                  'Önceki',
                                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: color,
                                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          if (hasPrev && hasNext) const SizedBox(width: 12),
                          if (hasNext)
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  final nextItem = allItems[currentIndex + 1];
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => KnowledgeDetailPage(
                                        moduleId: moduleId,
                                        itemId: nextItem.id,
                                        moduleColor: moduleColor,
                                        moduleIcon: moduleIcon,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                label: const Text(
                                  'Sonraki',
                                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: color,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                        ],
                      ).animate().fade(duration: 400.ms, delay: 240.ms),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
