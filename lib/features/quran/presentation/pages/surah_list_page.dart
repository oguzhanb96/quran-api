import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/audio/audio_profile.dart';
import '../../../../core/audio/offline_audio_service.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/app_dio.dart';
import '../../../../core/theme/app_transitions.dart';
import '../../../../core/widgets/app_side_panel.dart';
import '../../../../core/settings/app_preferences.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../data/surah_data.dart';
import '../../domain/entities/surah_meta.dart';
import 'quran_reading_page.dart';

class SurahListPage extends ConsumerStatefulWidget {
  const SurahListPage({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends ConsumerState<SurahListPage> {
  List<SurahMeta> _surahs = const <SurahMeta>[];
  List<SurahMeta> _filteredSurahs = const <SurahMeta>[];
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  int _selectedTab = 0;
  bool _loadingSurahs = true;
  String? _surahError;
  final Set<int> _downloadingSet = {};

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 3);
    _loadSurahList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _handleDownload(SurahMeta surah) async {
    if (!AppPreferences.isPremiumEnabled()) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        useSafeArea: true,
        isScrollControlled: true,
        builder: (ctx) => _PremiumGateSheet(
          onGoToPremium: () {
            Navigator.pop(ctx);
            context.go('/premium');
          },
        ),
      );
      return;
    }

    if (AppPreferences.getDownloadedSurahs().contains(surah.number)) return;
    if (_downloadingSet.contains(surah.number)) return;

    setState(() => _downloadingSet.add(surah.number));

    try {
      final dio = ref.read(dioProvider);
      final offlineService = OfflineAudioService(dio);
      const reciter = 'ar.alafasy';
      const profile = AudioProfile.male;

      final response = await dio.get<Map<String, dynamic>>(
        '${AppConfig.quranApiBase}/surah/${surah.number}/$reciter',
      );
      final ayahs = (response.data?['data']?['ayahs'] as List<dynamic>? ?? []);
      final downloadedUrls = <String>[];
      final failedAyahs = <int>[];
      var successCount = 0;
      
      for (final ayah in ayahs.whereType<Map>()) {
        final map = ayah.cast<String, dynamic>();
        final numberInSurah = (map['numberInSurah'] as num?)?.toInt() ?? 0;
        final url = map['audio']?.toString();
        if (url != null && url.isNotEmpty) {
          final cachedFile = await offlineService.ensureCached(url, profile);
          if (cachedFile == null) {
            failedAyahs.add(numberInSurah);
            downloadedUrls.add(''); // Mark as failed
          } else {
            successCount++;
            downloadedUrls.add(url);
          }
        }
      }
      
      // Only mark as downloaded if all succeeded
      if (failedAyahs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$successCount/${ayahs.length} ayet indirildi. '
                'Ayet ${failedAyahs.join(", ")} indirilemedi. '
                'Tekrar deneyin.',
                style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      
      // All succeeded
      await AppPreferences.saveSurahAudioUrls(surah.number, downloadedUrls);
      await AppPreferences.addDownloadedSurah(surah.number);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✓ ${surah.englishName} - Tüm ${ayahs.length} ayet indirildi',
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppText.of(context, 'snackDownloadFailedSurah'),
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingSet.remove(surah.number));
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      final q = query.trim().toLowerCase();
      if (q.isEmpty) {
        setState(() => _filteredSurahs = _surahs);
        return;
      }
      setState(() {
        _filteredSurahs = _surahs.where((s) {
          return s.englishName.toLowerCase().contains(q) ||
              s.name.contains(q) ||
              s.number.toString().contains(q);
        }).toList();
      });
    });
  }

  Future<void> _loadSurahList() async {
    final cache = Hive.box('quran_cache');
    final cached = cache.get('remote_surahs');
    if (cached is List && cached.isNotEmpty) {
      final list = cached
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .map((item) => SurahMeta(
                number: (item['number'] as num?)?.toInt() ?? 0,
                name: item['name']?.toString() ?? '',
                englishName: item['englishName']?.toString() ?? '',
                numberOfAyahs: (item['numberOfAyahs'] as num?)?.toInt() ?? 0,
                revelationType: item['revelationType']?.toString() ?? '',
              ))
          .where((s) => s.number > 0)
          .toList();
      if (!mounted) return;
      setState(() {
        _surahs = list;
        _filteredSurahs = list;
        _loadingSurahs = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _surahs = StaticSurahData.surahList;
      _filteredSurahs = StaticSurahData.surahList;
      _loadingSurahs = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => AppSidePanel.open(context),
        ),
        title: Text(
          AppText.of(context, 'quran'),
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: scheme.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: _loadingSurahs
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: AppPreferences.box.listenable(
                keys: [
                  AppPreferences.downloadedSurahsKey,
                  AppPreferences.savedSurahsKey,
                ],
              ),
              builder: (context, _, __) {
                return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_surahError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppText.of(context, _surahError!),
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        const _LastReadHero(),
                        const SizedBox(height: 32),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? scheme.surfaceContainerHigh
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: AppText.of(context, 'searchHint'),
                              hintStyle: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: scheme.onSurfaceVariant,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              _FilterTab(
                                label: AppText.of(context, 'tabSurah'),
                                isSelected: _selectedTab == 0,
                                onTap: () => setState(() => _selectedTab = 0),
                              ),
                              const SizedBox(width: 12),
                              _FilterTab(
                                label: AppText.of(context, 'tabBookmarks'),
                                isSelected: _selectedTab == 1,
                                onTap: () => setState(() => _selectedTab = 1),
                              ),
                              const SizedBox(width: 12),
                              _FilterTab(
                                label: AppText.of(context, 'tabSajda'),
                                isSelected: _selectedTab == 2,
                                onTap: () => setState(() => _selectedTab = 2),
                              ),
                              const SizedBox(width: 12),
                              _FilterTab(
                                label: AppText.of(context, 'tabDownloadedSurahs'),
                                isSelected: _selectedTab == 3,
                                onTap: () => setState(() => _selectedTab = 3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_selectedTab == 1)
                  _buildSavedTab(context)
                else if (_selectedTab == 2)
                  _buildSajdaTab(context)
                else if (_selectedTab == 3)
                  _buildDownloadedTab(context)
                else if (_filteredSurahs.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        AppText.of(context, 'noSurahsFound'),
                        style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final surah = _filteredSurahs[index];

                        final downloadedSurahs = AppPreferences.getDownloadedSurahs();
                        final isDownloaded = downloadedSurahs.contains(surah.number);
                        final isDownloading = _downloadingSet.contains(surah.number);

                        final item = _SurahListItem(
                          meta: surah,
                          isDownloaded: isDownloaded,
                          isDownloading: isDownloading,
                          onTap: () {
                            Navigator.of(context).push(
                              AppTransitions.fadeSlide(
                                page: QuranReadingPage(surahMeta: surah),
                              ),
                            );
                          },
                          onDownload: () => _handleDownload(surah),
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: item,
                        );
                      }, childCount: _filteredSurahs.length),
                    ),
                  ),
              ],
            );
              },
            ),
    );
  }

  Widget _buildSajdaTab(BuildContext context) {
    const sajdaAyahs = [
      (surah: 7, ayah: 206),
      (surah: 13, ayah: 15),
      (surah: 16, ayah: 50),
      (surah: 17, ayah: 109),
      (surah: 19, ayah: 58),
      (surah: 22, ayah: 18),
      (surah: 22, ayah: 77),
      (surah: 25, ayah: 60),
      (surah: 27, ayah: 26),
      (surah: 32, ayah: 15),
      (surah: 38, ayah: 24),
      (surah: 41, ayah: 38),
      (surah: 53, ayah: 62),
      (surah: 84, ayah: 21),
      (surah: 96, ayah: 19),
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF95D3BA) : const Color(0xFF003527);
    final bgColor = isDark ? Theme.of(context).colorScheme.surfaceContainerLow : Theme.of(context).colorScheme.surfaceContainerHighest;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final sajda = sajdaAyahs[index];
            final surah = _surahs.firstWhere(
              (s) => s.number == sajda.surah,
              orElse: () => SurahMeta(
                number: sajda.surah,
                name: '',
                englishName: 'Surah ${sajda.surah}',
                numberOfAyahs: 0,
                revelationType: '',
              ),
            );

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: AppGlassCard(
                padding: const EdgeInsets.all(20),
                baseColor: bgColor,
                opacity: 0.7,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      AppTransitions.fadeSlide(
                        page: QuranReadingPage(surahMeta: surah),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD97706).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.back_hand_rounded,
                          color: Color(0xFFD97706),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              surah.englishName,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${AppText.of(context, 'ayahNo')}: ${sajda.ayah}',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        surah.name,
                        style: GoogleFonts.notoSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: sajdaAyahs.length,
        ),
      ),
    );
  }

  Widget _buildDownloadedTab(BuildContext context) {
    final downloadedNums = AppPreferences.getDownloadedSurahs();
    if (downloadedNums.isEmpty) {
      return _buildEmptyState(
        context,
        AppText.of(context, 'tabDownloadedSurahs'),
        Icons.download_done_rounded,
        AppText.of(context, 'downloadedSurahsEmpty'),
      );
    }
    final downloadedSurahs = _surahs.where((s) => downloadedNums.contains(s.number)).toList();
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final surah = downloadedSurahs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _SurahListItem(
                meta: surah,
                isDownloaded: true,
                isDownloading: false,
                onTap: () {
                  Navigator.of(context).push(
                    AppTransitions.fadeSlide(
                      page: QuranReadingPage(surahMeta: surah),
                    ),
                  );
                },
                onDownload: () {},
              ),
            );
          },
          childCount: downloadedSurahs.length,
        ),
      ),
    );
  }

  Widget _buildSavedTab(BuildContext context) {
    final savedNums = AppPreferences.getSavedSurahs();
    if (savedNums.isEmpty) {
      return _buildEmptyState(
        context,
        AppText.of(context, 'tabBookmarks'),
        Icons.bookmark_border_rounded,
        AppText.of(context, 'savedSurahsEmpty'),
      );
    }
    final savedSurahs = _surahs.where((s) => savedNums.contains(s.number)).toList();
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final surah = savedSurahs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _SurahListItem(
                meta: surah,
                isDownloaded: AppPreferences.getDownloadedSurahs().contains(surah.number),
                isDownloading: _downloadingSet.contains(surah.number),
                onTap: () {
                  Navigator.of(context).push(
                    AppTransitions.fadeSlide(
                      page: QuranReadingPage(surahMeta: surah),
                    ),
                  );
                },
                onDownload: () => _handleDownload(surah),
              ),
            );
          },
          childCount: savedSurahs.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: scheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Noto Serif',
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBg = isDark ? const Color(0xFF95D3BA) : const Color(0xFF003527);
    final activeFg = isDark ? const Color(0xFF003527) : Colors.white;

    final inactiveBg = isDark
        ? Theme.of(context).colorScheme.surfaceContainerLow
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final inactiveFg = isDark
        ? const Color(0xFF95D3BA)
        : const Color(0xFF003527);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.bold,
            color: isSelected ? activeFg : inactiveFg,
          ),
        ),
      ),
    );
  }
}

