import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/localization/app_language.dart';
import '../../../core/widgets/app_side_panel.dart';
import '../../../features/prayer_times/presentation/prayer_name_localization.dart';
import '../../../features/prayer_times/presentation/viewmodels/prayer_times_viewmodel.dart';
import '../../dua/presentation/pages/dua_library_page.dart';
import '../../qibla/presentation/pages/qibla_compass_page.dart';
import 'pages/home_dashboard_page.dart';
import '../../quran/presentation/pages/surah_list_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({this.location, super.key});

  final String? location;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = _getSelectedIndex(widget.location ?? '/home');
  }

  @override
  void didUpdateWidget(HomeShellPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _currentIndex = _getSelectedIndex(widget.location ?? '/home');
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/quran')) return 1;
    if (location.startsWith('/duas')) return 2;
    if (location.startsWith('/qibla')) return 3;
    if (location.startsWith('/center')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5);
    return Scaffold(
      backgroundColor: bg,
      body: _buildPage(_currentIndex, widget.location ?? '/home'),
    );
  }

  Widget _buildPage(int index, String location) {
    switch (index) {
      case 0:
        return const HomeDashboardPage();
      case 1:
        final tab = location.contains('tab=juz') ? 1 : 0;
        return SurahListPage(initialTab: tab);
      case 2:
        return const DuaLibraryPage();
      case 3:
        return const QiblaCompassPage();
      case 4:
        return const CenterPage();
      default:
        return const HomeDashboardPage();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CenterPage
// ─────────────────────────────────────────────────────────────────────────────

class CenterPage extends ConsumerWidget {
  const CenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final prayerAsync = ref.watch(prayerTimesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            floating: true,
            leading: IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => AppSidePanel.open(context),
            ),
            title: Text(
              AppText.of(context, 'center'),
              style: GoogleFonts.notoSerif(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.person_rounded, size: 18, color: scheme.primary),
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Namaz vakti özet kartı ───────────────────────────────────
                _PrayerSummaryCard(prayerAsync: prayerAsync)
                    .animate()
                    .fade(duration: 500.ms)
                    .slideY(begin: 0.08, end: 0),

                const SizedBox(height: 20),

                // ── Hızlı erişim başlığı ─────────────────────────────────────
                _SectionHeader(
                  icon: Icons.bolt_rounded,
                  title: AppText.of(context, 'sectionQuickAccess'),
                  color: const Color(0xFF0EA5E9),
                ).animate().fade(duration: 400.ms, delay: 80.ms),

                const SizedBox(height: 12),

                // ── Hızlı erişim kartları (2 sütun, büyük) ──────────────────
                _QuickAccessGrid()
                    .animate()
                    .fade(duration: 400.ms, delay: 120.ms)
                    .slideY(begin: 0.08, end: 0),

                const SizedBox(height: 24),

                // ── İslami Bilgi başlığı ─────────────────────────────────────
                _SectionHeader(
                  icon: Icons.local_library_rounded,
                  title: AppText.of(context, 'sectionKnowledgeLibrary'),
                  color: const Color(0xFF8B5CF6),
                ).animate().fade(duration: 400.ms, delay: 160.ms),

                const SizedBox(height: 12),

                // ── Bilgi kartları ───────────────────────────────────────────
                _KnowledgeGrid()
                    .animate()
                    .fade(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.08, end: 0),

                const SizedBox(height: 24),

                // ── Topluluk başlığı ─────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.groups_rounded,
                  title: AppText.of(context, 'sectionCommunity'),
                  color: const Color(0xFFEC4899),
                ).animate().fade(duration: 400.ms, delay: 240.ms),

                const SizedBox(height: 12),

                // ── Dua Kardeşliği banner ────────────────────────────────────
                _DuaBrotherhoodBanner()
                    .animate()
                    .fade(duration: 400.ms, delay: 280.ms)
                    .slideY(begin: 0.08, end: 0),

                const SizedBox(height: 8),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Prayer Summary Card
// ─────────────────────────────────────────────────────────────────────────────

class _PrayerSummaryCard extends StatefulWidget {
  const _PrayerSummaryCard({required this.prayerAsync});

  final AsyncValue<PrayerTimesState> prayerAsync;

  @override
  State<_PrayerSummaryCard> createState() => _PrayerSummaryCardState();
}

class _PrayerSummaryCardState extends State<_PrayerSummaryCard> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatCountdown(BuildContext context, Duration diff) {
    if (diff.isNegative) return AppText.of(context, 'timePassed');
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (h > 0) {
      return AppText.of(context, 'countdownHM', {
        'h': '$h',
        'm': m.toString().padLeft(2, '0'),
      });
    }
    if (m > 0) {
      return AppText.of(context, 'countdownMS', {
        'm': '$m',
        's': s.toString().padLeft(2, '0'),
      });
    }
    return AppText.of(context, 'countdownS', {'s': '$s'});
  }

  @override
  Widget build(BuildContext context) {
    return widget.prayerAsync.when(
      loading: () => _buildShimmer(context),
      error: (_, __) => _buildError(context),
      data: (state) => _buildCard(context, state),
    );
  }

  Widget _buildCard(BuildContext context, PrayerTimesState state) {
    final now = _now;
    final upcoming = state.times.firstWhere(
      (t) => t.time.isAfter(now),
      orElse: () => state.times.first,
    );
    final diff = upcoming.time.difference(now);
    final timeStr = DateFormat('HH:mm').format(upcoming.time);

    // Son geçen namaz
    final past = state.times.lastWhere(
      (t) => t.time.isBefore(now),
      orElse: () => state.times.last,
    );

    return GestureDetector(
      onTap: () => context.push('/prayer'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF064E3B).withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Dekoratif daireler
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            // Cami ikonu
            Positioned(
              right: 24,
              top: 24,
              child: Icon(
                Icons.mosque_rounded,
                size: 56,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF6EE7B7)),
                      const SizedBox(width: 4),
                      Text(
                        state.locationLabel,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6EE7B7),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          AppText.of(context, 'prayerTimesChip'),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppText.of(context, 'nextNamazLabel'),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Color(0xFF6EE7B7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        localizedPrayerName(context, upcoming.name),
                        style: GoogleFonts.notoSerif(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        timeStr,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_rounded, size: 14, color: Color(0xFF6EE7B7)),
                            const SizedBox(width: 6),
                            Text(
                              _formatCountdown(context, diff),
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6EE7B7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${AppText.of(context, 'lastPrayerPrefix')} ${localizedPrayerName(context, past.name)}',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Mini vakitler satırı
                  Row(
                    children: state.times.map((t) {
                      final isNext = t.name == upcoming.name;
                      final isPast = t.time.isBefore(now);
                      return Expanded(
                        child: _MiniPrayerTime(
                          label: localizedPrayerShortLabel(context, t.name),
                          time: DateFormat('HH:mm').format(t.time),
                          isNext: isNext,
                          isPast: isPast,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF064E3B).withValues(alpha: 0.3),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF6EE7B7)),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/prayer'),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF047857)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.mosque_rounded, color: Colors.white54, size: 32),
              const SizedBox(height: 8),
              Text(
                AppText.of(context, 'tapForPrayerTimes'),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPrayerTime extends StatelessWidget {
  const _MiniPrayerTime({
    required this.label,
    required this.time,
    required this.isNext,
    required this.isPast,
  });

  final String label;
  final String time;
  final bool isNext;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isNext
                ? const Color(0xFF6EE7B7)
                : (isPast
                    ? Colors.white.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.7)),
          ),
        ),
        const SizedBox(height: 2),
        if (isNext)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF6EE7B7).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              time,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6EE7B7),
              ),
            ),
          )
        else
          Text(
            time,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isPast
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Access Grid
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItem(
        icon: Icons.access_time_rounded,
        title: AppText.of(context, 'quickPrayerTitle'),
        subtitle: AppText.of(context, 'quickPrayerSub'),
        route: '/prayer',
        gradient: const [Color(0xFF064E3B), Color(0xFF065F46)],
        accentColor: const Color(0xFF6EE7B7),
      ),
      _QuickItem(
        icon: Icons.fingerprint_rounded,
        title: AppText.of(context, 'quickDhikrTitle'),
        subtitle: AppText.of(context, 'quickDhikrSub'),
        route: '/dhikr',
        gradient: const [Color(0xFF1E40AF), Color(0xFF1D4ED8)],
        accentColor: const Color(0xFF93C5FD),
      ),
      _QuickItem(
        icon: Icons.calendar_month_rounded,
        title: AppText.of(context, 'quickCalTitle'),
        subtitle: AppText.of(context, 'quickCalSub'),
        route: '/calendar',
        gradient: const [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        accentColor: const Color(0xFFC4B5FD),
      ),
      _QuickItem(
        icon: Icons.track_changes_rounded,
        title: AppText.of(context, 'quickGoalsTitle'),
        subtitle: AppText.of(context, 'quickGoalsSub'),
        route: '/goals',
        gradient: const [Color(0xFFB45309), Color(0xFFD97706)],
        accentColor: const Color(0xFFFCD34D),
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.05,
      children: items.map((item) => _QuickAccessCard(item: item)).toList(),
    );
  }
}

class _QuickItem {
  const _QuickItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.gradient,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final List<Color> gradient;
  final Color accentColor;
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({required this.item});

  final _QuickItem item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(item.route),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item.gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: item.gradient.first.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -16,
              bottom: -16,
              child: Icon(
                item.icon,
                size: 90,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: item.accentColor.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Knowledge Grid
// ─────────────────────────────────────────────────────────────────────────────

class _KnowledgeGrid extends StatelessWidget {
  const _KnowledgeGrid();

  static const _items = [
    _KnowledgeItem(
      icon: Icons.menu_book_rounded,
      id: 'pillars_islam',
      route: '/knowledge/pillars_islam',
      color: Color(0xFF0D9488),
    ),
    _KnowledgeItem(
      icon: Icons.shield_moon_rounded,
      id: 'pillars_faith',
      route: '/knowledge/pillars_faith',
      color: Color(0xFF7C3AED),
    ),
    _KnowledgeItem(
      icon: Icons.auto_awesome_rounded,
      id: 'esmaul_husna',
      route: '/knowledge/esmaul_husna',
      color: Color(0xFFD97706),
    ),
    _KnowledgeItem(
      icon: Icons.record_voice_over_rounded,
      id: 'six_kalima',
      route: '/knowledge/six_kalima',
      color: Color(0xFF0EA5E9),
    ),
    _KnowledgeItem(
      icon: Icons.history_edu_rounded,
      id: 'siyer',
      route: '/knowledge/siyer',
      color: Color(0xFFEC4899),
    ),
    _KnowledgeItem(
      icon: Icons.checklist_rounded,
      id: 'fiqh_basics',
      route: '/knowledge/fiqh_basics',
      color: Color(0xFF16A34A),
    ),
    _KnowledgeItem(
      icon: Icons.translate_rounded,
      id: 'terms',
      route: '/knowledge/terms',
      color: Color(0xFF9333EA),
    ),
    _KnowledgeItem(
      icon: Icons.lightbulb_rounded,
      id: 'interesting_facts',
      route: '/knowledge/interesting_facts',
      color: Color(0xFFF59E0B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: _items
          .map((item) => _KnowledgeCard(item: item, isDark: isDark))
          .toList(),
    );
  }
}

class _KnowledgeItem {
  const _KnowledgeItem({
    required this.icon,
    required this.id,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String id;
  final String route;
  final Color color;
}

class _KnowledgeCard extends StatelessWidget {
  const _KnowledgeCard({required this.item, required this.isDark});

  final _KnowledgeItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final border = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);

    return GestureDetector(
      onTap: () => context.push(item.route),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(item.icon, color: item.color, size: 18),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: item.color.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                AppText.of(context, 'km_${item.id}_t'),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                AppText.of(context, 'km_${item.id}_s'),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: item.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dua Brotherhood Banner
// ─────────────────────────────────────────────────────────────────────────────

class _DuaBrotherhoodBanner extends StatelessWidget {
  const _DuaBrotherhoodBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/dua-brotherhood'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF831843), Color(0xFFBE185D), Color(0xFFDB2777)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBE185D).withValues(alpha: 0.35),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              right: 30,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AppText.of(context, 'communityBadgeUpper'),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppText.of(context, 'duaBrotherhoodTitle'),
                          style: GoogleFonts.notoSerif(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppText.of(context, 'duaBrotherhoodSub'),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.groups_rounded, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          AppText.of(context, 'duaBrotherhoodJoin'),
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white70, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
