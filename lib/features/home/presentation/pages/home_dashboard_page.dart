import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/settings/app_preferences.dart';
import '../../../../core/theme/app_transitions.dart';
import '../../../../core/widgets/app_side_panel.dart';
import '../../../prayer_times/presentation/prayer_name_localization.dart';
import '../../../prayer_times/presentation/viewmodels/prayer_times_viewmodel.dart';
import '../../../quran/domain/entities/surah_meta.dart';
import '../../../quran/presentation/pages/quran_reading_page.dart';

class HomeDashboardPage extends ConsumerWidget {
  const HomeDashboardPage({super.key});

  void _openProfile(BuildContext context) {
    context.push('/profile');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerState = ref.watch(prayerTimesProvider);
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            floating: true,
            pinned: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => AppSidePanel.open(context),
              ),
            ),
            title: Text(
              'Noor Essence',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: InkWell(
                  onTap: () => _openProfile(context),
                  borderRadius: BorderRadius.circular(18),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFFFDCC3),
                    child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                RepaintBoundary(
                  child: prayerState.when(
                    data: (state) => _PrayerHeroCard(state: state),
                    loading: () => const _PrayerHeroLoading(),
                    error: (e, s) => const _PrayerOfflineCard(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      flex: 3,
                      child: RepaintBoundary(child: _ContinueReadingCard()),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      flex: 2,
                      child: RepaintBoundary(child: _QuickActionGrid()),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _DailyQuoteCard(),
                const SizedBox(height: 24),
                const _PremiumBannerCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

}

class _PrayerHeroCard extends StatelessWidget {
  const _PrayerHeroCard({required this.state});
  final PrayerTimesState state;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(seconds: 1), (x) => x),
      builder: (context, _) {
        final now = DateTime.now();
        final prayers = state.times;

        // Find the next prayer that hasn't started yet
        final upcoming = prayers.firstWhere(
          (p) => p.time.isAfter(now),
          orElse: () => prayers.first,
        );

        // If diff is negative (all prayers passed today), add 1 day for tomorrow's first prayer
        final rawDiff = upcoming.time.difference(now);
        final diff = rawDiff.isNegative
            ? upcoming.time.add(const Duration(days: 1)).difference(now)
            : rawDiff;
        final isTomorrow = rawDiff.isNegative;

        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        return Container(
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFF064E3B),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Konum satırı
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF6EE7B7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.locationLabel,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6EE7B7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isTomorrow
                      ? AppText.of(context, 'dashboardPrayerTomorrow')
                      : AppText.of(context, 'dashboardPrayerNext'),
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  localizedPrayerName(context, upcoming.name),
                  style: GoogleFonts.notoSerif(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppText.of(context, 'dashboardCountdownPrefix')} ${hours > 0 ? '${hours.toString().padLeft(2, '0')}:' : ''}${minutes.toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD97706),
                  ),
                ),
                const Spacer(),
                Row(
                  children: prayers.map((prayer) {
                    final isSelected = prayer.name == upcoming.name;
                    final timeStr = DateFormat('HH:mm').format(prayer.time);
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFD97706) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              localizedPrayerName(context, prayer.name).toUpperCase(),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ).animate().fade(duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
      },
    );
  }
}

class _PrayerHeroLoading extends StatelessWidget {
  const _PrayerHeroLoading();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1200.ms);
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.format_list_numbered,
                label: AppText.of(context, 'quran'),
                onTap: () => context.push('/quran'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.menu_book_rounded,
                label: AppText.of(context, 'dua'),
                onTap: () => context.push('/duas'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionButton(
                icon: Icons.favorite,
                label: AppText.of(context, 'favorites'),
                onTap: () => context.push('/favorites'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.explore,
                label: AppText.of(context, 'qibla'),
                onTap: () => context.push('/qibla'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fade(duration: 600.ms, delay: 300.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F3EF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: scheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder(
      valueListenable: AppPreferences.box.listenable(keys: [
        AppPreferences.lastReadSurahKey,
        AppPreferences.lastReadSurahNameKey,
        AppPreferences.lastReadAyahKey,
      ]),
      builder: (context, box, _) {
        final lastRead = AppPreferences.getLastRead();
        final surahName = lastRead?['surahName'] as String? ?? 'Al-Kahf';
        final ayah = lastRead?['ayah'] as int? ?? 45;
        final surahNumber = lastRead?['surah'] as int? ?? 18;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF5F3EF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.menu_book, size: 14, color: const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Text(
                    AppText.of(context, 'continueReadingBadge'),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                surahName,
                style: GoogleFonts.notoSerif(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppText.of(context, 'readingAyahShort', {'n': '$ayah'}),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(AppTransitions.fadeSlide(
                          page: QuranReadingPage(
                            surahMeta: SurahMeta(
                              number: surahNumber,
                              name: '',
                              englishName: surahName,
                              numberOfAyahs: 0,
                              revelationType: '',
                            ),
                          ),
                        ));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fade(duration: 600.ms, delay: 200.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
      },
    );
  }
}

class _DailyQuoteCard extends StatelessWidget {
  const _DailyQuoteCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays + 1;
    const quoteCount = 5;
    final quoteIndex = (dayOfYear - 1) % quoteCount;
    final quoteText = AppText.of(context, 'dailyQuote${quoteIndex}Text');
    final quoteAuthor = AppText.of(context, 'dailyQuote${quoteIndex}Author');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark ? [
            const Color(0xFF1E3A5F),
            const Color(0xFF0F172A),
          ] : [
            const Color(0xFFE8F4F0),
            const Color(0xFFF5F0E8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : scheme.primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote,
                color: scheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                AppText.of(context, 'quoteOfDay'),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"$quoteText"',
            style: GoogleFonts.notoSerif(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: scheme.onSurface,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 24,
                height: 2,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                quoteAuthor,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 600.ms, delay: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }
}

class _PremiumBannerCard extends StatelessWidget {
  const _PremiumBannerCard();

  @override
  Widget build(BuildContext context) {
    final isPremium = AppPreferences.isPremiumEnabled();
    if (isPremium) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/premium'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xFFFFD166)),
                      SizedBox(width: 5),
                      Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Color(0xFFFFD166),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              AppText.of(context, 'premium_banner_headline'),
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PremiumChip(
                  icon: Icons.download_rounded,
                  label: AppText.of(context, 'premium_feat_download_l'),
                ),
                _PremiumChip(
                  icon: Icons.record_voice_over_rounded,
                  label: AppText.of(context, 'premium_feat_reciters_l'),
                ),
                _PremiumChip(
                  icon: Icons.color_lens_rounded,
                  label: AppText.of(context, 'premium_feat_tajweed_l'),
                ),
                _PremiumChip(
                  icon: Icons.bar_chart_rounded,
                  label: AppText.of(context, 'premium_feat_stats_l'),
                ),
                _PremiumChip(
                  icon: Icons.block_rounded,
                  label: AppText.of(context, 'premium_feat_ads_l'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fade(duration: 600.ms, delay: 500.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad);
  }
}

class _PrayerOfflineCard extends StatelessWidget {
  const _PrayerOfflineCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD97706).withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppText.of(context, 'loadError'),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppText.of(context, 'prayer_offline_detail'),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumChip extends StatelessWidget {
  const _PremiumChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
