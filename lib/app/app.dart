import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localization/app_language.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/ui_settings_provider.dart';
import 'router.dart';

class QuranCompanionApp extends ConsumerWidget {
  const QuranCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(appLocaleProvider);
    final ui = ref.watch(uiSettingsProvider);
    return MaterialApp.router(
      title: 'Hidaya: Prayer Times, Quran & Duas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightFromSeed(ui.seedColor),
      darkTheme: AppTheme.darkFromSeed(ui.seedColor),
      themeMode: ui.themeMode,
      routerConfig: router,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        for (final s in supportedLocales) {
          if (s.languageCode == locale.languageCode) {
            return s;
          }
        }
        return locale;
      },
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(ui.textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
