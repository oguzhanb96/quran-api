import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_transitions.dart';
import '../core/widgets/app_nav_shell.dart';
import '../features/calendar/presentation/pages/islamic_calendar_page.dart';
import '../features/dhikr/presentation/pages/dhikr_counter_page.dart';
import '../features/dua_brotherhood/presentation/pages/dua_chain_detail_page.dart';
import '../features/dua_brotherhood/presentation/pages/dua_chains_page.dart';
import '../features/home/presentation/home_shell_page.dart';
import '../features/home/presentation/pages/favorites_page.dart';
import '../features/home/presentation/pages/profile_page.dart';
import '../features/home/presentation/pages/reading_goals_page.dart';
import '../features/islamic_knowledge/presentation/pages/knowledge_detail_page.dart';
import '../features/islamic_knowledge/presentation/pages/knowledge_hub_page.dart';
import '../features/islamic_knowledge/presentation/pages/knowledge_list_page.dart';
import '../features/onboarding/presentation/pages/launch_gate_page.dart';
import '../features/onboarding/presentation/pages/setup_preferences_page.dart';
import '../features/onboarding/presentation/pages/welcome_page.dart';
import '../features/prayer_times/presentation/pages/prayer_times_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/auth/presentation/pages/auth_page.dart';
import '../features/settings/presentation/pages/appearance_settings_page.dart';
import '../features/settings/presentation/pages/advanced_stats_page.dart';
import '../features/settings/presentation/pages/eid_card_page.dart';
import '../features/settings/presentation/pages/islamic_wallpapers_page.dart';
import '../features/settings/presentation/pages/notification_preferences_page.dart';
import '../features/settings/presentation/pages/notification_schedule_page.dart';
import '../features/settings/presentation/pages/premium_page.dart';
import '../features/settings/presentation/pages/privacy_policy_page.dart';
import '../features/settings/presentation/pages/support_page.dart';
import '../features/settings/presentation/pages/zakat_calculator_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // ── Onboarding (nav bar yok) ──────────────────────────────────────────
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LaunchGatePage(),
          transitionsBuilder: AppTransitions.goRouterFadeSlide,
          transitionDuration: const Duration(milliseconds: 460),
        ),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WelcomePage(),
          transitionsBuilder: AppTransitions.goRouterFadeSlide,
          transitionDuration: const Duration(milliseconds: 460),
        ),
      ),
      GoRoute(
        path: '/setup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SetupPreferencesPage(),
          transitionsBuilder: AppTransitions.goRouterFadeSlide,
          transitionDuration: const Duration(milliseconds: 460),
        ),
      ),

      // ── Ana uygulama (nav bar göster) ─────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppNavShell(child: child),
        routes: [
          // 5 ana tab
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: HomeShellPage(location: state.uri.toString()),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/quran',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: HomeShellPage(location: state.uri.toString()),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/duas',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: HomeShellPage(location: state.uri.toString()),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/qibla',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: HomeShellPage(location: state.uri.toString()),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/center',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: HomeShellPage(location: state.uri.toString()),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),

          // Alt sayfalar (nav bar görünür)
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfilePage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SettingsPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/prayer',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const PrayerTimesPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/dhikr',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DhikrCounterPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const IslamicCalendarPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/goals',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ReadingGoalsPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const FavoritesPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/knowledge',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const KnowledgeHubPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/knowledge/:moduleId',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: KnowledgeListPage(
                moduleId: state.pathParameters['moduleId'] ?? '',
              ),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/knowledge/:moduleId/:itemId',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: KnowledgeDetailPage(
                moduleId: state.pathParameters['moduleId'] ?? '',
                itemId: state.pathParameters['itemId'] ?? '',
              ),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/dua-brotherhood',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const DuaChainsPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/dua-brotherhood/:chainId',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: DuaChainDetailPage(
                chainId: state.pathParameters['chainId'] ?? '',
              ),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/appearance-settings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AppearanceSettingsPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/zakat',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ZakatCalculatorPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/eid-card',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const EidCardPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/wallpapers',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const IslamicWallpapersPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/premium',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const PremiumPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/auth',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AuthPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/advanced-stats',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const AdvancedStatsPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/notification-preferences',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const NotificationPreferencesPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/notification-schedule',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const NotificationSchedulePage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/support',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const SupportPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
          GoRoute(
            path: '/privacy-policy',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const PrivacyPolicyPage(),
              transitionsBuilder: AppTransitions.goRouterFadeSlide,
              transitionDuration: const Duration(milliseconds: 460),
            ),
          ),
        ],
      ),
    ],
  );
});