class _LastReadHero extends StatelessWidget {
  const _LastReadHero();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF064E3B) : const Color(0xFF064E3B);
    final buttonColor = isDark
        ? const Color(0xFFD97706)
        : const Color(0xFFD97706);

    return ValueListenableBuilder(
      valueListenable: AppPreferences.box.listenable(
        keys: [
          AppPreferences.lastReadSurahKey,
          AppPreferences.lastReadSurahNameKey,
          AppPreferences.lastReadAyahKey,
        ],
      ),
      builder: (context, box, _) {
        final lastRead = AppPreferences.getLastRead();
        if (lastRead == null) {
          return const SizedBox.shrink();
        }

        final surahName = lastRead['surahName'] as String;
        final ayah = lastRead['ayah'] as int;

        return AppGlassCard(
              padding: const EdgeInsets.all(28),
              baseColor: bgColor,
              opacity: 1.0,
              child: Stack(
                children: [
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Icon(
                      Icons.menu_book,
                      size: 200,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: const Color(0xFFFFDCC3),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppText.of(context, 'lastRead'),
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.0,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        surahName.isNotEmpty
                            ? surahName
                            : '${AppText.of(context, 'tabSurah')} ${lastRead['surah']}',
                        style: GoogleFonts.notoSerif(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${AppText.of(context, 'ayahNo')}: $ayah',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            AppTransitions.fadeSlide(
                              page: QuranReadingPage(
                                surahMeta: SurahMeta(
                                  number: lastRead['surah'] as int,
                                  name: '',
                                  englishName: surahName.isNotEmpty
                                      ? surahName
                                      : 'Surah ${lastRead['surah']}',
                                  numberOfAyahs: 0,
                                  revelationType: '',
                                ),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: isDark
                              ? const Color(0xFF2F1500)
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: buttonColor.withValues(alpha: 0.4),
                        ),
                        label: Text(
                          AppText.of(context, 'continueReading'),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        iconAlignment: IconAlignment.end,
                      ),
                    ],
                  ),
                ],
              ),
            )
            .animate()
            .fade(duration: 600.ms)
            .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
      },
    );
  }
}

