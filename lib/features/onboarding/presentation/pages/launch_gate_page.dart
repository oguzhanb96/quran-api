import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/settings/app_preferences.dart';
import '../../../../core/splash/splash_screen.dart';

class LaunchGatePage extends ConsumerStatefulWidget {
  const LaunchGatePage({super.key});

  @override
  ConsumerState<LaunchGatePage> createState() => _LaunchGatePageState();
}

class _LaunchGatePageState extends ConsumerState<LaunchGatePage> {
  static const Duration _minSplash = Duration(milliseconds: 800);
  static const Duration _maxSplash = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runGate());
  }

  Future<void> _runGate() async {
    final sw = Stopwatch()..start();
    var done = false;

    try {
      done = await Future<bool>(() async {
        final savedLocale = await AppPreferences.getLocaleCode();
        if (!mounted) return false;
        if (savedLocale != null) {
          ref.read(appLocaleProvider.notifier).state = Locale(savedLocale);
        }
        return await AppPreferences.isOnboardingDone();
      }).timeout(
        _maxSplash,
        onTimeout: () {
          final code = AppPreferences.readLocaleCodeSync();
          if (code != null && mounted) {
            ref.read(appLocaleProvider.notifier).state = Locale(code);
          }
          return AppPreferences.readOnboardingDoneSync();
        },
      );
    } catch (_) {
      done = AppPreferences.readOnboardingDoneSync();
    }

    final elapsed = sw.elapsed;
    final target = const Duration(seconds: 3);
    if (elapsed < target) {
      await Future<void>.delayed(target - elapsed);
    }

    if (!mounted) return;
    context.go(done ? '/home' : '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
