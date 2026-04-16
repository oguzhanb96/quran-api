import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/settings/app_preferences.dart';
import '../../../../core/widgets/app_glass_card.dart';

class DhikrCounterPage extends StatefulWidget {
  const DhikrCounterPage({super.key});

  @override
  State<DhikrCounterPage> createState() => _DhikrCounterPageState();
}

class _DhikrCounterPageState extends State<DhikrCounterPage>
    with SingleTickerProviderStateMixin {
  int _count = 0;
  int _target = 33;
  String _dhikr = 'Subhanallah';
  final _customController = TextEditingController();

  late AnimationController _punchController;

  @override
  void initState() {
    super.initState();
    _punchController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
  }

  @override
  void dispose() {
    _customController.dispose();
    _punchController.dispose();
    super.dispose();
  }

  void _increment() {
    HapticFeedback.lightImpact();
    AppPreferences.incrementDhikrStats();
    setState(() {
      _count++;
      if (_count == _target) {
        HapticFeedback.heavyImpact();
      }
    });
    _punchController.forward(from: 0.0);
  }

  Widget _buildGamifiedCounter() {
    final progress = (_target == 0) ? 0.0 : (_count / _target).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        AppGlassCard(
          shadowColor: Colors.transparent,
          baseColor: isDark ? scheme.surfaceContainerLow : Colors.white,
          opacity: isDark ? 0.3 : 0.8,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Text(
                _dhikr,
                style: GoogleFonts.notoSerif(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ).animate(key: ValueKey(_dhikr)).fade().slideY(
                  begin: 0.2, end: 0, duration: 400.ms),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _increment,
                child: AnimatedBuilder(
                  animation: _punchController,
                  builder: (context, child) {
                    final scale = 1.0 - (_punchController.value * 0.05);
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Transform.rotate(
                          angle: -math.pi / 2,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 14,
                            backgroundColor: scheme.primary.withValues(alpha: 0.08),
                            color: scheme.primary,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                      ),
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              scheme.primary.withValues(alpha: 0.85),
                              scheme.secondary.withValues(alpha: 0.85),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$_count',
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Hedef: $_target',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ).animate().fade(duration: 500.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 24),
        ValueListenableBuilder(
          valueListenable: AppPreferences.box.listenable(keys: [
            AppPreferences.dhikrStreakKey,
            AppPreferences.dhikrMonthlyTotalKey,
          ]),
          builder: (context, box, _) {
            final streak = AppPreferences.getDhikrStreak();
            final monthlyTotal = AppPreferences.getDhikrMonthlyTotal();
            return Row(
              children: [
                Expanded(
                  child: AppGlassCard(
                    shadowColor: Colors.transparent,
                    baseColor: isDark ? scheme.surfaceContainerLow : Colors.white,
                    opacity: isDark ? 0.3 : 0.8,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            color: Colors.orange[400], size: 32),
                        const SizedBox(height: 8),
                        Text(AppText.of(context, 'streak'),
                            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: scheme.onSurfaceVariant)),
                        Text('$streak ${AppText.of(context, 'days')}',
                            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                      ],
                    ),
                  ).animate().fade(delay: 200.ms).scale(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppGlassCard(
                    shadowColor: Colors.transparent,
                    baseColor: isDark ? scheme.surfaceContainerLow : Colors.white,
                    opacity: isDark ? 0.3 : 0.8,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.star_rounded,
                            color: Colors.amber[400], size: 32),
                        const SizedBox(height: 8),
                        Text(AppText.of(context, 'monthlyTotal'),
                            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: scheme.onSurfaceVariant)),
                        Text('$monthlyTotal',
                            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.bold, color: scheme.onSurface)),
                      ],
                    ),
                  ).animate().fade(delay: 300.ms).scale(),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPresets() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _presetChip('Subhanallah', 33),
        _presetChip('Elhamdülillah', 33),
        _presetChip('Allahu Ekber', 34),
        _presetChip('Salavat', 100),
      ],
    );
  }

  Widget _presetChip(String text, int target) {
    bool selected = _target == target && _dhikr == text;
    return ChoiceChip(
      label: Text(text),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _dhikr = text;
          _target = target;
          _count = 0;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              AppText.of(context, 'dhikrCounter'),
              style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () {
                  setState(() => _count = 0);
                  HapticFeedback.mediumImpact();
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildGamifiedCounter(),
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Hızlı Seçimler',
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildPresets().animate().fade(delay: 400.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 32),
                AppGlassCard(
                  shadowColor: Colors.transparent,
                  baseColor: isDark ? scheme.surfaceContainerLow : Colors.white,
                  opacity: isDark ? 0.3 : 0.8,
                  padding: const EdgeInsets.all(16),
                  borderRadius: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              setState(() {
                                _dhikr = val.trim();
                                _target = 100;
                                _count = 0;
                              });
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Kendi zikrini yaz...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: TextStyle(fontFamily: 'Plus Jakarta Sans'),
                          ),
                          style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.check_circle_rounded, color: scheme.primary),
                        onPressed: () {
                          if (_customController.text.trim().isNotEmpty) {
                            setState(() {
                              _dhikr = _customController.text.trim();
                              _target = 100;
                              _count = 0;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ).animate().fade(delay: 500.ms).slideY(begin: 0.1, end: 0),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
