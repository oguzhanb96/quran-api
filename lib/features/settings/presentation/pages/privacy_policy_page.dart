import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/settings/app_preferences.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  bool _analyticsConsent = false;
  bool _explicitConsent = false;

  @override
  void initState() {
    super.initState();
    final box = AppPreferences.box;
    _analyticsConsent = box.get(AppPreferences.analyticsConsentKey, defaultValue: false) as bool;
    _explicitConsent = box.get(AppPreferences.explicitConsentKey, defaultValue: false) as bool;
  }

  Future<void> _saveConsents() async {
    final box = AppPreferences.box;
    await box.put(AppPreferences.analyticsConsentKey, _analyticsConsent);
    await box.put(AppPreferences.explicitConsentKey, _explicitConsent);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Gizlilik tercihleri kaydedildi.',
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

  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Tüm Verileri Sil',
          style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bu işlem geri alınamaz. Tüm yerel verileriniz (okuma geçmişi, zikir istatistikleri, tercihler) silinecektir.',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AppPreferences.box.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Tüm veriler silindi.',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _exportData() async {
    final box = AppPreferences.box;
    final data = {
      'locale': box.get(AppPreferences.localeCodeKey),
      'city': box.get(AppPreferences.selectedCityKey),
      'country': box.get(AppPreferences.selectedCountryKey),
      'dhikr_streak': box.get(AppPreferences.dhikrStreakKey, defaultValue: 0),
      'dhikr_monthly': box.get(AppPreferences.dhikrMonthlyTotalKey, defaultValue: 0),
      'reading_goal': box.get(AppPreferences.readingGoalMinutesKey, defaultValue: 0.0),
      'analytics_consent': box.get(AppPreferences.analyticsConsentKey, defaultValue: false),
    };
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Verileriniz',
          style: GoogleFonts.notoSerif(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: data.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(
                      '${e.key}: ',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${e.value ?? "—"}',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

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
              'Gizlilik ve KVKK',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: _saveConsents,
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
                // ── Özet banner ───────────────────────────────────────────────
                _PrivacyHeroBanner(isDark: isDark)
                    .animate()
                    .fade(duration: 500.ms)
                    .slideY(begin: 0.08, end: 0),

                const SizedBox(height: 20),

                // ── Onay yönetimi ─────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.tune_rounded,
                  title: 'Onay Yönetimi (KVKK / GDPR)',
                  color: const Color(0xFF0EA5E9),
                ).animate().fade(duration: 400.ms, delay: 80.ms),

                const SizedBox(height: 12),

                _ConsentCard(
                  isDark: isDark,
                  analyticsConsent: _analyticsConsent,
                  explicitConsent: _explicitConsent,
                  onAnalyticsChanged: (v) => setState(() => _analyticsConsent = v),
                  onExplicitChanged: (v) => setState(() => _explicitConsent = v),
                  scheme: scheme,
                ).animate().fade(duration: 400.ms, delay: 120.ms).slideY(begin: 0.06, end: 0),

                const SizedBox(height: 20),

                // ── Veri hakları ──────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.manage_accounts_rounded,
                  title: 'Veri Haklarınız',
                  color: const Color(0xFF8B5CF6),
                ).animate().fade(duration: 400.ms, delay: 160.ms),

                const SizedBox(height: 12),

                _DataRightsCard(
                  isDark: isDark,
                  scheme: scheme,
                  onExport: _exportData,
                  onDelete: _deleteAllData,
                ).animate().fade(duration: 400.ms, delay: 200.ms).slideY(begin: 0.06, end: 0),

                const SizedBox(height: 20),

                // ── Gizlilik politikası ───────────────────────────────────────
                _SectionHeader(
                  icon: Icons.policy_rounded,
                  title: 'Gizlilik Politikası',
                  color: const Color(0xFF064E3B),
                ).animate().fade(duration: 400.ms, delay: 240.ms),

                const SizedBox(height: 12),

                _PrivacyPolicyText(isDark: isDark)
                    .animate()
                    .fade(duration: 400.ms, delay: 280.ms)
                    .slideY(begin: 0.06, end: 0),

                const SizedBox(height: 20),

                // ── Kaydet butonu ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveConsents,
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
                ).animate().fade(duration: 400.ms, delay: 320.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PrivacyHeroBanner extends StatelessWidget {
  const _PrivacyHeroBanner({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF1D4ED8), Color(0xFF2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'KVKK / GDPR UYUMLU',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Verileriniz Güvende',
                      style: GoogleFonts.notoSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Kişisel verileriniz yalnızca uygulamanın çalışması için kullanılır. Hiçbir veri üçüncü taraflarla paylaşılmaz.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ConsentCard extends StatelessWidget {
  const _ConsentCard({
    required this.isDark,
    required this.analyticsConsent,
    required this.explicitConsent,
    required this.onAnalyticsChanged,
    required this.onExplicitChanged,
    required this.scheme,
  });

  final bool isDark;
  final bool analyticsConsent;
  final bool explicitConsent;
  final ValueChanged<bool> onAnalyticsChanged;
  final ValueChanged<bool> onExplicitChanged;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      isDark: isDark,
      child: Column(
        children: [
          _ConsentRow(
            icon: Icons.analytics_rounded,
            iconColor: const Color(0xFF0EA5E9),
            title: 'Analitik Veri Toplama',
            subtitle: 'Uygulama kullanım istatistikleri (anonim). Hata raporları ve performans verileri.',
            value: analyticsConsent,
            onChanged: onAnalyticsChanged,
            scheme: scheme,
            showDivider: true,
          ),
          _ConsentRow(
            icon: Icons.verified_user_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'Açık Rıza Beyanı',
            subtitle: 'KVKK kapsamında kişisel veri işlenmesine açık rıza veriyorum.',
            value: explicitConsent,
            onChanged: onExplicitChanged,
            scheme: scheme,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _ConsentRow extends StatelessWidget {
  const _ConsentRow({
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 2),
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
              const SizedBox(width: 8),
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

class _DataRightsCard extends StatelessWidget {
  const _DataRightsCard({
    required this.isDark,
    required this.scheme,
    required this.onExport,
    required this.onDelete,
  });

  final bool isDark;
  final ColorScheme scheme;
  final VoidCallback onExport;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      isDark: isDark,
      child: Column(
        children: [
          _RightRow(
            icon: Icons.download_rounded,
            iconColor: const Color(0xFF8B5CF6),
            title: 'Verilerimi Görüntüle / Dışa Aktar',
            subtitle: 'Uygulama tarafından saklanan tüm verilerinizi görüntüleyin.',
            buttonLabel: 'Görüntüle',
            buttonColor: const Color(0xFF8B5CF6),
            onTap: onExport,
            isDark: isDark,
            scheme: scheme,
            showDivider: true,
          ),
          _RightRow(
            icon: Icons.delete_forever_rounded,
            iconColor: Colors.red,
            title: 'Tüm Verilerimi Sil',
            subtitle: 'Yerel verilerin tamamını kalıcı olarak silin. Bu işlem geri alınamaz.',
            buttonLabel: 'Sil',
            buttonColor: Colors.red,
            onTap: onDelete,
            isDark: isDark,
            scheme: scheme,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _RightRow extends StatelessWidget {
  const _RightRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.buttonColor,
    required this.onTap,
    required this.isDark,
    required this.scheme,
    required this.showDivider,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final Color buttonColor;
  final VoidCallback onTap;
  final bool isDark;
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
                        fontSize: 13,
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
              const SizedBox(width: 8),
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: buttonColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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

class _PrivacyPolicyText extends StatelessWidget {
  const _PrivacyPolicyText({required this.isDark});

  final bool isDark;

  static const _sections = [
    _PolicySection(
      title: '1. Toplanan Veriler',
      content:
          'Uygulama yalnızca cihazınızda yerel olarak şu verileri saklar: konum tercihi (namaz vakitleri için), dil tercihi, okuma geçmişi, zikir istatistikleri ve bildirim tercihleri. Hiçbir kişisel kimlik bilgisi toplanmaz.',
    ),
    _PolicySection(
      title: '2. Veri Kullanımı',
      content:
          'Toplanan veriler yalnızca uygulamanın temel işlevlerini (namaz vakitleri, kişiselleştirilmiş deneyim) sağlamak amacıyla kullanılır. Verileriniz hiçbir üçüncü tarafla paylaşılmaz veya satılmaz.',
    ),
    _PolicySection(
      title: '3. Veri Güvenliği',
      content:
          'Tüm veriler cihazınızda şifreli olarak saklanır. Sunucu bağlantıları HTTPS/TLS ile şifrelenir. Hassas veriler için platform güvenli depolama (Keychain/Keystore) kullanılır.',
    ),
    _PolicySection(
      title: '4. KVKK Hakları',
      content:
          'Türkiye\'de yerleşik kullanıcılar olarak 6698 sayılı KVKK kapsamında: verilerinize erişme, düzeltme, silme ve işlenmesine itiraz etme haklarına sahipsiniz. Bu hakları kullanmak için uygulama içi "Verilerimi Sil" özelliğini kullanabilirsiniz.',
    ),
    _PolicySection(
      title: '5. GDPR Hakları',
      content:
          'AB/AEA\'da yerleşik kullanıcılar GDPR kapsamında: erişim, taşınabilirlik, silme ("unutulma hakkı") ve işleme itiraz haklarına sahiptir. Veri dışa aktarma özelliğini kullanabilirsiniz.',
    ),
    _PolicySection(
      title: '6. İletişim',
      content:
          'Gizlilik ile ilgili sorularınız için: privacy@hidaya-app.com adresine e-posta gönderebilirsiniz. Talepleriniz 30 gün içinde yanıtlanır.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Son güncelleme: Nisan 2026',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._sections.map((section) => _PolicySectionWidget(section: section, isDark: isDark)),
        ],
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection({required this.title, required this.content});

  final String title;
  final String content;
}

class _PolicySectionWidget extends StatelessWidget {
  const _PolicySectionWidget({required this.section, required this.isDark});

  final _PolicySection section;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            section.content,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF374151),
              height: 1.6,
            ),
          ),
        ],
      ),
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
