import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/settings/app_preferences.dart';
import '../../../../core/theme/app_transitions.dart';
import '../../../../core/widgets/app_glass_card.dart';
import 'notification_schedule_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const List<String> _privacyActionKeys = [
    'privacyActionExport',
    'privacyActionDeleteAccount',
    'privacyActionAnalytics',
    'privacyActionConsent',
  ];

  Future<void> _syncNow(BuildContext context) async {
    await AppPreferences.box.put(AppPreferences.offlineSyncedKey, true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Offline içerik senkronu tamamlandı.')),
    );
  }

  void _openPrivacySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _privacyActionKeys.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    AppText.of(sheetContext, 'privacy'),
                    style: Theme.of(sheetContext).textTheme.titleLarge,
                  ),
                );
              }
              final key = _privacyActionKeys[index - 1];
              return Card(
                child: ListTile(
                  title: Text(AppText.of(sheetContext, key)),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    if (key == 'privacyActionExport') {
                      final data = {
                        'city': await AppPreferences.getSelectedCity(),
                        'country': await AppPreferences.getSelectedCountry(),
                        'locale': await AppPreferences.getLocaleCode(),
                      }.toString();
                      await Clipboard.setData(ClipboardData(text: data));
                    } else if (key == 'privacyActionDeleteAccount') {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Hesap silme talebi oluşturuldu.'),
                        ),
                      );
                    } else if (key == 'privacyActionAnalytics') {
                      final current =
                          AppPreferences.box.get(
                                AppPreferences.analyticsConsentKey,
                                defaultValue: false,
                              )
                              as bool;
                      await AppPreferences.box.put(
                        AppPreferences.analyticsConsentKey,
                        !current,
                      );
                    } else if (key == 'privacyActionConsent') {
                      final current =
                          AppPreferences.box.get(
                                AppPreferences.explicitConsentKey,
                                defaultValue: false,
                              )
                              as bool;
                      await AppPreferences.box.put(
                        AppPreferences.explicitConsentKey,
                        !current,
                      );
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openLanguageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Consumer(
            builder: (context, ref, child) {
              final activeLocale = ref.watch(appLocaleProvider);
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: appLanguageOptions.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        AppText.of(sheetContext, 'languageOptions'),
                        style: Theme.of(sheetContext).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  final option = appLanguageOptions[index - 1];
                  final isSelected = activeLocale == option.locale;
                  return Card(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    elevation: isSelected ? 2 : 0,
                    child: ListTile(
                      title: Text(
                        option.label,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () async {
                        ref.read(appLocaleProvider.notifier).state =
                            option.locale;
                        await AppPreferences.setLocaleCode(
                          option.locale.languageCode,
                        );
                        
                        String newTranslation;
                        switch (option.locale.languageCode) {
                          case 'tr':
                            newTranslation = 'Türkçe';
                            break;
                          case 'en':
                            newTranslation = 'English';
                            break;
                          case 'fr':
                            newTranslation = 'Français';
                            break;
                          case 'ar':
                            newTranslation = 'العربية';
                            break;
                          case 'ur':
                            newTranslation = 'اردو';
                            break;
                          case 'id':
                            newTranslation = 'Bahasa Indonesia';
                            break;
                          case 'de':
                            newTranslation = 'Deutsch';
                            break;
                          default:
                            newTranslation = 'Türkçe';
                        }
                        await AppPreferences.setQuranTranslationLang(newTranslation);
                        await AppPreferences.setDuaTranslationLang(newTranslation);
                        
                        if (sheetContext.mounted) {
                          Navigator.pop(sheetContext);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  void _openContributionSheet(BuildContext context) {
    context.push('/premium');
  }

  Future<void> _openVpsSheet(BuildContext context) async {
    final controller = TextEditingController(
      text: AppPreferences.getVpsBaseUrl(),
    );
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'VPS API Base URL',
                  hintText: 'https://api.example.com',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await AppPreferences.setVpsBaseUrl(controller.text);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('VPS adresi kaydedildi.')),
                    );
                  },
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            floating: true,
            title: Text(
              AppText.of(context, 'profileSettings').toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            centerTitle: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AppGlassCard(
                      baseColor: const Color(0xFF064E3B),
                      opacity: 1.0,
                      padding: const EdgeInsets.all(28),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30,
                            top: -30,
                            child: Icon(
                              Icons.person_rounded,
                              size: 160,
                              color: Colors.white.withValues(alpha: 0.05),
                            ),
                          ),
                          Column(
                            children: [
                              CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.white.withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Oguzhan',
                                style: TextStyle(
                                  fontFamily: 'Noto Serif',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Localizations.localeOf(context).languageCode ==
                                        'tr'
                                    ? 'Ramazan 1445\'ten beri üye'
                                    : 'Member since Ramadan 1445',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13,
                                  color: Color(0xFF95D3BA),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fade(duration: 600.ms)
                    .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),
                const SizedBox(height: 32),
                Text(
                  Localizations.localeOf(context).languageCode == 'tr'
                      ? 'TERCİHLER'
                      : 'PREFERENCES',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    color: scheme.onSurfaceVariant,
                  ),
                ).animate().fade(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 12),
                _SettingsTile(
                      icon: Icons.language_rounded,
                      color: const Color(0xFF0F766E),
                      title: AppText.of(context, 'settingsLanguage'),
                      subtitle: AppText.of(context, 'languageOptions'),
                      isDark: isDark,
                      onTap: () => _openLanguageSheet(context),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 150.ms)
                    .slideX(begin: 0.05, end: 0),
                const SizedBox(height: 12),
                _SettingsTile(
                      icon: Icons.palette_rounded,
                      color: const Color(0xFF7E57C2),
                      title: 'Tema ve Yazi',
                      subtitle: 'Dark mode, renk ve yazi boyutu',
                      isDark: isDark,
                      onTap: () => context.push('/appearance-settings'),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 130.ms)
                    .slideX(begin: 0.05, end: 0),
                const SizedBox(height: 12),
                _SettingsTile(
                      icon: Icons.notifications_active_rounded,
                      color: const Color(0xFFB45309),
                      title: AppText.of(context, 'notification'),
                      subtitle: AppText.of(
                        context,
                        'settingsNotificationSubtitle',
                      ),
                      isDark: isDark,
                      onTap: () => Navigator.of(context).push(
                        AppTransitions.slideFromRight(
                          page: const NotificationSchedulePage(),
                        ),
                      ),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 200.ms)
                    .slideX(begin: 0.05, end: 0),
                const SizedBox(height: 12),
                _SettingsTile(
                      icon: Icons.calculate_rounded,
                      color: const Color(0xFF0F766E),
                      title: 'Zekat Hesaplayici',
                      subtitle: 'Altin, para, ticaret mali',
                      isDark: isDark,
                      onTap: () => context.push('/zakat'),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 220.ms)
                    .slideX(begin: 0.05, end: 0),
                const SizedBox(height: 12),
                _SettingsTile(
                      icon: Icons.card_giftcard_rounded,
                      color: const Color(0xFFEC4899),
                      title: 'Bayram Tebrik Karti',
                      subtitle: 'Olustur ve paylas',
                      isDark: isDark,
                      onTap: () => context.push('/eid-card'),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 240.ms)
                    .slideX(begin: 0.05, end: 0),
                const SizedBox(height: 12),
                _SettingsTile(
                      icon: Icons.wallpaper_rounded,
                      color: const Color(0xFF0EA5E9),
                      title: 'Islami Duvar Kagitlari',
                      subtitle: 'Galeriden sec ve paylas',
                      isDark: isDark,
                      onTap: () => context.push('/wallpapers'),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 250.ms)
                    .slideX(begin: 0.05, end: 0),
                const SizedBox(height: 12),
                _SettingsTile(
                      icon: Icons.volunteer_activism_rounded,
                      color: scheme.tertiary,
                      title: AppText.of(context, 'supportContribution'),
                      subtitle: AppText.of(
                        context,
                        'supportContributionSubtitle',
                      ),
                      isDark: isDark,
                      onTap: () => _openContributionSheet(context),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 250.ms)
                    .slideX(begin: 0.05, end: 0),
                const SizedBox(height: 12),
                _SettingsTile(
                      icon: Icons.workspace_premium_rounded,
                      color: const Color(0xFFD97706),
                      title: 'Premium',
                      subtitle: 'Offline ses, reklamsiz, tum kari, istatistik',
                      isDark: isDark,
                      onTap: () => context.push('/premium'),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 280.ms)
                    .slideX(begin: 0.05, end: 0),
                const SizedBox(height: 12),
                _SettingsTile(
                      icon: Icons.query_stats_rounded,
                      color: const Color(0xFF10B981),
                      title: 'Gelismis Istatistikler',
                      subtitle: 'Premium rapor ekrani',
                      isDark: isDark,
                      onTap: () => context.push('/advanced-stats'),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 290.ms)
                    .slideX(begin: 0.05, end: 0),
                const SizedBox(height: 12),
                _SettingsTile(
                      icon: Icons.privacy_tip_rounded,
                      color: const Color(0xFF6366F1),
                      title: AppText.of(context, 'privacy'),
                      subtitle: AppText.of(context, 'settingsPrivacySubtitle'),
                      isDark: isDark,
                      onTap: () => _openPrivacySheet(context),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 300.ms)
                    .slideX(begin: 0.05, end: 0),
                const SizedBox(height: 12),
                _SettingsTile(
                      icon: Icons.cloud_done_rounded,
                      color: const Color(0xFF0EA5E9),
                      title: 'VPS ve Offline Senkron',
                      subtitle: 'Sunucu URL ayarla ve senkron başlat',
                      isDark: isDark,
                      onTap: () => _openVpsSheet(context),
                    )
                    .animate()
                    .fade(duration: 400.ms, delay: 340.ms)
                    .slideX(begin: 0.05, end: 0),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _syncNow(context),
                    icon: const Icon(Icons.sync_rounded),
                    label: const Text('Şimdi Senkronla'),
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF191C1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