class _SurahListItem extends StatelessWidget {
  const _SurahListItem({
    required this.meta,
    required this.onTap,
    required this.onDownload,
    this.isDownloaded = false,
    this.isDownloading = false,
  });

  final SurahMeta meta;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final bool isDownloaded;
  final bool isDownloading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = isDark
        ? const Color(0xFF95D3BA)
        : const Color(0xFF003527);
    final bgColor = isDark
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerHighest;

    return AppGlassCard(
      padding: const EdgeInsets.all(20),
      baseColor: bgColor,
      opacity: 0.7,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.pentagon_rounded,
                    size: 48,
                    color: const Color(0xFF904D00).withValues(alpha: 0.15),
                  ),
                  Text(
                    meta.number.toString(),
                    style: GoogleFonts.notoSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.englishName,
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${meta.englishName} • ${meta.numberOfAyahs} Verses',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  meta.name,
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 4),
                Text(
                  meta.revelationType.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: const Color(0xFF904D00),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: isDownloaded || isDownloading ? null : onDownload,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isDownloaded
                          ? const Color(0xFF10B981).withValues(alpha: 0.12)
                          : const Color(0xFF7C3AED).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isDownloading
                        ? const Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF7C3AED),
                            ),
                          )
                        : Icon(
                            isDownloaded
                                ? Icons.check_circle_rounded
                                : Icons.download_rounded,
                            size: 16,
                            color: isDownloaded
                                ? const Color(0xFF10B981)
                                : const Color(0xFF7C3AED),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumGateSheet extends StatelessWidget {
  const _PremiumGateSheet({required this.onGoToPremium});

  final VoidCallback onGoToPremium;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 80),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF7C3AED), size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            AppText.of(context, 'premiumOfflineFeatureTitle'),
            style: GoogleFonts.notoSerif(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppText.of(context, 'premiumOfflineDownloadBody'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onGoToPremium,
              icon: const Icon(Icons.workspace_premium_rounded, size: 18),
              label: Text(
                AppText.of(context, 'sidePremiumTitle'),
                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppText.of(context, 'premiumNotNow'),
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
