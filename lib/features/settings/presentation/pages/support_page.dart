import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/settings/app_preferences.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _isPremium = AppPreferences.isPremiumEnabled();
  }

  Future<void> _activatePremium() async {
    HapticFeedback.mediumImpact();
    await AppPreferences.setPremiumEnabled(true);
    setState(() => _isPremium = true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text(
              'Premium aktif edildi! Tüm özellikler açıldı.',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD97706),
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
              'Gelişime Katkı',
              style: GoogleFonts.notoSerif(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            centerTitle: true,
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Hero ─────────────────────────────────────────────────────
                _HeroBanner(isDark: isDark)
                    .animate()
                    .fade(duration: 500.ms)
                    .slideY(begin: 0.08, end: 0),

                const SizedBox(height: 20),

                // ── Premium başlığı ───────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Premium Üyelik',
                  color: const Color(0xFFD97706),
                ).animate().fade(duration: 400.ms, delay: 80.ms),

                const SizedBox(height: 12),

                // ── Premium kart ──────────────────────────────────────────────
                _PremiumCard(
                  isDark: isDark,
                  isPremium: _isPremium,
                  onActivate: _activatePremium,
                ).animate().fade(duration: 400.ms, delay: 120.ms).slideY(begin: 0.06, end: 0),

                const SizedBox(height: 20),

                // ── Premium özellikler ────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.star_rounded,
                  title: 'Premium Özellikler',
                  color: const Color(0xFFF59E0B),
                ).animate().fade(duration: 400.ms, delay: 160.ms),

                const SizedBox(height: 12),

                _FeaturesCard(isDark: isDark)
                    .animate()
                    .fade(duration: 400.ms, delay: 200.ms)
                    .slideY(begin: 0.06, end: 0),

                const SizedBox(height: 20),

                // ── Bağış başlığı ─────────────────────────────────────────────
                _SectionHeader(
                  icon: Icons.favorite_rounded,
                  title: 'Bağış Yap',
                  color: const Color(0xFFEC4899),
                ).animate().fade(duration: 400.ms, delay: 240.ms),

                const SizedBox(height: 12),

                _DonationCard(isDark: isDark, scheme: scheme)
                    .animate()
                    .fade(duration: 400.ms, delay: 280.ms)
                    .slideY(begin: 0.06, end: 0),

                const SizedBox(height: 20),

                // ── Teşekkür notu ─────────────────────────────────────────────
                _ThankYouNote(isDark: isDark)
                    .animate()
                    .fade(duration: 400.ms, delay: 320.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFD97706)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -20,
            child: Icon(
              Icons.volunteer_activism_rounded,
              size: 100,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
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
                    'HİDAYA UYGULAMASI',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Uygulamayı Destekle',
                  style: GoogleFonts.notoSerif(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bu uygulama tamamen ücretsiz ve reklamsız olarak sunulmaktadır. Geliştirmeye devam etmemiz için desteğine ihtiyacımız var.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PremiumCard extends StatelessWidget {
  const _PremiumCard({
    required this.isDark,
    required this.isPremium,
    required this.onActivate,
  });

  final bool isDark;
  final bool isPremium;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium
              ? const Color(0xFFD97706).withValues(alpha: 0.4)
              : const Color(0xFFD97706).withValues(alpha: 0.15),
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
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hidaya Premium',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isPremium ? 'Aktif — Tüm özellikler açık' : 'Tüm özelliklerin kilidini aç',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: isPremium ? const Color(0xFF10B981) : const Color(0xFFD97706),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Color(0xFF10B981), size: 18),
                ),
            ],
          ),
          if (!isPremium) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onActivate,
                icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                label: const Text(
                  'Premium\'u Etkinleştir',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard({required this.isDark});

  final bool isDark;

  static const _features = [
    (Icons.download_rounded, 'Offline Kur\'an Ses İndirme', 'İnternet olmadan dinle', Color(0xFF0EA5E9)),
    (Icons.block_rounded, 'Reklamsız Kullanım', 'Kesintisiz ibadet deneyimi', Color(0xFF10B981)),
    (Icons.record_voice_over_rounded, 'Tüm Kari Sesleri', 'Dünyaca ünlü hafız sesleri', Color(0xFF8B5CF6)),
    (Icons.bar_chart_rounded, 'Gelişmiş İstatistikler', 'Detaylı ibadet takibi', Color(0xFFF59E0B)),
    (Icons.palette_rounded, 'Özel Temalar', 'Kişiselleştirilmiş görünüm', Color(0xFFEC4899)),
    (Icons.cloud_sync_rounded, 'Bulut Senkronizasyonu', 'Tüm cihazlarda erişim', Color(0xFF06B6D4)),
  ];

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
      child: Column(
        children: _features.asMap().entries.map((entry) {
          final i = entry.key;
          final (icon, title, subtitle, color) = entry.value;
          final isLast = i == _features.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
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
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.workspace_premium_rounded, color: const Color(0xFFD97706), size: 18),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DonationCard extends StatelessWidget {
  const _DonationCard({required this.isDark, required this.scheme});

  final bool isDark;
  final ColorScheme scheme;

  static const _amounts = ['10 ₺', '25 ₺', '50 ₺', '100 ₺', '250 ₺'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.15),
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
          Text(
            'Bir defaya mahsus bağış yaparak uygulamanın geliştirilmesine katkıda bulunabilirsiniz.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: isDark ? Colors.white60 : const Color(0xFF374151),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _amounts.map((amount) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$amount bağış için teşekkürler! 🤲',
                        style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600),
                      ),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: const Color(0xFFEC4899),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      margin: const EdgeInsets.all(16),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    amount,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEC4899),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Bağış sayfasına yönlendiriliyorsunuz...',
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
              icon: const Icon(Icons.favorite_rounded, size: 18),
              label: const Text(
                'Bağış Yap',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEC4899),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ThankYouNote extends StatelessWidget {
  const _ThankYouNote({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF064E3B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF064E3B).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mosque_rounded, color: Color(0xFF064E3B), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Her türlü katkınız için Allah razı olsun. Bu uygulama sadece Allah\'ın rızasını kazanmak için yapılmıştır.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white60 : const Color(0xFF374151),
                height: 1.5,
              ),
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
