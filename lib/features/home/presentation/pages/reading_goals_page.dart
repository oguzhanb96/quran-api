import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/settings/app_preferences.dart';

class ReadingGoalsPage extends StatefulWidget {
  const ReadingGoalsPage({super.key});

  @override
  State<ReadingGoalsPage> createState() => _ReadingGoalsPageState();
}

class _ReadingGoalsPageState extends State<ReadingGoalsPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            floating: true,
            title: Text(
              AppText.of(context, 'goalsTitle'),
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            centerTitle: true,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: ValueListenableBuilder(
              valueListenable: AppPreferences.box.listenable(keys: [
                AppPreferences.readingGoalMinutesKey,
                AppPreferences.readingProgressMinutesKey,
                AppPreferences.readingLastDateKey,
                AppPreferences.dhikrStreakKey,
                AppPreferences.dhikrMonthlyTotalKey,
              ]),
              builder: (context, box, _) {
                final double dailyGoalMinutes = AppPreferences.getReadingGoal();
                final double todayMinutes = AppPreferences.getReadingProgress();
                final double progress = dailyGoalMinutes <= 0
                    ? 0
                    : (todayMinutes / dailyGoalMinutes).clamp(0.0, 1.0);
                final streak = AppPreferences.getDhikrStreak();
                final monthlyTotal = AppPreferences.getDhikrMonthlyTotal();
                final isGoalMet = progress >= 1.0;

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Hero kart ──────────────────────────────────────────
                    _GoalHeroCard(
                      progress: progress,
                      todayMinutes: todayMinutes,
                      dailyGoalMinutes: dailyGoalMinutes,
                      isGoalMet: isGoalMet,
                      isDark: isDark,
                    ).animate().fade(duration: 500.ms).slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 16),

                    // ── İstatistik kartları ────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.local_fire_department_rounded,
                            value: '$streak',
                            label: AppText.of(context, 'days'),
                            sublabel: AppText.of(context, 'streak'),
                            color: const Color(0xFFF97316),
                            isDark: isDark,
                          ).animate().fade(duration: 400.ms, delay: 80.ms).scale(begin: const Offset(0.95, 0.95)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.star_rounded,
                            value: _formatNumber(monthlyTotal),
                            label: 'zikir',
                            sublabel: AppText.of(context, 'monthlyTotal'),
                            color: const Color(0xFFF59E0B),
                            isDark: isDark,
                          ).animate().fade(duration: 400.ms, delay: 120.ms).scale(begin: const Offset(0.95, 0.95)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.menu_book_rounded,
                            value: '${todayMinutes.toStringAsFixed(0)}',
                            label: 'dk',
                            sublabel: 'Bugün okunan',
                            color: const Color(0xFF10B981),
                            isDark: isDark,
                          ).animate().fade(duration: 400.ms, delay: 160.ms).scale(begin: const Offset(0.95, 0.95)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Hedef ayarla başlığı ───────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.tune_rounded, size: 16, color: scheme.primary),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Günlük Hedef Ayarla',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ).animate().fade(duration: 400.ms, delay: 200.ms),

                    const SizedBox(height: 12),

                    // ── Slider kartı ───────────────────────────────────────
                    _GoalSliderCard(
                      dailyGoalMinutes: dailyGoalMinutes,
                      isDark: isDark,
                      scheme: scheme,
                    ).animate().fade(duration: 400.ms, delay: 240.ms).slideY(begin: 0.06, end: 0),

                    const SizedBox(height: 20),

                    // ── Motivasyon başlığı ─────────────────────────────────
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFF8B5CF6)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Motivasyon',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ).animate().fade(duration: 400.ms, delay: 280.ms),

                    const SizedBox(height: 12),

                    // ── Motivasyon kartları ────────────────────────────────
                    ..._motivationItems.asMap().entries.map((entry) {
                      return _MotivationCard(
                        item: entry.value,
                        isDark: isDark,
                      ).animate().fade(
                        duration: 400.ms,
                        delay: Duration(milliseconds: 320 + entry.key * 60),
                      ).slideY(begin: 0.06, end: 0);
                    }),

                    const SizedBox(height: 12),

                    // ── Bilgi notu ─────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.primary.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 18, color: scheme.primary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Okuma sayacı, Kur\'an okuma sayfasında otomatik olarak güncellenir.',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12,
                                color: scheme.primary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade(duration: 400.ms, delay: 500.ms),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const _motivationItems = [
    _MotivationItem(
      quote: '"Kur\'an okuyunuz. Zira o, kıyamet gününde kendisini okuyanlara şefaatçi olarak gelecektir."',
      source: 'Müslim',
      icon: Icons.auto_stories_rounded,
      color: Color(0xFF0EA5E9),
    ),
    _MotivationItem(
      quote: '"Sizin en hayırlınız Kur\'an\'ı öğrenen ve öğretendir."',
      source: 'Buhari',
      icon: Icons.school_rounded,
      color: Color(0xFF10B981),
    ),
    _MotivationItem(
      quote: '"Kur\'an\'ı güzelce okuyan, yazıcı ve şerefli meleklerle beraberdir."',
      source: 'Buhari, Müslim',
      icon: Icons.star_rounded,
      color: Color(0xFF8B5CF6),
    ),
  ];

  String _formatNumber(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GoalHeroCard extends StatelessWidget {
  const _GoalHeroCard({
    required this.progress,
    required this.todayMinutes,
    required this.dailyGoalMinutes,
    required this.isGoalMet,
    required this.isDark,
  });

  final double progress;
  final double todayMinutes;
  final double dailyGoalMinutes;
  final bool isGoalMet;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final primaryColor = isGoalMet ? const Color(0xFF10B981) : const Color(0xFF006D44);
    final secondaryColor = isGoalMet ? const Color(0xFF059669) : const Color(0xFF065F46);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -20,
            child: Icon(
              isGoalMet ? Icons.emoji_events_rounded : Icons.menu_book_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isGoalMet ? '🎉 HEDEF TAMAMLANDI!' : 'GÜNLÜK OKUMA HEDEFİ',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      todayMinutes.toStringAsFixed(0),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -2,
                        height: 1.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 6),
                      child: Text(
                        '/ ${dailyGoalMinutes.toStringAsFixed(0)} dk',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white60,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}% tamamlandı',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
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

// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isDark,
  });

  final IconData icon;
  final String value;
  final String label;
  final String sublabel;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                TextSpan(
                  text: ' $label',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GoalSliderCard extends StatelessWidget {
  const _GoalSliderCard({
    required this.dailyGoalMinutes,
    required this.isDark,
    required this.scheme,
  });

  final double dailyGoalMinutes;
  final bool isDark;
  final ColorScheme scheme;

  String _goalLabel(double minutes) {
    if (minutes < 5) return 'Hedef ayarlamak için kaydırın';
    if (minutes <= 10) return 'Başlangıç seviyesi';
    if (minutes <= 20) return 'Hafif okuyucu';
    if (minutes <= 30) return 'Düzenli okuyucu';
    if (minutes <= 45) return 'Aktif okuyucu';
    return 'Yoğun okuyucu';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dailyGoalMinutes < 5
                          ? 'Hedef belirlenmedi'
                          : '${dailyGoalMinutes.toStringAsFixed(0)} dakika / gün',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.primary,
                      ),
                    ),
                    Text(
                      _goalLabel(dailyGoalMinutes),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.timer_rounded, color: scheme.primary, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: scheme.primary,
              inactiveTrackColor: scheme.primary.withValues(alpha: 0.1),
              thumbColor: scheme.primary,
              overlayColor: scheme.primary.withValues(alpha: 0.1),
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: dailyGoalMinutes.clamp(5.0, 90.0),
              min: 5,
              max: 90,
              divisions: 17,
              label: dailyGoalMinutes < 5 ? 'Hedef belirlenmedi' : '${dailyGoalMinutes.toStringAsFixed(0)} dk',
              onChanged: (v) => AppPreferences.setReadingGoal(v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 dk',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                '90 dk',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _MotivationItem {
  const _MotivationItem({
    required this.quote,
    required this.source,
    required this.icon,
    required this.color,
  });

  final String quote;
  final String source;
  final IconData icon;
  final Color color;
}

class _MotivationCard extends StatelessWidget {
  const _MotivationCard({required this.item, required this.isDark});

  final _MotivationItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: item.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.quote,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white70 : const Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '— ${item.source}',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.color,
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
