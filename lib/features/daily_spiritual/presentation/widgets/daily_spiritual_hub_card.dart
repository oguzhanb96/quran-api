import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/theme/app_transitions.dart';
import '../../../../core/widgets/app_glass_card.dart';
import '../../../dhikr/presentation/pages/dhikr_counter_page.dart';
import '../../../dua/presentation/pages/dua_library_page.dart';

class DailySpiritualHubCard extends StatelessWidget {
  const DailySpiritualHubCard({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = Localizations.localeOf(context).languageCode == 'tr'
        ? 'GÜNÜN SÖZÜ'
        : 'VERSE OF THE DAY';
    final verse = Localizations.localeOf(context).languageCode == 'tr'
        ? '"Kalpler ancak Allah\'ı anmakla huzur bulur."'
        : '"Verily, in the remembrance of Allah do hearts find rest."';
    final info = Localizations.localeOf(context).languageCode == 'tr'
        ? 'Rad Suresi, 28. Ayet'
        : "Surah Ar-Ra'd, 28";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppGlassCard(
          baseColor: const Color(0xFF064E3B),
          opacity: 1.0,
          padding: const EdgeInsets.all(28),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                bottom: -40,
                child: Icon(Icons.format_quote_rounded, size: 200, color: Colors.white.withValues(alpha: 0.05)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_rounded, color: Color(0xFFD97706), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: Color(0xFFFFDCC3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    verse,
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      info,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF95D3BA),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fade(duration: 600.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
        const SizedBox(height: 20),
        Text(
          Localizations.localeOf(context).languageCode == 'tr' ? 'MANEVİ ARAÇLAR' : 'SPIRITUAL TOOLS',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            color: scheme.onSurfaceVariant,
          ),
        ).animate().fade(duration: 400.ms, delay: 100.ms),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HubToolCard(
                icon: Icons.grain_rounded,
                title: AppText.of(context, 'dhikrCounter'),
                color: const Color(0xFF0F766E),
                isDark: isDark,
                onTap: () => Navigator.of(context).push(
                  AppTransitions.fadeSlide(page: const DhikrCounterPage()),
                ),
              ).animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1, end: 0),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _HubToolCard(
                icon: Icons.auto_awesome_rounded,
                title: AppText.of(context, 'duaLibrary'),
                color: const Color(0xFFB45309),
                isDark: isDark,
                onTap: () => Navigator.of(context).push(
                  AppTransitions.fadeSlide(page: const DuaLibraryPage()),
                ),
              ).animate().fade(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1, end: 0),
            ),
          ],
        ),
      ],
    );
  }
}

class _HubToolCard extends StatelessWidget {
  const _HubToolCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF191C1A),
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.arrow_forward_rounded, size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
