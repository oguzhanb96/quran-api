import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../localization/app_language.dart';
import '../settings/app_preferences.dart';

class AppSidePanel {
  static const _navBarHeight = 106.0;

  static const _languages = [
    (code: 'tr', label: 'Türkçe', flag: '🇹🇷'),
    (code: 'en', label: 'English', flag: '🇬🇧'),
    (code: 'ar', label: 'العربية', flag: '🇸🇦'),
    (code: 'ur', label: 'اردو', flag: '🇵🇰'),
    (code: 'id', label: 'Bahasa Indonesia', flag: '🇮🇩'),
    (code: 'fa', label: 'فارسی', flag: '🇮🇷'),
    (code: 'fr', label: 'Français', flag: '🇫🇷'),
    (code: 'de', label: 'Deutsch', flag: '🇩🇪'),
    (code: 'es', label: 'Español', flag: '🇪🇸'),
    (code: 'ru', label: 'Русский', flag: '🇷🇺'),
    (code: 'hi', label: 'हिन्दी', flag: '🇮🇳'),
    (code: 'bn', label: 'বাংলা', flag: '🇧🇩'),
    (code: 'ms', label: 'Melayu', flag: '🇲🇾'),
    (code: 'sw', label: 'Kiswahili', flag: '🇰🇪'),
    (code: 'ta', label: 'தமிழ்', flag: '🇱🇰'),
    (code: 'uz', label: 'Oʻzbekcha', flag: '🇺🇿'),
    (code: 'az', label: 'Azərbaycan', flag: '🇦🇿'),
    (code: 'ha', label: 'Hausa', flag: '🇳🇬'),
    (code: 'fil', label: 'Filipino', flag: '🇵🇭'),
    (code: 'so', label: 'Soomaali', flag: '🇸🇴'),
    (code: 'ps', label: 'پښتو', flag: '🇦🇫'),
    (code: 'ml', label: 'മലയാളം', flag: '🇮🇳'),
  ];

  static Future<void> open(BuildContext context) async {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: false,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        final safeBottom = MediaQuery.of(ctx).padding.bottom;
        final extraPadding = _navBarHeight + safeBottom + bottomInset;
        final maxH = MediaQuery.of(ctx).size.height * 0.75;

        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    Text(
                      AppText.of(ctx, 'menuTitle'),
                      style: GoogleFonts.notoSerif(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, extraPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Premium
                      ListTile(
                        leading: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF7C3AED)),
                        title: Text(
                          AppText.of(ctx, 'sidePremiumTitle'),
                          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          AppText.of(ctx, 'sidePremiumSubtitle'),
                          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          context.push('/premium');
                        },
                      ),
                      const Divider(),

                      // Dil seçimi
                      _LanguageSelector(
                        languages: _languages,
                        scheme: scheme,
                        isDark: isDark,
                        onClose: () => Navigator.pop(ctx),
                      ),
                      const Divider(),

                      // Değerlendir
                      ListTile(
                        leading: Icon(Icons.star_border_rounded, color: scheme.primary),
                        title: Text(
                          AppText.of(ctx, 'sideRateApp'),
                          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
                        ),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final url = Uri.parse('https://play.google.com/store/apps/details?id=com.hidaya.quran');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          } else {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Uygulama mağazası açılamadı.'),
                                backgroundColor: const Color(0xFF064E3B),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.share_rounded, color: scheme.primary),
                        title: Text(
                          AppText.of(ctx, 'sideShareApp'),
                          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          SharePlus.instance.share(
                            ShareParams(
                              text: AppText.of(
                                context,
                                'sideShareText',
                                {'url': 'https://hidaya.app/download'},
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppText.of(ctx, 'sideFooterTagline'),
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: scheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageSelector extends ConsumerWidget {
  const _LanguageSelector({
    required this.languages,
    required this.scheme,
    required this.isDark,
    required this.onClose,
  });

  final List<({String code, String label, String flag})> languages;
  final ColorScheme scheme;
  final bool isDark;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(appLocaleProvider);

    return ExpansionTile(
      leading: Icon(Icons.language_rounded, color: scheme.primary),
      title: Text(
        AppText.of(context, 'changeLanguage'),
        style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        languages.firstWhere(
          (l) => l.code == currentLocale.languageCode,
          orElse: () => (code: 'tr', label: 'Türkçe', flag: '🇹🇷'),
        ).label,
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 12,
          color: scheme.primary,
        ),
      ),
      children: [
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: languages.length,
            itemBuilder: (context, i) {
              final lang = languages[i];
              final isSelected = currentLocale.languageCode == lang.code;
              return ListTile(
                dense: true,
                leading: Text(lang.flag, style: const TextStyle(fontSize: 20)),
                title: Text(
                  lang.label,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? scheme.primary : scheme.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_rounded, color: scheme.primary, size: 18)
                    : null,
                onTap: () async {
                  ref.read(appLocaleProvider.notifier).state = Locale(lang.code);
                  await AppPreferences.setLocaleCode(lang.code);
                  onClose();
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
