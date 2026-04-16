import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/settings/app_preferences.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  Map<String, bool> _onTime = {};
  Map<String, bool> _before = {};
  bool _dailyContent = true;
  bool _duaBrotherhood = true;
  bool _islamicEvents = true;
  bool _loading = true;

  static const _prayerLabels = <String, String>{
    'imsak': 'İmsak',
    'gunes': 'Güneş',
    'ogle': 'Öğle',
    'ikindi': 'İkindi',
    'aksam': 'Akşam',
    'yatsi': 'Yatsı',
  };

  static const _prayerIcons = <String, IconData>{
    'imsak': Icons.wb_twilight_rounded,
    'gunes': Icons.wb_sunny_rounded,
    'ogle': Icons.light_mode_rounded,
    'ikindi': Icons.wb_cloudy_rounded,
    'aksam': Icons.nights_stay_rounded,
    'yatsi': Icons.bedtime_rounded,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final onTime = await AppPreferences.loadOnTimeToggles();
    final before = await AppPreferences.loadBeforeToggles();
    final box = AppPreferences.box;
    if (!mounted) return;
    setState(() {
      _onTime = onTime;
      _before = before;
      _dailyContent = box.get('notify_daily_content', defaultValue: true) as bool;
      _duaBrotherhood = box.get('notify_dua_brotherhood', defaultValue: true) as bool;
      _islamicEvents = box.get('notify_islamic_events', defaultValue: true) as bool;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await AppPreferences.saveToggles(onTime: _onTime, before: _before);
    final box = AppPreferences.box;
    await box.put('notify_daily_content', _dailyContent);
    await box.put('notify_dua_brotherhood', _duaBrotherhood);
    await box.put('notify_islamic_events', _islamicEvents);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Bildirim tercihleri kaydedildi.',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _requestPermission() async {
    await NotificationService().requestPermissions();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Bildirim izni istendi.',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
              'Bildirim Tercihleri',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: _save,
                child: Text(
                  'Kaydet',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── İzin banner ──────────────────────────────────────────────
                _PermissionBanner(onRequest: _requestPermission, isDark: isDark, scheme: scheme)
                    .animate()
                    .fade(duration: 400.ms)
                    .slideY(begin: 0.06, end: 0),

                const SizedBox(height: 20),

                // ── Namaz vakitleri ───────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.mosque_rounded,
                  title: 'Namaz Vakti Bildirimleri',
                  color: const Color(0xFF064E3B),
                ).animate().fade(duration: 400.ms, delay: 60.ms),

                const SizedBox(height: 10),

                _InfoCard(
                  isDark: isDark,
                  child: Column(
                    children: AppPreferences.prayerKeys.asMap().entries.map((entry) {
                      final key = entry.value;
                      final label = _prayerLabels[key] ?? key;
                      final icon = _prayerIcons[key] ?? Icons.access_time_rounded;
                      final isLast = entry.key == AppPreferences.prayerKeys.length - 1;
                      return Column(
                        children: [
                          _PrayerNotifRow(
                            icon: icon,
                            label: label,
                            onTime: _onTime[key] ?? true,
                            before: _before[key] ?? true,
                            onTimeChanged: (v) => setState(() => _onTime[key] = v),
                            beforeChanged: (v) => setState(() => _before[key] = v),
                            scheme: scheme,
                          ),
                          if (!isLast) Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                        ],
                      );
                    }).toList(),
                  ),
                ).animate().fade(duration: 400.ms, delay: 100.ms).slideY(begin: 0.06, end: 0),

                const SizedBox(height: 20),

                // ── Uygulama bildirimleri ─────────────────────────────────────
                _SectionHeader(
                  icon: Icons.notifications_rounded,
                  title: 'Uygulama Bildirimleri',
                  color: const Color(0xFF0EA5E9),
                ).animate().fade(duration: 400.ms, delay: 140.ms),

                const SizedBox(height: 10),

                _InfoCard(
                  isDark: isDark,
                  child: Column(
                    children: [
                      _AppNotifRow(
                        icon: Icons.auto_stories_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                        title: 'Günlük Manevi İçerik',
                        subtitle: 'Günlük ayet, hadis ve ilham bildirimi',
                        value: _dailyContent,
                        onChanged: (v) => setState(() => _dailyContent = v),
                        scheme: scheme,
                        showDivider: true,
                      ),
                      _AppNotifRow(
                        icon: Icons.groups_rounded,
                        iconColor: const Color(0xFFEC4899),
                        title: 'Dua Kardeşliği',
                        subtitle: 'Zincir tamamlandı ve yeni zincir bildirimleri',
                        value: _duaBrotherhood,
                        onChanged: (v) => setState(() => _duaBrotherhood = v),
                        scheme: scheme,
                        showDivider: true,
                      ),
                      _AppNotifRow(
                        icon: Icons.event_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'İslami Etkinlikler',
                        subtitle: 'Mübarek gün ve geceler yaklaşırken hatırlatma',
                        value: _islamicEvents,
                        onChanged: (v) => setState(() => _islamicEvents = v),
                        scheme: scheme,
                        showDivider: false,
                      ),
                    ],
                  ),
                ).animate().fade(duration: 400.ms, delay: 180.ms).slideY(begin: 0.06, end: 0),

                const SizedBox(height: 20),

                // ── Kaydet butonu ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text(
                      'Tercihleri Kaydet',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ).animate().fade(duration: 400.ms, delay: 220.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({
    required this.onRequest,
    required this.isDark,
    required this.scheme,
  });

  final VoidCallback onRequest;
  final bool isDark;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0EA5E9).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF0EA5E9), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bildirim İzni',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Bildirimlerin çalışması için izin gereklidir.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRequest,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF0EA5E9),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: const Text(
              'İzin Ver',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PrayerNotifRow extends StatelessWidget {
  const _PrayerNotifRow({
    required this.icon,
    required this.label,
    required this.onTime,
    required this.before,
    required this.onTimeChanged,
    required this.beforeChanged,
    required this.scheme,
  });

  final IconData icon;
  final String label;
  final bool onTime;
  final bool before;
  final ValueChanged<bool> onTimeChanged;
  final ValueChanged<bool> beforeChanged;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF064E3B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          _MiniToggle(
            label: 'Vaktinde',
            value: onTime,
            onChanged: onTimeChanged,
            color: const Color(0xFF064E3B),
          ),
          const SizedBox(width: 8),
          _MiniToggle(
            label: '15 dk önce',
            value: before,
            onChanged: beforeChanged,
            color: const Color(0xFF0EA5E9),
          ),
        ],
      ),
    );
  }
}

class _MiniToggle extends StatelessWidget {
  const _MiniToggle({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? color : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: value ? color : Colors.grey,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _AppNotifRow extends StatelessWidget {
  const _AppNotifRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.scheme,
    required this.showDivider,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme scheme;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: iconColor,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
