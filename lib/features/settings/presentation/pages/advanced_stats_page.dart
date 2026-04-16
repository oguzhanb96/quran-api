import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/settings/app_preferences.dart';

class AdvancedStatsPage extends StatelessWidget {
  const AdvancedStatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final premium = AppPreferences.isPremiumEnabled();

    if (!premium) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            'Gelişmiş İstatistikler',
            style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD97706).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 40,
                    color: Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Premium Gerekli',
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu özellik Premium üyelik gerektirir.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed('/premium'),
                  icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                  label: const Text(
                    'Premium\'a Geç',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5),
      body: ValueListenableBuilder(
        valueListenable: AppPreferences.box.listenable(keys: [
          AppPreferences.readingProgressMinutesKey,
          AppPreferences.readingGoalMinutesKey,
          AppPreferences.dhikrStreakKey,
          AppPreferences.dhikrMonthlyTotalKey,
          AppPreferences.duaPlayCountKey,
          AppPreferences.totalAppMinutesKey,
          AppPreferences.totalSurahsReadKey,
          AppPreferences.readingHistoryKey,
        ]),
        builder: (context, box, _) {
          final stats = [
            (Icons.menu_book_rounded, 'Günlük Okuma', '${AppPreferences.getReadingProgress().toStringAsFixed(1)} dk', const Color(0xFF064E3B)),
            (Icons.flag_rounded, 'Okuma Hedefi', '${AppPreferences.getReadingGoal().toStringAsFixed(1)} dk', const Color(0xFF0369A1)),
            (Icons.local_fire_department_rounded, 'Zikir Serisi', '${AppPreferences.getDhikrStreak()} gün', const Color(0xFFD97706)),
            (Icons.star_rounded, 'Aylık Zikir', '${AppPreferences.getDhikrMonthlyTotal()} adet', const Color(0xFF7C3AED)),
            (Icons.volume_up_rounded, 'Dua Dinleme', '${AppPreferences.getDuaPlayCount()} kez', const Color(0xFFEC4899)),
            (Icons.auto_stories_rounded, 'Okunan Sure', '${AppPreferences.getTotalSurahsRead()} sure', const Color(0xFF0EA5E9)),
            (Icons.timer_rounded, 'Uygulama Süresi', '${AppPreferences.getTotalAppMinutes()} dk', const Color(0xFF10B981)),
          ];

          final history = AppPreferences.getReadingHistory();
          final today = DateTime.now();
          final last7 = List.generate(7, (i) {
            final d = today.subtract(Duration(days: 6 - i));
            final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
            return (key: key, day: _dayLabel(d.weekday), minutes: history[key] ?? 0.0);
          });
          final maxMinutes = last7.map((e) => e.minutes).fold(0.0, (a, b) => a > b ? a : b);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                floating: true,
                title: Text(
                  'Gelişmiş İstatistikler',
                  style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stat grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        final s = stats[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.07)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: s.$4.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(s.$1, color: s.$4, size: 20),
                              ),
                              const Spacer(),
                              Text(
                                s.$3,
                                style: GoogleFonts.notoSerif(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.$2,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Weekly reading chart
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.07)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF006D44).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF006D44), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Haftalık Okuma',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 120,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: last7.map((entry) {
                                final barHeight = maxMinutes > 0
                                    ? (entry.minutes / maxMinutes) * 90
                                    : 0.0;
                                final isToday = entry.key == '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (entry.minutes > 0)
                                          Text(
                                            '${entry.minutes.toStringAsFixed(0)}',
                                            style: TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 600),
                                          curve: Curves.easeOutCubic,
                                          height: barHeight.clamp(4.0, 90.0),
                                          decoration: BoxDecoration(
                                            color: isToday
                                                ? const Color(0xFF006D44)
                                                : const Color(0xFF006D44).withValues(alpha: 0.35),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          entry.day,
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11,
                                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                            color: isToday ? const Color(0xFF006D44) : scheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _dayLabel(int weekday) {
    const labels = {1: 'Pzt', 2: 'Sal', 3: 'Çar', 4: 'Per', 5: 'Cum', 6: 'Cmt', 7: 'Paz'};
    return labels[weekday] ?? '';
  }
}
