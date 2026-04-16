import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../prayer_name_localization.dart';
import '../viewmodels/prayer_times_viewmodel.dart';

class PrayerTimesPage extends ConsumerStatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  ConsumerState<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends ConsumerState<PrayerTimesPage> {
  Timer? _ticker;
  DateTime _now = DateTime.now();

  static const _prayerIcons = <String, IconData>{
    'İmsak': Icons.wb_twilight_rounded,
    'Güneş': Icons.wb_sunny_rounded,
    'Öğle': Icons.light_mode_rounded,
    'İkindi': Icons.wb_cloudy_rounded,
    'Akşam': Icons.nights_stay_rounded,
    'Yatsı': Icons.bedtime_rounded,
  };

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

  String _formatCountdown(Duration diff) {
    if (diff.isNegative) return '';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (h > 0) {
      return '$h sa ${m.toString().padLeft(2, '0')} dk ${s.toString().padLeft(2, '0')} sn';
    }
    if (m > 0) {
      return '$m dk ${s.toString().padLeft(2, '0')} sn';
    }
    return '$s sn';
  }

  String _formatCountdownShort(Duration diff) {
    if (diff.isNegative) return '';
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    if (h > 0) return '$h sa $m dk';
    if (m > 0) return '$m dk $s sn';
    return '$s sn';
  }

  Future<void> _openManualLocationDialog(BuildContext context) async {
    final cityController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          AppText.of(ctx, 'enterCity'),
          style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: cityController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: AppText.of(ctx, 'cityName'),
            prefixIcon: const Icon(Icons.location_city_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onSubmitted: (v) {
            final city = v.trim();
            if (city.isNotEmpty) Navigator.pop(ctx, city);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppText.of(ctx, 'cancel')),
          ),
          FilledButton(
            onPressed: () {
              final city = cityController.text.trim();
              if (city.isEmpty) return;
              Navigator.pop(ctx, city);
            },
            child: Text(AppText.of(ctx, 'save')),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;

    final ok = await ref.read(prayerTimesProvider.notifier).setManualCity(result);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppText.of(context, 'cityNotFound'))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$result için namaz vakitleri güncellendi'),
          backgroundColor: const Color(0xFF064E3B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prayerTimes = ref.watch(prayerTimesProvider);
    final localeCode = ref.watch(appLocaleCodeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          AppText.of(context, 'prayer'),
          style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(prayerTimesProvider.notifier).refresh(),
        child: prayerTimes.when(
          data: (state) {
            final timeFormat = DateFormat('HH:mm', localeCode);

            // Bir sonraki namaz vaktini bul
            final upcoming = state.times.firstWhere(
              (item) => item.time.isAfter(_now),
              orElse: () => state.times.first,
            );
            final diff = upcoming.time.difference(_now);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // Hero kart — bir sonraki namaz + canlı geri sayım
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: AppGlassCard(
                      baseColor: const Color(0xFF064E3B),
                      opacity: 1.0,
                      padding: const EdgeInsets.all(28),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30,
                            top: -30,
                            child: Icon(
                              Icons.mosque_rounded,
                              size: 180,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Konum satırı
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: Color(0xFFFFDCC3),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      state.locationLabel,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFFDCC3),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Saat göstergesi
                                  Text(
                                    DateFormat('HH:mm:ss').format(_now),
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF95D3BA),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'SONRAKI NAMAZ',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.0,
                                  color: Color(0xFF95D3BA),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                localizedPrayerName(context, upcoming.name),
                                style: GoogleFonts.notoSerif(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeFormat.format(upcoming.time),
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Canlı geri sayım
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.timer_outlined,
                                      size: 14,
                                      color: Color(0xFF95D3BA),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      diff.isNegative
                                          ? 'Vakit geçti'
                                          : _formatCountdown(diff),
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF95D3BA),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton.tonalIcon(
                                      onPressed: () => ref
                                          .read(prayerTimesProvider.notifier)
                                          .refresh(),
                                      icon: const Icon(
                                        Icons.refresh_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        AppText.of(context, 'refreshPrayerTimes'),
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () =>
                                          _openManualLocationDialog(context),
                                      icon: const Icon(
                                        Icons.edit_location_alt_rounded,
                                        size: 16,
                                      ),
                                      label: Text(
                                        AppText.of(context, 'manualLocation'),
                                        style: const TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(0xFFD97706),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fade(duration: 600.ms).slideY(
                          begin: 0.1,
                          end: 0,
                          curve: Curves.easeOutQuad,
                        ),
                  ),
                ),

                // Namaz vakitleri listesi
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = state.times[index];
                        final isPast = item.time.isBefore(_now);
                        final isNext = item.name == upcoming.name;
                        final icon =
                            _prayerIcons[item.name] ?? Icons.access_time_rounded;
                        final itemDiff = item.time.difference(_now);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppGlassCard(
                            baseColor: isNext
                                ? const Color(0xFF064E3B)
                                : (isDark
                                    ? const Color(0xFF0F172A)
                                    : Colors.white),
                            opacity: isNext ? 1.0 : (isDark ? 0.5 : 0.9),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isNext
                                        ? Colors.white.withValues(alpha: 0.15)
                                        : (isPast
                                            ? (isDark
                                                ? Colors.white12
                                                : Colors.black12)
                                            : const Color(0xFF064E3B)
                                                .withValues(alpha: 0.1)),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    size: 22,
                                    color: isNext
                                        ? const Color(0xFFFFDCC3)
                                        : (isPast
                                            ? (isDark
                                                ? Colors.white38
                                                : Colors.black26)
                                            : const Color(0xFF064E3B)),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localizedPrayerName(context, item.name),
                                        style: GoogleFonts.notoSerif(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isNext
                                              ? Colors.white
                                              : (isPast
                                                  ? (isDark
                                                      ? Colors.white38
                                                      : Colors.black38)
                                                  : (isDark
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF064E3B,
                                                        ))),
                                        ),
                                      ),
                                      if (isNext && !itemDiff.isNegative)
                                        Text(
                                          _formatCountdownShort(itemDiff),
                                          style: const TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 12,
                                            color: Color(0xFF95D3BA),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      if (isPast && !isNext)
                                        Text(
                                          'Geçti',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.white24
                                                : Colors.black26,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  timeFormat.format(item.time),
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                    color: isNext
                                        ? Colors.white
                                        : (isPast
                                            ? (isDark
                                                ? Colors.white38
                                                : Colors.black26)
                                            : (isDark
                                                ? Colors.white
                                                : const Color(0xFF064E3B))),
                                  ),
                                ),
                                if (isNext) ...[
                                  const SizedBox(width: 12),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Color(0xFF95D3BA),
                                  ),
                                ],
                              ],
                            ),
                          ).animate().fade(
                                duration: 400.ms,
                                delay: Duration(milliseconds: index * 60),
                              ).slideY(
                                begin: 0.1,
                                end: 0,
                                curve: Curves.easeOutQuad,
                              ),
                        );
                      },
                      childCount: state.times.length,
                    ),
                  ),
                ),
              ],
            );
          },
          error: (error, _) => CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        size: 64,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppText.of(context, 'loadError'),
                        style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.read(prayerTimesProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
