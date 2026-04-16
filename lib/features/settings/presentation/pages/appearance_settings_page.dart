import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/ui_settings_provider.dart';

class AppearanceSettingsPage extends ConsumerWidget {
  const AppearanceSettingsPage({super.key});

  static const _seeds = <({Color color, String label})>[
    (color: Color(0xFF006D44), label: 'Yeşil'),
    (color: Color(0xFF0B57D0), label: 'Mavi'),
    (color: Color(0xFF7E57C2), label: 'Mor'),
    (color: Color(0xFFC2185B), label: 'Pembe'),
    (color: Color(0xFFD97706), label: 'Turuncu'),
    (color: Color(0xFF0369A1), label: 'Lacivert'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final ui = ref.watch(uiSettingsProvider);
    final notifier = ref.read(uiSettingsProvider.notifier);

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
              'Görünüm ve Yazı',
              style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Tema modu
                _SectionCard(
                  isDark: isDark,
                  title: 'Tema Modu',
                  icon: Icons.brightness_6_rounded,
                  iconColor: const Color(0xFFD97706),
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Sistem'),
                        icon: Icon(Icons.phone_android_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Aydınlık'),
                        icon: Icon(Icons.light_mode_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Karanlık'),
                        icon: Icon(Icons.dark_mode_rounded, size: 16),
                      ),
                    ],
                    selected: {ui.themeMode},
                    onSelectionChanged: (modes) => notifier.setThemeMode(modes.first),
                    style: ButtonStyle(
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Tema rengi
                _SectionCard(
                  isDark: isDark,
                  title: 'Tema Rengi',
                  icon: Icons.palette_rounded,
                  iconColor: scheme.primary,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _seeds.map((s) {
                      final selected = ui.seedColor.toARGB32() == s.color.toARGB32();
                      return GestureDetector(
                        onTap: () => notifier.setSeedColor(s.color),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: s.color,
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: isDark ? Colors.white : Colors.black,
                                        width: 3,
                                      )
                                    : null,
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: s.color.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: selected
                                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.label,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 10,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Yazı boyutu
                _SectionCard(
                  isDark: isDark,
                  title: 'Yazı Boyutu',
                  icon: Icons.text_fields_rounded,
                  iconColor: const Color(0xFF0369A1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Küçük',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '%${(ui.textScale * 100).round()}',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                          const Text(
                            'Büyük',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        min: 0.85,
                        max: 1.5,
                        divisions: 13,
                        value: ui.textScale,
                        onChanged: notifier.setTextScale,
                        onChangeEnd: notifier.setTextScale,
                      ),
                      Text(
                        'Örnek metin boyutu',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14 * ui.textScale,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.isDark,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  final bool isDark;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.notoSerif(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
