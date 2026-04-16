import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_language.dart';

/// Tüm uygulamada görünen floating nav bar shell'i.
/// GoRouter ShellRoute ile kullanılır.
class AppNavShell extends StatefulWidget {
  const AppNavShell({required this.child, super.key});

  final Widget child;

  @override
  State<AppNavShell> createState() => _AppNavShellState();
}

class _AppNavShellState extends State<AppNavShell> {
  static const _tabs = [
    (path: '/home', icon: Icons.home_rounded),
    (path: '/quran', icon: Icons.auto_stories_rounded),
    (path: '/duas', icon: Icons.menu_book_rounded),
    (path: '/qibla', icon: Icons.explore_rounded),
    (path: '/center', icon: Icons.grid_view_rounded),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/quran')) return 1;
    if (location.startsWith('/duas')) return 2;
    if (location.startsWith('/qibla')) return 3;
    if (location.startsWith('/center')) return 4;
    if (location.startsWith('/home')) return 0;
    // Alt sayfalar için en yakın tab'ı bul
    if (location.startsWith('/prayer')) return 0;
    if (location.startsWith('/dhikr')) return 4;
    if (location.startsWith('/calendar')) return 4;
    if (location.startsWith('/goals')) return 4;
    if (location.startsWith('/knowledge')) return 4;
    if (location.startsWith('/dua-brotherhood')) return 4;
    if (location.startsWith('/settings')) return 0;
    if (location.startsWith('/profile')) return 0;
    if (location.startsWith('/favorites')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF020617) : const Color(0xFFFBF9F5);
    final selectedIdx = _selectedIndex(context);
    final navLabels = [
      AppText.of(context, 'navHome'),
      AppText.of(context, 'quran'),
      AppText.of(context, 'dua'),
      AppText.of(context, 'qibla'),
      AppText.of(context, 'center'),
    ];

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: _FloatingNavBar(
              selectedIndex: selectedIdx,
              isDark: isDark,
              labels: navLabels,
              onTap: (index) => context.go(_tabs[index].path),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.isDark,
    required this.labels,
    required this.onTap,
  });

  final int selectedIndex;
  final bool isDark;
  final List<String> labels;
  final ValueChanged<int> onTap;

  static const _icons = [
    Icons.home_rounded,
    Icons.auto_stories_rounded,
    Icons.menu_book_rounded,
    Icons.explore_rounded,
    Icons.grid_view_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _icons.length,
              (i) => _NavItem(
                icon: _icons[i],
                label: labels[i],
                isSelected: selectedIndex == i,
                onTap: () => onTap(i),
                iconSize: 20,
                labelSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.iconSize = 22,
    this.labelSize = 11,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double iconSize;
  final double labelSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? scheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isSelected ? scheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : scheme.onSurfaceVariant,
                  size: iconSize,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
                  fontFamily: 'Plus Jakarta Sans',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
